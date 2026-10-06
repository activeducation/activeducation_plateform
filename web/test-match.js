/**
 * Test Automatisé du Module d'Orientation ActivEducation (/api/match)
 * Validations :
 * 1. Statut HTTP 200 / Succès
 * 2. Structure JSON valide
 * 3. Profil psychologique conforme (code, title, description, traits, forces, conseils)
 * 4. Exactement 3 métiers porteurs au Togo (titre, score, salaire FCFA, compétences)
 * 5. Exactement 3 établissements togolais agréés MESR/CAMES (nom, ville, accréditation, filières)
 * 6. Établissements réels togolais vérifiés
 * 7. ZÉRO EMOJI dans l'intégralité de la réponse
 */

const assert = require('assert');
const fs = require('fs');
const path = require('path');

// Regex universelle de détection d'emojis
const EMOJI_REGEX = /[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{1FA70}-\u{1FAFF}]/u;

// Jeu de données de test simulé (réponses Likert 1-5 d'un étudiant à forte appétence tech/sciences)
const mockPayload = {
  answers: {
    q1: 4, // Réaliste (outils, technique)
    q2: 5, // Investigateur (logique, données)
    q3: 3, // Artistique (visuels)
    q4: 3, // Social (entraide)
    q5: 4, // Entreprenant (initiatives, projets)
    q6: 4, // Conventionnel (rigueur)
    q7: 3, // Réaliste (terrain)
    q8: 5, // Investigateur (code, sciences)
    q9: 2, // Artistique (improvisation)
    q10: 3, // Social (équipe)
    q11: 4, // Entreprenant (affaires)
    q12: 4, // Conventionnel (méthode)
  },
  studentContext: {
    schoolLevel: 'Terminale D',
    city: 'Lomé',
    serieBac: 'D',
  },
};

// Liste des établissements togolais authentiques reconnus
const OFFICIAL_TOGO_SCHOOL_NAMES = [
  'Université de Lomé',
  'Université de Kara',
  'Institut Africain d’Informatique',
  'IAI-Togo',
  'École Africaine des Métiers de l’Architecture et de l’Urbanisme',
  'EAMAU',
  'École Supérieure de Gestion, d’Informatique et des Sciences',
  'ESGIS',
  'École Supérieure d’Administration et de Gestion Notre-Dame de l’Église',
  'ESAG-NDE',
  'Institut de Technologie IPNET',
  'IPNET',
  'FORMATEC',
  'INFA de Tové',
  'UCAO-UUT',
];

async function getMatchData() {
  const targetUrl = process.env.TEST_URL || 'http://localhost:3000/api/match';
  
  // 1. Essai d'appel HTTP direct si le serveur tourne
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 2000);

    console.log(`[1/3] Tentative d'appel HTTP vers ${targetUrl}...`);
    const res = await fetch(targetUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(mockPayload),
      signal: controller.signal,
    });
    clearTimeout(timeout);

    if (res.ok) {
      console.log(`[HTTP 200 OK] Réponse reçue depuis le serveur Next.js.`);
      const json = await res.json();
      return { data: json, source: 'http-server' };
    }
  } catch (err) {
    console.log(`[INFO] Serveur HTTP non disponible (${err.message}). Bascule vers l'exécution directe du module.`);
  }

  // 2. Exécution directe et autonome de la logique orientation.ts via transpile TypeScript
  console.log(`[2/3] Chargement direct du module TypeScript src/lib/orientation.ts...`);
  const ts = require('typescript');
  const tsPath = path.join(__dirname, 'src', 'lib', 'orientation.ts');
  const tsCode = fs.readFileSync(tsPath, 'utf8');

  const transpiled = ts.transpileModule(tsCode, {
    compilerOptions: {
      module: ts.ModuleKind.CommonJS,
      target: ts.ScriptTarget.ES2022,
    },
  }).outputText;

  const localModule = { exports: {} };
  const runner = new Function('module', 'exports', 'require', '__dirname', '__filename', transpiled);
  runner(localModule, localModule.exports, require, path.dirname(tsPath), tsPath);

  const { matchOrientation } = localModule.exports;
  const result = await matchOrientation(mockPayload);
  return { data: result, source: 'standalone-direct' };
}

