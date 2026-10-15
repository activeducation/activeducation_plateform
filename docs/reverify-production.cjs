// Audit harness: executes the current handlers with in-memory dependencies only.
// No environment files, database connections, network calls, or application edits.
// Run from repository root: node docs/reverify-production.cjs
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const { createRequire } = require('node:module');
const root = path.resolve(__dirname, '..');
const webRequire = createRequire(path.join(root, 'web/package.json'));
const ts = webRequire('typescript');
const { getTableName } = webRequire('drizzle-orm');

function load(relative, dependencies = {}) {
  const filename = path.join(root, relative);
  const source = fs.readFileSync(filename, 'utf8');
  const { outputText } = ts.transpileModule(source, {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 },
  });
  const module = { exports: {} };
  const localRequire = id => {
    if (Object.hasOwn(dependencies, id)) return dependencies[id];
    if (id.startsWith('@/')) throw new Error(`Unmocked application import: ${id}`);
    return webRequire(id);
  };
  vm.runInNewContext('(function(require,module,exports){' + outputText + '\n})', {
    console, Response, Request, Date, process: { env: {} },
  }, { filename })(localRequire, module, module.exports);
  return module.exports;
}

const schema = load('web/src/db/schema.ts');
const camel = name => name.replace(/_([a-z])/g, (_, c) => c.toUpperCase());
const orm = {
  eq: (column, value) => row => row[camel(column.name)] === value,
  and: (...predicates) => row => predicates.every(p => p(row)),
  desc: () => undefined,
  asc: () => undefined,
};
const clone = value => structuredClone(value);
const next = { NextResponse: { json: (body, init) => Response.json(body, init) } };

function fixture(role = 'STUDENT', authenticated = true, rewardXp = 50) {
  const state = {
    users: [{ id: 'u1', role, xpPoints: 0, level: 1 }],
    courses: [{ id: 'c1', isPublished: true }],
    lessons: [
      { id: 'l1', courseId: 'c1', orderIndex: 0, rewardXp },
      { id: 'l2', courseId: 'c1', orderIndex: 1, rewardXp },
    ],
    course_progress: [{ userId: 'u1', courseId: 'c1', completedLessons: [], status: 'IN_PROGRESS' }],
  };
  const db = {
    select() {
      let name;
      let predicate = () => true;
      const read = () => clone((state[name] || []).filter(predicate));
      const query = {
        from(table) { name = getTableName(table); return query; },
        where(p) { predicate = p; return query; },
        limit(n) { return Promise.resolve(read().slice(0, n)); },
        orderBy() { return query; },
        then(resolve, reject) { return Promise.resolve(read()).then(resolve, reject); },
      };
      return query;
    },
    update(table) {
      return { set: values => ({ where: async predicate => {
        for (const row of state[getTableName(table)] || []) {
          if (predicate(row)) Object.assign(row, clone(values));
        }
      } }) };
    },
    async transaction(callback) { return callback(db); },
    insert() { throw new Error('Unexpected insert reached'); },
  };
  const deps = {
    '@/db': { db }, '@/db/schema': schema, 'drizzle-orm': orm, 'next/server': next,
    '@/utils/supabase/server': { createClient: async () => ({ auth: {
      getUser: async () => ({ data: { user: authenticated ? { id: 'u1' } : null }, error: null }),
    } }) },
  };
  deps['@/utils/auth'] = load('web/src/utils/auth.ts', deps);
  return { state, deps };
}
const request = lessonId => new Request('http://audit.invalid/', {
  method: 'POST', headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ courseId: 'c1', lessonId }),
});
const completion = f => load('web/src/app/api/student/courses/complete-lesson/route.ts', f.deps).POST;

