/**
 * Test Automatisé Multi-Profils du Module d'Orientation AÏDA (/api/orientation/generate)
 * Vérifications strictes :
 * 1. Statut HTTP 200 ou exécution directe du repli déterministe
 * 2. Structure JSON exacte (psychologicalProfile, recommendedCareers, recommendedSchools)
 * 3. Exactement 3 métiers avec matchPercentage (60-100), salaire en FCFA, demandInTogo
 * 4. Entre 1 et 3 établissements togolais accrédités MESR / CAMES
 * 5. ZÉRO EMOJI dans l'intégralité de la réponse
 * 6. Correspondance sémantique par profil (Santé -> Médecin/Pharmacien, BTP -> BTP/Architecte, Tech -> Dev/Data)
 */

const assert = require('assert');
const fs = require('fs');
const path = require('path');

// Regex universelle de détection d'emojis
const EMOJI_REGEX = /[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{1FA70}-\u{1FAFF}]/u;

// Noms d'établissements togolais authentiques reconnus
const OFFICIAL_TOGO_SCHOOLS = [
  'Université de Lomé',
  'Université de Kara',
  'Institut Africain d’Informatique',
  'IAI-Togo',
  'École Africaine des Métiers de l’Architecture et de l’Urbanisme',
  'EAMAU',
  'École Supérieure de Gestion, d’Informatique et des Sciences',
  'ESGIS',
  'FORMATEC',
  'INFA de Tové',
  'UCAO-UUT',
  'ESAG-NDE',
  'IPNET',
];

// Profils de test multi-domaines
const TEST_PROFILES = [
  {
    id: 'tech',
    name: 'Profil 1 — Numérique & Nouvelles Technologies',
    answers: {
      interests: ['Sciences & Nouvelles Technologies'],
      strongSubjects: ['Mathématiques & Physique-Chimie', 'Informatique & Technologies'],
      otherSubject: 'Programmation Web et Python',
      budget: 'Moyen',
      mobility: 'Grand Lomé & Région Maritime',
      currentCity: 'Lomé',
    },
    expectedKeywords: ['Développeur', 'Data', 'Cybersécurité', 'Web', 'Réseaux'],
  },
  {
    id: 'sante',
    name: 'Profil 2 — Santé, Médecine & Sciences Médicales',
    answers: {
      interests: ['Santé, Biologie & Sciences Médicales'],
      strongSubjects: ['Sciences de la Vie et de la Terre (SVT)'],
      otherSubject: 'Biologie Médicale et Chimie',
      budget: 'Faible',
      mobility: 'Grand Lomé & Région Maritime',
      currentCity: 'Lomé',
    },
    expectedKeywords: ['Médecin', 'Pharmacien', 'Santé', 'Biologiste'],
  },
  {
    id: 'btp',
    name: 'Profil 3 — Bâtiment, Travaux Publics & Génie Civil',
    answers: {
      interests: ['Bâtiment, Industrie & Ingénierie'],
      strongSubjects: ['Mathématiques & Physique-Chimie'],
      otherSubject: 'Dessin Technique et RDM',
      budget: 'Élevé',
      mobility: 'Grand Lomé & Région Maritime',
      currentCity: 'Lomé',
    },
    expectedKeywords: ['Ingénieur', 'BTP', 'Génie Civil', 'Architecte', 'Urbaniste'],
  },
  {
    id: 'gestion',
    name: 'Profil 4 — Économie, Gestion & Finance',
    answers: {
      interests: ['Économie, Gestion & Entrepreneuriat'],
      strongSubjects: ['Sciences Économiques & Sociales (SES)'],
      otherSubject: 'Comptabilité et Finance',
      budget: 'Moyen',
      mobility: 'Région de la Kara & Nord Togo',
      currentCity: 'Kara',
    },
    expectedKeywords: ['Comptable', 'Banquier', 'Auditeur', 'Financier', 'Entrepreneur'],
  },
];