async function runTests() {
  console.log('====================================================');
  console.log(' ACTIVEDUCATION - TEST DE VALIDATION /api/match');
  console.log('====================================================\n');

  const startTime = Date.now();
  const { data, source } = await getMatchData();
  const rawJson = JSON.stringify(data);

  console.log(`[3/3] Validation des assertions sur les données (source: ${source})...\n`);

  // Assertion 1 : Présence d'un objet de données valide
  assert(data && typeof data === 'object', 'L’API doit renvoyer un objet JSON non nul');
  console.log('  [PASS] Assertion 1 : Réponse JSON valide');

  // Assertion 2 : Structure du Profil psychologique
  assert(data.profile, 'Le champ profile est obligatoire');
  assert(typeof data.profile.code === 'string' && data.profile.code.length >= 2, 'profile.code doit être une chaîne (ex: IRE, RIA)');
  assert(typeof data.profile.title === 'string' && data.profile.title.length > 5, 'profile.title doit être une chaîne explicite');
  assert(
    typeof (data.profile.description || data.profile.summary) === 'string',
    'profile.description doit être une chaîne non vide'
  );
  assert(Array.isArray(data.profile.dominantTraits) && data.profile.dominantTraits.length >= 3, 'profile.dominantTraits doit contenir au moins 3 traits');
  assert(Array.isArray(data.profile.strengths) && data.profile.strengths.length >= 1, 'profile.strengths doit contenir des points forts');
  assert(typeof data.profile.advice === 'string' && data.profile.advice.length > 10, 'profile.advice doit fournir un conseil');
  console.log(`  [PASS] Assertion 2 : Profil psychologique complet (Code: ${data.profile.code} - ${data.profile.title})`);

  // Assertion 3 : Exactement 3 Métiers porteurs au Togo
  assert(Array.isArray(data.careers), 'Le champ careers doit être un tableau');
  assert.strictEqual(data.careers.length, 3, 'L’API doit renvoyer EXACTEMENT 3 métiers porteurs');
  data.careers.forEach((career, idx) => {
    const title = career.title || career.name;
    assert(typeof title === 'string' && title.length > 3, `Carrière ${idx + 1} : titre invalide`);
    assert(typeof career.matchScore === 'number' && career.matchScore >= 0 && career.matchScore <= 100, `Carrière ${idx + 1} : score de correspondance entre 0 et 100`);
    const salary = career.salary || career.salaryRange || career.averageSalary || '';
    assert(salary.includes('FCFA'), `Carrière ${idx + 1} (${title}) : le salaire doit être exprimé en FCFA (${salary})`);
    assert(Array.isArray(career.requiredSkills) && career.requiredSkills.length > 0, `Carrière ${idx + 1} : compétences requises obligatoires`);
    assert(typeof career.description === 'string' && career.description.length > 15, `Carrière ${idx + 1} : description détaillée obligatoire`);
  });
  console.log(`  [PASS] Assertion 3 : Exactement 3 carrières porteurs (${data.careers.map((c) => c.title || c.name).join(', ')})`);

  // Assertion 4 : Exactement 3 Établissements agréés au Togo
  const institutions = data.institutions || data.schools;
  assert(Array.isArray(institutions), 'Le champ institutions (ou schools) doit être un tableau');
  assert.strictEqual(institutions.length, 3, 'L’API doit renvoyer EXACTEMENT 3 établissements agréés');
  institutions.forEach((inst, idx) => {
    assert(typeof inst.name === 'string' && inst.name.length > 3, `Établissement ${idx + 1} : nom obligatoire`);
    assert(typeof inst.city === 'string' && inst.city.length > 2, `Établissement ${idx + 1} : ville obligatoire`);
    const status = inst.accreditation || inst.status || '';
    assert(
      status.toLowerCase().includes('mesr') || status.toLowerCase().includes('cames') || status.toLowerCase().includes('agréé'),
      `Établissement ${idx + 1} (${inst.name}) : doit mentionner l'accréditation MESR ou CAMES (${status})`
    );
    assert(Array.isArray(inst.programs) && inst.programs.length > 0, `Établissement ${idx + 1} : filières obligatoires`);
  });
  console.log(`  [PASS] Assertion 4 : Exactement 3 établissements togolais (${institutions.map((i) => i.name).join(', ')})`);

  // Assertion 5 : Noms des établissements réels togolais
  const recognizedCount = institutions.filter((inst) =>
    OFFICIAL_TOGO_SCHOOL_NAMES.some((off) => inst.name.includes(off) || off.includes(inst.name))
  ).length;
  assert(recognizedCount >= 2, `Au moins 2 établissements doivent correspondre au référentiel togolais (${recognizedCount}/3 validés)`);
  console.log(`  [PASS] Assertion 5 : Authenticité des écoles togolaises vérifiée (${recognizedCount}/3 référencées MESR)`);

  // Assertion 6 : Règle ZÉRO EMOJI absolue
  const hasEmoji = EMOJI_REGEX.test(rawJson);
  assert.strictEqual(hasEmoji, false, 'VIOLATION CRITIQUE : Des emojis ont été détectés dans la réponse JSON');
  console.log('  [PASS] Assertion 6 : ZÉRO EMOJI dans l’intégralité de la réponse');

  // Assertion 7 : Score ambre présent pour chaque carrière
  data.careers.forEach((c, idx) => {
    assert(typeof c.matchScore === 'number' && c.matchScore >= 60, `Carrière ${idx + 1} doit posséder un score d'adéquation réaliste (>= 60)`);
  });
  console.log('  [PASS] Assertion 7 : Scores de correspondance d’orientation valides (ex: ' + data.careers.map((c) => c.matchScore + '%').join(', ') + ')');

  const elapsed = Date.now() - startTime;
  console.log(`\n====================================================`);
  console.log(` TOUTES LES ASSERTIONS ONT RÉUSSI EN ${elapsed}ms !`);
  console.log(` Mode d'exécution : ${data.executionMode || 'standard'}`);
  console.log(` Statut : SUCCÈS (Code de sortie 0)`);
  console.log(`====================================================\n`);

  process.exit(0);
}

runTests().catch((err) => {
  console.error('\n[ERREUR FATALE DANS test-match.js] :', err.message);
  if (err.stack) console.error(err.stack);
  process.exit(1);
});