async function main() {
  let guardedHandlers = 0;
  function walk(dir) {
    return fs.readdirSync(dir, { withFileTypes: true }).flatMap(entry => {
      const full = path.join(dir, entry.name);
      return entry.isDirectory() ? walk(full) : entry.name === 'route.ts' ? [full] : [];
    });
  }
  for (const file of walk(path.join(root, 'web/src/app/api/admin'))) {
    for (const [role, authenticated, expected] of [['STUDENT', false, 401], ['STUDENT', true, 403]]) {
      const f = fixture(role, authenticated);
      const handlers = load(path.relative(root, file), f.deps);
      for (const [name, handler] of Object.entries(handlers)) {
        if (!['GET', 'POST', 'PUT', 'DELETE', 'PATCH'].includes(name)) continue;
        const response = await handler(request('l1'), { params: Promise.resolve({ id: 'c1', lessonId: 'l1' }) });
        assert.equal(response.status, expected, `${file} ${name} ${role}`);
        guardedHandlers++;
      }
    }
  }
  console.log(`CONFIRMED: ${guardedHandlers} admin denial checks passed (anonymous and student).`);

  for (const area of ['careers', 'domains', 'programs', 'schools']) {
    for (const role of ['ADMIN', 'admin']) {
      const f = fixture(role);
      const route = load(`web/src/app/api/admin/explorer/${area}/route.ts`, f.deps);
      const response = await route.POST(request('l1'));
      assert.equal(response.status, 403);
    }
  }
  console.log('REPRODUCED: all four explorer POST routes reject both ADMIN and admin (8 checks).');

  assert.equal(Object.hasOwn(schema.lessons, 'isPublished'), false);
  {
    const f = fixture();
    const response = await completion(f)(request('l1'));
    const data = await response.json();
    assert.equal(response.status, 200);
    assert.equal(data.status, 'COMPLETED');
    assert.equal(f.state.course_progress[0].completedLessons.length, 1);
    console.log('REPRODUCED: first lesson of a two-lesson course marks entire course COMPLETED.');
  }
  {
    const f = fixture();
    const response = await completion(f)(request('foreign-lesson'));
    assert.equal(response.status, 400);
    assert.equal(f.state.users[0].xpPoints, 0);
    console.log('CONFIRMED: unknown/foreign lesson refused without XP write.');
  }
  {
    const f = fixture();
    const post = completion(f);
    await post(request('l1'));
    await post(request('l1'));
    assert.equal(f.state.users[0].xpPoints, 50);
    console.log('CONFIRMED: sequential replay of a completed lesson does not award XP twice.');
  }
  {
    const f = fixture();
    f.state.courses[0].isPublished = false;
    const response = await completion(f)(request('l2'));
    assert.equal(response.status, 200);
    assert.equal(f.state.users[0].xpPoints, 50);
    console.log('REPRODUCED: unpublished course and second lesson without prerequisite accepted.');
  }
  {
    const f = fixture('STUDENT', true, 0);
    const response = await completion(f)(request('l1'));
    assert.equal((await response.json()).xpAwarded, 50);
    console.log('REPRODUCED: configured reward of zero awards 50 XP.');
  }
  {
    const f = fixture();
    const post = completion(f);
    const responses = await Promise.all([post(request('l1')), post(request('l2'))]);
    assert.ok(responses.every(r => r.status === 200));
    assert.equal(f.state.users[0].xpPoints, 50);
    assert.equal(f.state.course_progress[0].completedLessons.length, 1);
    console.log('REPRODUCED in memory: concurrent distinct completions lose one lesson and 50 XP.');
  }
  {
    // Force a valid interleaving: both requests read no previous result, then
    // the second inserts after the first has credited its reward.
    const f = fixture();
    f.state.orientation_results = [];
    const db = f.deps['@/db'].db;
    let inserted = 0;
    let releaseSecond;
    const firstRewardWritten = new Promise(resolve => { releaseSecond = resolve; });
    db.insert = table => ({ values: async value => {
      assert.equal(getTableName(table), 'orientation_results');
      inserted++;
      if (inserted === 2) await firstRewardWritten;
      f.state.orientation_results.push(clone(value));
    } });
    const update = db.update.bind(db);
    db.update = table => ({ set: values => ({ where: async predicate => {
      await update(table).set(values).where(predicate);
      if (getTableName(table) === 'users') releaseSecond();
    } }) });
    f.deps.ai = { generateObject: () => { throw new Error('No provider call allowed'); } };
    f.deps['@ai-sdk/groq'] = { createGroq: () => { throw new Error('No provider call allowed'); } };
    f.deps['@/lib/orientation'] = {
      generateDeterministicOrientationM3: () => ({ audit: true }), sanitizeObject: value => value,
    };
    const post = load('web/src/app/api/orientation/generate/route.ts', f.deps).POST;
    const responses = await Promise.all([post(request('l1')), post(request('l1'))]);
    assert.ok(responses.every(r => r.status === 200));
    assert.equal(f.state.users[0].xpPoints, 400);
    console.log('REPRODUCED in memory: concurrent first orientation reports award 400 XP instead of 200.');
  }
  const patchSource = fs.readFileSync(path.join(root, 'web/patch_coursesclient.js'), 'utf8');
  const regexLiteral = patchSource.match(/const regex = (\/.*\/);/)[1];
  const regex = vm.runInNewContext(regexLiteral);
  const client = fs.readFileSync(path.join(root, 'web/src/app/student/cours/CoursesClient.tsx'), 'utf8');
  assert.equal(regex.test(client), false);
  assert.ok(client.includes("fetch('/api/user/xp'"));
  assert.equal(fs.existsSync(path.join(root, 'web/src/app/api/user/xp/route.ts')), false);
  console.log('REPRODUCED: UI patch regex matches nothing; client still calls deleted XP route.');
  console.log('Audit reproductions completed. These are isolated checks, not a production integration test.');
}
main().catch(error => { console.error(error); process.exitCode = 1; });