let cachedGenerator = null;

function getDeterministicGenerator() {
  if (cachedGenerator) return cachedGenerator;
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

  cachedGenerator = localModule.exports.generateDeterministicOrientationM3;
  return cachedGenerator;
}

async function getOrientationData(payload) {
  const targetUrl = process.env.TEST_URL || 'http://localhost:3000/api/orientation/generate';

  // 1. Essai HTTP si un serveur dev Next.js est en écoute
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 2000);

    const res = await fetch(targetUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });
    clearTimeout(timeout);

    if (res.ok) {
      const json = await res.json();
      return { data: json, source: 'http-server' };
    }
  } catch (err) {
    // Repli direct
  }

  // 2. Exécution directe via transpile
  const generator = getDeterministicGenerator();
  const result = generator(payload.answers);
  return { data: result, source: 'direct-module-fallback' };
}

async function runTests() {
  console.log('====================================================');
  console.log(' ACTIVEDUCATION - SUITE DE TESTS MULTI-PROFILS M3');
  console.log('====================================================\n');

  const totalStartTime = Date.now();

  for (let i = 0; i < TEST_PROFILES.length; i++) {
    const profile = TEST_PROFILES[i];
    console.log(`--- [${i + 1}/${TEST_PROFILES.length}] Exécution : ${profile.name} ---`);

    const payload = { answers: profile.answers };
    const { data, source } = await getOrientationData(payload);
    const rawJson = JSON.stringify(data);

    // Assertion 1 : Objet JSON valide
    assert(data && typeof data === 'object', `[${profile.id}] L’API doit renvoyer un objet JSON valide`);

    // Assertion 2 : Profil psychologique complet
    assert(data.psychologicalProfile, `[${profile.id}] psychologicalProfile est obligatoire`);
    assert(Array.isArray(data.psychologicalProfile.dominantTraits) && data.psychologicalProfile.dominantTraits.length >= 2, `[${profile.id}] dominantTraits invalide`);
    assert(Array.isArray(data.psychologicalProfile.strengths) && data.psychologicalProfile.strengths.length >= 1, `[${profile.id}] strengths invalide`);
    assert(Array.isArray(data.psychologicalProfile.weaknesses) && data.psychologicalProfile.weaknesses.length >= 1, `[${profile.id}] weaknesses invalide`);
    assert(typeof data.psychologicalProfile.summary === 'string' && data.psychologicalProfile.summary.length > 20, `[${profile.id}] summary trop court`);

    // Assertion 3 : Exactement 3 Métiers recommandés
    assert(Array.isArray(data.recommendedCareers), `[${profile.id}] recommendedCareers doit être un tableau`);
    assert.strictEqual(data.recommendedCareers.length, 3, `[${profile.id}] Exactement 3 métiers recommandés requis`);
    data.recommendedCareers.forEach((c, idx) => {
      assert(typeof c.title === 'string' && c.title.length > 3, `[${profile.id}] Métier ${idx + 1} : titre invalide`);
      assert(typeof c.matchPercentage === 'number' && c.matchPercentage >= 60 && c.matchPercentage <= 100, `[${profile.id}] Match % invalide`);
      assert(typeof c.salaryRangeCFA === 'string' && c.salaryRangeCFA.includes('FCFA'), `[${profile.id}] Salaire en FCFA requis`);
      assert(['Faible', 'Moyenne', 'Forte'].includes(c.demandInTogo), `[${profile.id}] Demande Togo invalide`);
      assert(typeof c.description === 'string' && c.description.length > 15, `[${profile.id}] Description requise`);
    });

    // Assertion 4 : Établissements togolais (1 à 3)
    assert(Array.isArray(data.recommendedSchools), `[${profile.id}] recommendedSchools doit être un tableau`);
    assert(data.recommendedSchools.length >= 1 && data.recommendedSchools.length <= 3, `[${profile.id}] 1 à 3 écoles requises`);
    data.recommendedSchools.forEach((s, idx) => {
      assert(typeof s.name === 'string' && s.name.length > 3, `[${profile.id}] Nom école invalide`);
      assert(typeof s.program === 'string' && s.program.length > 3, `[${profile.id}] Filière invalide`);
      assert(typeof s.estimatedAnnualCostCFA === 'string' && s.estimatedAnnualCostCFA.length > 2, `[${profile.id}] Coût invalide`);
    });

    // Assertion 5 : Authenticité des établissements togolais
    const recognizedCount = data.recommendedSchools.filter((school) =>
      OFFICIAL_TOGO_SCHOOLS.some((off) => school.name.includes(off) || off.includes(school.name))
    ).length;
    assert(recognizedCount >= 1, `[${profile.id}] Au moins 1 école doit appartenir au référentiel togolais`);

    // Assertion 6 : RÈGLE ABSOLUE ZÉRO EMOJI
    const hasEmoji = EMOJI_REGEX.test(rawJson);
    assert.strictEqual(hasEmoji, false, `[${profile.id}] VIOLATION CRITIQUE : Émoji détecté`);

    // Assertion 7 : Pertinence sémantique stricte du profil (Top 2 / Top 3 métiers)
    const careerTitles = data.recommendedCareers.map((c) => c.title);
    if (profile.id === 'tech') {
      const top2 = careerTitles.slice(0, 2);
      const hasDev = top2.some((t) => /développeur/i.test(t));
      const hasData = top2.some((t) => /data analyst/i.test(t));
      assert(
        hasDev && hasData,
        `[${profile.id}] Les 2 premiers métiers doivent inclure Développeur et Data Analyst (obtenu: ${top2.join(', ')})`
      );
    } else if (profile.id === 'sante') {
      const top2 = careerTitles.slice(0, 2);
      const hasMed = top2.some((t) => /médecin/i.test(t));
      const hasPharm = top2.some((t) => /pharmacien/i.test(t));
      assert(
        hasMed && hasPharm,
        `[${profile.id}] Les 2 premiers métiers doivent inclure Médecin et Pharmacien (obtenu: ${top2.join(', ')})`
      );
    } else if (profile.id === 'btp') {
      const top2 = careerTitles.slice(0, 2);
      const hasBtp = top2.some((t) => /génie civil|btp/i.test(t));
      const hasArch = top2.some((t) => /architecte/i.test(t));
      assert(
        hasBtp && hasArch,
        `[${profile.id}] Les 2 premiers métiers doivent inclure Génie Civil/BTP et Architecte (obtenu: ${top2.join(', ')})`
      );
    } else if (profile.id === 'gestion') {
      const top3 = careerTitles.slice(0, 3);
      const hasCompta = top3.some((t) => /comptable/i.test(t));
      const hasBanque = top3.some((t) => /banquier|analyste/i.test(t));
      const hasEntreprise = top3.some((t) => /entrepreneur/i.test(t));
      assert(
        hasCompta && hasBanque && hasEntreprise,
        `[${profile.id}] Le Top 3 des métiers doit contenir Comptable, Banquier/Analyste et Entrepreneur (obtenu: ${top3.join(', ')})`
      );
    }

    console.log(`  [PASS] 7/7 Assertions validées (Top Métiers: ${careerTitles.join(' | ')}) [Source: ${source}]\n`);
  }

  const elapsed = Date.now() - totalStartTime;
  console.log('====================================================');
  console.log(` TOUS LES ${TEST_PROFILES.length} PROFILS ONT ÉTÉ VALIDÉS AVEC SUCCÈS EN ${elapsed}ms !`);
  console.log(' Statut : SUCCÈS (Code de sortie 0)');
  console.log('====================================================\n');
  process.exit(0);
}

runTests().catch((err) => {
  console.error('\n[ERREUR DANS test-orientation-generate.js] :', err.message);
  if (err.stack) console.error(err.stack);
  process.exit(1);
});
