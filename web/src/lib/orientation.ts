/**
 * Module d'Orientation Scolaire & Professionnelle ActivEducation
 * Modèle RIASEC (Holland), Référentiel Togo (MESR/CAMES) & Matching IA Groq / AÏDA
 * Règle stricte: ZÉRO EMOJI dans tout le code, les données et les réponses.
 */

// Expression régulière complète pour détecter et assainir tout emoji Unicode
export const EMOJI_REGEX = /[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{1FA70}-\u{1FAFF}]/gu;

export function stripEmojis(text: string): string {
  if (typeof text !== 'string') return text;
  return text.replace(EMOJI_REGEX, '').replace(/\s{2,}/g, ' ').trim();
}

export function sanitizeObject<T>(obj: T): T {
  if (typeof obj === 'string') {
    return stripEmojis(obj) as unknown as T;
  }
  if (Array.isArray(obj)) {
    return obj.map((item) => sanitizeObject(item)) as unknown as T;
  }
  if (obj !== null && typeof obj === 'object') {
    const result: Record<string, unknown> = {};
    for (const [key, value] of Object.entries(obj)) {
      result[key] = sanitizeObject(value);
    }
    return result as unknown as T;
  }
  return obj;
}

// 6 Dimensions RIASEC
export type RiasecDimension = 'R' | 'I' | 'A' | 'S' | 'E' | 'C';

export interface RiasecQuestion {
  id: string;
  dimension: RiasecDimension;
  category: string;
  categoryFr: string;
  text: string;
  subtext: string;
}

export interface Career {
  id: string;
  title: string;
  name: string; // Alias pour rétrocompatibilité
  sector: string;
  hollandCode: string;
  primaryDimensions: RiasecDimension[];
  demand: 'Tres Forte' | 'Forte' | 'En Croissance';
  jobDemand: string; // Alias
  growthTrend: string;
  salary: string;
  averageSalary: string; // Alias
  salaryRange: string; // Alias
  description: string;
  requiredSkills: string[];
  relevantSchools: string[];
  matchScore?: number;
}

export interface Institution {
  id: string;
  name: string;
  type: 'public' | 'private' | 'inter-etats';
  city: string;
  accreditation: string;
  status: string; // Alias
  programs: string[];
  admissionLevel: string;
  website?: string;
  matchScore?: number;
}

export interface RiasecScores {
  [key: string]: number;
  R: number; // Réaliste
  I: number; // Investigateur
  A: number; // Artistique
  S: number; // Social
  E: number; // Entreprenant
  C: number; // Conventionnel
}

export interface MatchProfile {
  code: string;
  title: string;
  description: string;
  summary?: string; // Alias
  dominantTraits: string[];
  strengths: string[];
  advice: string;
  scores?: RiasecScores | Record<string, number>;
}

export interface MatchResponse {
  success?: boolean;
  profile: MatchProfile;
  careers: Career[];
  institutions: Institution[];
  schools?: Institution[]; // Alias pour compatibilité
  executionMode?: 'groq' | 'fallback_deterministic';
}

// Les 12 Questions RIASEC Calibrées (2 par dimension, entrelacées R-I-A-S-E-C, R-I-A-S-E-C)
export const RIASEC_QUESTIONS: RiasecQuestion[] = [
  {
    id: 'q1',
    dimension: 'R',
    category: 'Réaliste',
    categoryFr: 'Concret & Terrain',
    text: "J'aime manipuler des outils, réparer des équipements ou concevoir des installations concrètes.",
    subtext: "Activités manuelles, mécanique, électronique ou travail physique en atelier et en extérieur.",
  },
  {
    id: 'q2',
    dimension: 'I',
    category: 'Investigateur',
    categoryFr: 'Analyse & Sciences',
    text: "Résoudre des problèmes logiques, analyser des données ou décortiquer un système complexe me passionne.",
    subtext: "Curiosité scientifique, modélisation mathématique, programmation et recherche approfondie.",
  },
  {
    id: 'q3',
    dimension: 'A',
    category: 'Artistique',
    categoryFr: 'Créativité & Design',
    text: "J'aime imaginer des concepts visuels, créer du contenu ou exprimer des idées originales.",
    subtext: "Conception graphique, design d'interfaces, écriture, expression audiovisuelle et innovation esthétique.",
  },
  {
    id: 'q4',
    dimension: 'S',
    category: 'Social',
    categoryFr: 'Entraide & Éducation',
    text: "Aider les autres à progresser, transmettre des connaissances ou soigner m'apporte une réelle satisfaction.",
    subtext: "Pédagogie, écoute active, médiation, santé communautaire et travail collaboratif solidaire.",
  },
  {
    id: 'q5',
    dimension: 'E',
    category: 'Entreprenant',
    categoryFr: 'Leadership & Affaires',
    text: "Prendre des initiatives, diriger des projets, convaincre une équipe et négocier m'enthousiasme.",
    subtext: "Esprit d'entreprise, vision stratégique, audace commerciale et développement de partenariats.",
  },
  {
    id: 'q6',
    dimension: 'C',
    category: 'Conventionnel',
    categoryFr: 'Organisation & Méthode',
    text: "J'apprécie l'ordre, la rigueur méthodique, la gestion de données chiffrées et les procédures claires.",
    subtext: "Structuration administrative, comptabilité, conformité réglementaire et contrôle qualité.",
  },
  {
    id: 'q7',
    dimension: 'R',
    category: 'Réaliste',
    categoryFr: 'Concret & Terrain',
    text: "Je préfère les activités pratiques sur le terrain ou sur un chantier plutôt que rester assis devant un bureau.",
    subtext: "Infrastructures, génie civil, gestion d'exploitations agricoles ou réseaux télécoms.",
  },
  {
    id: 'q8',
    dimension: 'I',
    category: 'Investigateur',
    categoryFr: 'Analyse & Sciences',
    text: "Les technologies d'avenir, le code informatique et les découvertes scientifiques attirent immédiatement mon attention.",
    subtext: "Intelligence artificielle, cybersécurité, biotechnologies et systèmes embarqués.",
  },
  {
    id: 'q9',
    dimension: 'A',
    category: 'Artistique',
    categoryFr: 'Créativité & Design',
    text: "Improviser et proposer une approche originale me met plus à l'aise que suivre un protocole rigide.",
    subtext: "Pensée latérale, créativité décalée, storytelling et architecture de marque.",
  },
  {
    id: 'q10',
    dimension: 'S',
    category: 'Social',
    categoryFr: 'Entraide & Éducation',
    text: "Travailler au sein d'un collectif uni et veiller à la bonne entente du groupe est capital pour moi.",
    subtext: "Cohésion d'équipe, accompagnement psychosocial, ressources humaines et bien-être communautaire.",
  },
  {
    id: 'q11',
    dimension: 'E',
    category: 'Entreprenant',
    categoryFr: 'Leadership & Affaires',
    text: "Identifier des opportunités économiques, lancer de nouvelles activités et relever des défis me stimule.",
    subtext: "Création de valeur, management d'opérations, levée de fonds et impact sur le marché ouest-africain.",
  },
  {
    id: 'q12',
    dimension: 'C',
    category: 'Conventionnel',
    categoryFr: 'Organisation & Méthode',
    text: "Planifier minutieusement mes étapes et vérifier les détails m'évite les erreurs et les imprévus.",
    subtext: "Rigueur d'exécution, audit systématique, respect des échéances et traçabilité.",
  },
];

// Référentiel des 16 Métiers Porteurs au Togo (issu de seed_careers.sql & marché UEMOA)
export const TOGO_CAREERS_CATALOG: Career[] = [
  {
    id: 'dev-web-mobile',
    title: 'Développeur Web & Mobile / Ingénieur Cloud',
    name: 'Développeur Web & Mobile / Ingénieur Cloud',
    sector: 'Technologie & IT',
    hollandCode: 'IRE',
    primaryDimensions: ['I', 'R', 'E'],
    demand: 'Tres Forte',
    jobDemand: 'Tres Forte',
    growthTrend: 'En très forte croissance au Togo et en Afrique de l’Ouest',
    salary: '250 000 - 850 000 FCFA / mois',
    averageSalary: '450 000 FCFA / mois',
    salaryRange: '250 000 - 850 000 FCFA / mois',
    description: 'Conception et déploiement d’applications robustes, API sécurisées et plateformes cloud adaptées aux besoins de numérisation des entreprises locales.',
    requiredSkills: ['TypeScript', 'Python', 'Bases de données SQL / NoSQL', 'Architecture Cloud', 'Git & CI/CD'],
    relevantSchools: ['Université de Lomé (UL)', 'Institut Africain d’Informatique (IAI-Togo)', 'ESGIS', 'IPNET Institute'],
  },
  {
    id: 'data-analyst-ia',
    title: 'Data Analyst & Spécialiste IA',
    name: 'Data Analyst & Spécialiste IA',
    sector: 'Technologie & IT',
    hollandCode: 'ICE',
    primaryDimensions: ['I', 'C', 'E'],
    demand: 'Tres Forte',
    jobDemand: 'Tres Forte',
    growthTrend: 'Secteur stratégique en expansion rapide',
    salary: '300 000 - 900 000 FCFA / mois',
    averageSalary: '500 000 FCFA / mois',
    salaryRange: '300 000 - 900 000 FCFA / mois',
    description: 'Valorisation des flux de données d’entreprise, modélisation prédictive et conception d’outils d’aide à la décision pour banques, télécoms et logistique portuaire.',
    requiredSkills: ['SQL avancé', 'Python / R', 'Power BI / Tableau', 'Machine Learning', 'Statistiques inférentielles'],
    relevantSchools: ['Université de Lomé (UL)', 'IAI-Togo', 'ESGIS'],
  },
  {
    id: 'cybersecurite-reseaux',
    title: 'Architecte Réseaux & Cybersécurité',
    name: 'Architecte Réseaux & Cybersécurité',
    sector: 'Technologie & IT',
    hollandCode: 'IRC',
    primaryDimensions: ['I', 'R', 'C'],
    demand: 'Tres Forte',
    jobDemand: 'Tres Forte',
    growthTrend: 'Priorité nationale et sous-régionale UEMOA',
    salary: '350 000 - 1 000 000 FCFA / mois',
    averageSalary: '600 000 FCFA / mois',
    salaryRange: '350 000 - 1 000 000 FCFA / mois',
    description: 'Protection des infrastructures critiques contre les cybermenaces, sécurisation des réseaux d’entreprises et gestion des incidents de sécurité.',
    requiredSkills: ['Sécurité Réseaux', 'Cryptographie', 'Audit de sécurité', 'Firewalls & SIEM', 'Linux / Cisco'],
    relevantSchools: ['Université de Lomé (UL)', 'IPNET Institute', 'IAI-Togo', 'ESGIS'],
  },
  {
    id: 'ingenieur-btp-civil',
    title: 'Ingénieur Génie Civil & BTP',
    name: 'Ingénieur Génie Civil & BTP',
    sector: 'Ingénierie & BTP',
    hollandCode: 'RIE',
    primaryDimensions: ['R', 'I', 'E'],
    demand: 'Tres Forte',
    jobDemand: 'Tres Forte',
    growthTrend: 'Croissance soutenue portée par les grands travaux de la feuille de route Togo 2025',
    salary: '350 000 - 1 200 000 FCFA / mois',
    averageSalary: '650 000 FCFA / mois',
    salaryRange: '350 000 - 1 200 000 FCFA / mois',
    description: 'Supervision des études techniques, dimensionnement de structures et pilotage de chantiers routiers, portuaires et immobiliers durables.',
    requiredSkills: ['Calcul de structures', 'AutoCAD / Revit', 'Gestion de chantier BTP', 'Résistance des matériaux'],
    relevantSchools: ['Université de Lomé (UL) - ENSI', 'FORMATEC', 'CERFER'],
  },
  {
    id: 'architecte-urbaniste',
    title: 'Architecte & Urbaniste',
    name: 'Architecte & Urbaniste',
    sector: 'Architecture & Design',
    hollandCode: 'AIR',
    primaryDimensions: ['A', 'I', 'R'],
    demand: 'Forte',
    jobDemand: 'Forte',
    growthTrend: 'Forte demande induite par l’urbanisation du Grand Lomé et des villes secondaires',
    salary: '300 000 - 1 100 000 FCFA / mois',
    averageSalary: '550 000 FCFA / mois',
    salaryRange: '300 000 - 1 100 000 FCFA / mois',
    description: 'Conception d’édifices modernes et bioclimatiques, aménagement durable du territoire et planification des espaces de vie urbains.',
    requiredSkills: ['Conception architecturale', 'BIM / ArchiCAD', 'Urbanisme durable', 'Réglementation foncière'],
    relevantSchools: ['EAMAU Lomé', 'Université de Lomé (UL)'],
  },
  {
    id: 'ingenieur-agronome',
    title: 'Ingénieur Agronome & Agroalimentaire',
    name: 'Ingénieur Agronome & Agroalimentaire',
    sector: 'Agriculture & Environnement',
    hollandCode: 'RIE',
    primaryDimensions: ['R', 'I', 'E'],
    demand: 'Tres Forte',
    jobDemand: 'Tres Forte',
    growthTrend: 'Secteur clé national représentant 40% du PIB et pôle agro-industriel de la PIA',
    salary: '250 000 - 750 000 FCFA / mois',
    averageSalary: '450 000 FCFA / mois',
    salaryRange: '250 000 - 750 000 FCFA / mois',
    description: 'Optimisation des rendements culturaux, mécanisation raisonnée, transformation des produits locaux et préservation des écosystèmes.',
    requiredSkills: ['Agronomie tropicale', 'Agro-industrie', 'Gestion de filières agricoles', 'Systèmes d’irrigation'],
    relevantSchools: ['Université de Lomé (UL) - ESA', 'INFA de Tové', 'Université de Kara (UK)'],
  },
  {
    id: 'medecin-sante',
    title: 'Médecin Généraliste / Spécialiste',
    name: 'Médecin Généraliste / Spécialiste',
    sector: 'Santé & Soins',
    hollandCode: 'ISR',
    primaryDimensions: ['I', 'S', 'R'],
    demand: 'Tres Forte',
    jobDemand: 'Tres Forte',
    growthTrend: 'Besoin médical structurel urgent à l’échelle nationale',
    salary: '400 000 - 1 200 000 FCFA / mois',
    averageSalary: '700 000 FCFA / mois',
    salaryRange: '400 000 - 1 200 000 FCFA / mois',
    description: 'Diagnostic clinique, prise en charge thérapeutique des patients et participation aux campagnes de santé publique nationales.',
    requiredSkills: ['Diagnostic clinique', 'Prise en charge d’urgence', 'Pharmacologie', 'Éthique médicale'],
    relevantSchools: ['Université de Lomé (UL) - FSS', 'Université de Kara (UK)'],
  },
  {
    id: 'pharmacien-biologiste',
    title: 'Pharmacien & Biologiste Médical',
    name: 'Pharmacien & Biologiste Médical',
    sector: 'Santé & Pharmacie',
    hollandCode: 'ICS',
    primaryDimensions: ['I', 'C', 'S'],
    demand: 'Forte',
    jobDemand: 'Forte',
    growthTrend: 'Développement de la production pharmaceutique locale et réseaux de distribution',
    salary: '350 000 - 850 000 FCFA / mois',
    averageSalary: '550 000 FCFA / mois',
    salaryRange: '350 000 - 850 000 FCFA / mois',
    description: 'Délivrance sécurisée de médicaments, analyses biomédicales et contrôle qualité des préparations officinales et industrielles.',
    requiredSkills: ['Chimie pharmaceutique', 'Biologie médicale', 'Bonnes pratiques d’officine', 'Réglementation sanitaire'],
    relevantSchools: ['Université de Lomé (UL) - FSS'],
  },
  {
    id: 'comptable-auditeur',
    title: 'Comptable & Auditeur Financier',
    name: 'Comptable & Auditeur Financier',
    sector: 'Finance & Gestion',
    hollandCode: 'CEI',
    primaryDimensions: ['C', 'E', 'I'],
    demand: 'Tres Forte',
    jobDemand: 'Tres Forte',
    growthTrend: 'Hub financier de Lomé (sièges régionaux de banques et institutions multilatérales)',
    salary: '250 000 - 850 000 FCFA / mois',
    averageSalary: '450 000 FCFA / mois',
    salaryRange: '250 000 - 850 000 FCFA / mois',
    description: 'Tenue des comptes selon le référentiel SYSCOHADA, audit financier et optimisation des processus fiscaux et de gestion interne.',
    requiredSkills: ['Normes SYSCOHADA', 'Audit comptable', 'Fiscalité togolaise', 'Logiciels ERP / Excel avancé'],
    relevantSchools: ['ESAG-NDE', 'Université de Lomé (UL) - FASEG', 'UCAO-UUT', 'ESGIS'],
  },
  {
    id: 'banquier-analyste',
    title: 'Analyste Bancaire & Gestionnaire de Risque',
    name: 'Analyste Bancaire & Gestionnaire de Risque',
    sector: 'Banque & Assurance',
    hollandCode: 'CEI',
    primaryDimensions: ['C', 'E', 'I'],
    demand: 'Forte',
    jobDemand: 'Forte',
    growthTrend: 'Stabilité et attractivité du pôle bancaire togolais (Ecobank, BOAD, BIDC)',
    salary: '300 000 - 950 000 FCFA / mois',
    averageSalary: '550 000 FCFA / mois',
    salaryRange: '300 000 - 950 000 FCFA / mois',
    description: 'Évaluation de la solvabilité des dossiers de crédit d’entreprise, analyse financière et conformité aux directives prudentielles de la BCEAO.',
    requiredSkills: ['Analyse de crédit', 'Réglementation BCEAO', 'Modélisation financière', 'Gestion de trésorerie'],
    relevantSchools: ['ESAG-NDE', 'Université de Lomé (UL)', 'Lomé Business School (LBS)'],
  },
  {
    id: 'marketing-digital',
    title: 'Responsable Marketing Digital & E-Commerce',
    name: 'Responsable Marketing Digital & E-Commerce',
    sector: 'Commerce & Médias',
    hollandCode: 'EAS',
    primaryDimensions: ['E', 'A', 'S'],
    demand: 'Forte',
    jobDemand: 'Forte',
    growthTrend: 'Essor massif de la vente en ligne et des services numériques marchands',
    salary: '200 000 - 700 000 FCFA / mois',
    averageSalary: '380 000 FCFA / mois',
    salaryRange: '200 000 - 700 000 FCFA / mois',
    description: 'Stratégies d’acquisition en ligne, gestion des campagnes publicitaires et animation des communautés sur les réseaux sociaux.',
    requiredSkills: ['SEO / SEA', 'Social Media Management', 'Copywriting', 'Web Analytics', 'Growth Marketing'],
    relevantSchools: ['ESGIS', 'Lomé Business School (LBS)', 'Université de Lomé (UL)'],
  },
  {
    id: 'entrepreneur-innovation',
    title: 'Entrepreneur & Chef de Projet Innovant',
    name: 'Entrepreneur & Chef de Projet Innovant',
    sector: 'Entrepreneuriat & Innovation',
    hollandCode: 'EIS',
    primaryDimensions: ['E', 'I', 'S'],
    demand: 'Tres Forte',
    jobDemand: 'Tres Forte',
    growthTrend: 'Écosystème startup togolais très dynamique soutenu par les dispositifs d’aide publique',
    salary: '250 000 - 1 500 000 FCFA / mois',
    averageSalary: '600 000 FCFA / mois',
    salaryRange: '250 000 - 1 500 000 FCFA / mois',
    description: 'Création d’entreprises technologiques ou de services, validation de modèles économiques viables et management d’équipes pluridisciplinaires.',
    requiredSkills: ['Business Modeling', 'Gestion de projet agile', 'Négociation commerciale', 'Levée de fonds'],
    relevantSchools: ['Lomé Business School (LBS)', 'ESAG-NDE', 'Université de Lomé (UL)'],
  },
  {
    id: 'enseignant-formateur',
    title: 'Enseignant / Formateur Académique',
    name: 'Enseignant / Formateur Académique',
    sector: 'Éducation & Formation',
    hollandCode: 'SAI',
    primaryDimensions: ['S', 'A', 'I'],
    demand: 'Tres Forte',
    jobDemand: 'Tres Forte',
    growthTrend: 'Plan national de recrutement massif d’enseignants pour le primaire et le secondaire',
    salary: '180 000 - 550 000 FCFA / mois',
    averageSalary: '320 000 FCFA / mois',
    salaryRange: '180 000 - 550 000 FCFA / mois',
    description: 'Transmission de compétences disciplinaires, animation pédagogique interactive et préparation des apprenants aux examens nationaux et concours.',
    requiredSkills: ['Pédagogie active', 'Conception de cours', 'Évaluation des compétences', 'Didactique'],
    relevantSchools: ['ENS Atakpamé', 'Université de Lomé (UL)', 'Université de Kara (UK)'],
  },
  {
    id: 'juriste-affaires',
    title: 'Juriste d’Entreprise & Conseiller Fiscal',
    name: 'Juriste d’Entreprise & Conseiller Fiscal',
    sector: 'Droit & Administration',
    hollandCode: 'ECI',
    primaryDimensions: ['E', 'C', 'I'],
    demand: 'Forte',
    jobDemand: 'Forte',
    growthTrend: 'Complexification des contrats commerciaux OHADA et des contentieux d’affaires',
    salary: '250 000 - 900 000 FCFA / mois',
    averageSalary: '480 000 FCFA / mois',
    salaryRange: '250 000 - 900 000 FCFA / mois',
    description: 'Rédaction de contrats commerciaux, conformité avec le traité OHADA, veille réglementaire et protection des intérêts juridiques de l’entreprise.',
    requiredSkills: ['Droit OHADA', 'Droit du travail togolais', 'Rédaction contractuelle', 'Contentieux commercial'],
    relevantSchools: ['Université de Lomé (UL) - FDD', 'Université de Kara (UK)', 'ISDI'],
  },
  {
    id: 'designer-graphique',
    title: 'Designer Graphique & UI/UX',
    name: 'Designer Graphique & UI/UX',
    sector: 'Création & Médias',
    hollandCode: 'AIS',
    primaryDimensions: ['A', 'I', 'S'],
    demand: 'Forte',
    jobDemand: 'Forte',
    growthTrend: 'Besoin croissant d’identités de marque professionnelles et d’ergonomie pour applications',
    salary: '180 000 - 650 000 FCFA / mois',
    averageSalary: '350 000 FCFA / mois',
    salaryRange: '180 000 - 650 000 FCFA / mois',
    description: 'Création de chartes graphiques percutantes, prototypage d’interfaces web et mobiles sur Figma et conception d’actifs de communication.',
    requiredSkills: ['Figma', 'Adobe Creative Suite', 'Design System', 'Prototypage UX', 'Typographie'],
    relevantSchools: ['ESGIS', 'Université de Lomé (UL)', 'IPNET Institute'],
  },
  {
    id: 'responsable-rh',
    title: 'Responsable Ressources Humaines',
    name: 'Responsable Ressources Humaines',
    sector: 'Management & RH',
    hollandCode: 'SEC',
    primaryDimensions: ['S', 'E', 'C'],
    demand: 'Forte',
    jobDemand: 'Forte',
    growthTrend: 'Professionnalisation de la gestion du capital humain dans les PME et grands groupes',
    salary: '250 000 - 800 000 FCFA / mois',
    averageSalary: '450 000 FCFA / mois',
    salaryRange: '250 000 - 800 000 FCFA / mois',
    description: 'Pilotage du recrutement, gestion prévisionnelle des emplois et compétences (GPEC), administration de la paie et climat social d’entreprise.',
    requiredSkills: ['Recrutement', 'Gestion de la paie', 'Droit social', 'GPEC', 'Médiation d’équipe'],
    relevantSchools: ['Université de Lomé (UL) - FASEG', 'ESAG-NDE', 'UCAO-UUT'],
  },
];

// Référentiel des Établissements Agréés au Togo (MESR / CAMES)
export const TOGO_INSTITUTIONS_CATALOG: Institution[] = [
  {
    id: 'ul-lome',
    name: 'Université de Lomé (UL)',
    type: 'public',
    city: 'Lomé',
    accreditation: 'MESR Togo / CAMES',
    status: 'Agréée MESR Togo / CAMES',
    programs: [
      'École Nationale Supérieure d’Ingénieurs (ENSI) - Génie Civil, Logiciel, Électrique',
      'Faculté des Sciences (FDS) - Mathématiques & Informatique',
      'Faculté des Sciences de la Santé (FSS) - Médecine & Pharmacie',
      'Faculté des Sciences Économiques et de Gestion (FASEG)',
    ],
    admissionLevel: 'BAC C, D, E, F, A selon filière (concours ou étude de dossier)',
    website: 'https://univ-lome.tg',
  },
  {
    id: 'uk-kara',
    name: 'Université de Kara (UK)',
    type: 'public',
    city: 'Kara',
    accreditation: 'MESR Togo / CAMES',
    status: 'Agréée MESR Togo / CAMES',
    programs: [
      'Faculté des Sciences et Techniques (FaST)',
      'Institut Supérieur des Métiers Agricoles (ISMA)',
      'Faculté des Sciences Économiques et de Gestion (FASEG)',
      'Faculté de Droit et des Sciences Politiques (FDSP)',
    ],
    admissionLevel: 'BAC Scientifique ou Littéraire selon filière',
    website: 'https://univ-kara.tg',
  },
  {
    id: 'iai-togo',
    name: 'Institut Africain d’Informatique (IAI-Togo)',
    type: 'inter-etats',
    city: 'Lomé',
    accreditation: 'MESR Togo / CAMES',
    status: 'Agréée MESR Togo / CAMES',
    programs: [
      'Ingénierie des Systèmes d’Information',
      'Génie Logiciel & Technologies Web',
      'Administration Systèmes et Réseaux Informatiques',
    ],
    admissionLevel: 'BAC C, D, E sur concours sous-régional',
    website: 'https://iai-togo.tg',
  },
  {
    id: 'eamau-lome',
    name: 'École Africaine des Métiers de l’Architecture et de l’Urbanisme (EAMAU)',
    type: 'inter-etats',
    city: 'Lomé',
    accreditation: 'CAMES (14 États membres)',
    status: 'Homologuée CAMES',
    programs: [
      'Diplôme d’Architecte (Bac+5)',
      'Diplôme d’Urbaniste (Bac+5)',
      'Licence & Master en Gestion Urbaine',
    ],
    admissionLevel: 'BAC toutes séries sur concours international',
    website: 'https://eamau.org',
  },
  {
    id: 'esgis-lome',
    name: 'École Supérieure de Gestion, d’Informatique et des Sciences (ESGIS)',
    type: 'private',
    city: 'Lomé',
    accreditation: 'MESR Togo / CAMES',
    status: 'Agréée MESR Togo / CAMES',
    programs: [
      'Licence & Master Génie Logiciel & Réseaux',
      'Management des Systèmes d’Information',
      'Marketing Digital & E-Business',
    ],
    admissionLevel: 'BAC sur étude de dossier et entretien',
    website: 'https://esgis.org',
  },
  {
    id: 'esag-nde',
    name: 'École Supérieure d’Administration et de Gestion Notre-Dame de l’Église (ESAG-NDE)',
    type: 'private',
    city: 'Lomé',
    accreditation: 'MESR Togo / CAMES',
    status: 'Agréée MESR Togo / CAMES',
    programs: [
      'Comptabilité, Contrôle et Audit (CCA)',
      'Banque et Finance d’Entreprise',
      'Informatique de Gestion & Management',
    ],
    admissionLevel: 'BAC G2, C, D, A sur étude de dossier',
    website: 'https://esagnde.org',
  },
  {
    id: 'ipnet-institute',
    name: 'Institut de Technologie IPNET (IPNET Institute of Technology)',
    type: 'private',
    city: 'Lomé',
    accreditation: 'MESR Togo',
    status: 'Agréée MESR Togo',
    programs: [
      'Infrastructures Réseaux, Cloud & Datacenter',
      'Cybersécurité Opérationnelle',
      'Génie Logiciel & DevOps',
    ],
    admissionLevel: 'BAC Scientifique ou Technique sur étude de dossier',
    website: 'https://ipnetinstitute.com',
  },
  {
    id: 'formatec-lome',
    name: 'Institut Polyvalent FORMATEC',
    type: 'private',
    city: 'Lomé',
    accreditation: 'MESR Togo / CAMES',
    status: 'Agréée MESR Togo / CAMES',
    programs: [
      'Génie Civil & Bâtiment',
      'Génie Électrique & Énergies Renouvelables',
      'Topographie & Géomatique',
    ],
    admissionLevel: 'BAC C, D, E, F sur étude de dossier',
    website: 'https://formatec.tg',
  },
  {
    id: 'infa-tove',
    name: 'Institut National de Formation Agricole de Tové (INFA de Tové)',
    type: 'public',
    city: 'Kpalimé / Tové',
    accreditation: 'MESR Togo',
    status: 'Agréée MESR Togo',
    programs: [
      'Production Végétale et Animale',
      'Agroéconomie & Gestion d’Exploitation',
      'Foresterie et Génie Rural',
    ],
    admissionLevel: 'BAC C, D ou Brevet Agricole sur concours national',
  },
  {
    id: 'ucao-uut',
    name: 'Université Catholique de l’Afrique de l’Ouest - Unité Universitaire au Togo (UCAO-UUT)',
    type: 'private',
    city: 'Lomé',
    accreditation: 'MESR Togo / CAMES',
    status: 'Agréée MESR Togo / CAMES',
    programs: [
      'Sciences Économiques et de Gestion',
      'Sciences Juridiques & Droit des Affaires',
      'Informatique Appliquée à la Gestion',
    ],
    admissionLevel: 'BAC toutes séries sur étude de dossier',
    website: 'https://ucao-uut.tg',
  },
];

// Calcul des scores normalisés RIASEC (0 - 100)
export function calculateRiasecScores(
  answers?: Record<string, number | boolean | string>,
  providedScores?: Record<string, number>
): RiasecScores {
  if (providedScores && Object.keys(providedScores).length > 0) {
    const rawScores: RiasecScores = {
      R: Math.min(100, Math.max(0, Number(providedScores.R ?? providedScores.Réaliste ?? 50))),
      I: Math.min(100, Math.max(0, Number(providedScores.I ?? providedScores.Investigateur ?? 50))),
      A: Math.min(100, Math.max(0, Number(providedScores.A ?? providedScores.Artistique ?? 50))),
      S: Math.min(100, Math.max(0, Number(providedScores.S ?? providedScores.Social ?? 50))),
      E: Math.min(100, Math.max(0, Number(providedScores.E ?? providedScores.Entreprenant ?? 50))),
      C: Math.min(100, Math.max(0, Number(providedScores.C ?? providedScores.Conventionnel ?? 50))),
    };
    return rawScores;
  }

  const counts: Record<RiasecDimension, { sum: number; count: number }> = {
    R: { sum: 0, count: 0 },
    I: { sum: 0, count: 0 },
    A: { sum: 0, count: 0 },
    S: { sum: 0, count: 0 },
    E: { sum: 0, count: 0 },
    C: { sum: 0, count: 0 },
  };

  if (answers) {
    for (const q of RIASEC_QUESTIONS) {
      const ans = answers[q.id];
      if (ans !== undefined && ans !== null) {
        let val = 3; // neutre par défaut
        if (typeof ans === 'boolean') {
          val = ans ? 5 : 1;
        } else if (typeof ans === 'number') {
          val = Math.min(5, Math.max(1, ans));
        } else if (typeof ans === 'string') {
          const lower = ans.toLowerCase();
          if (lower === 'true' || lower === 'yes' || lower === 'like' || lower === 'positive') val = 5;
          else if (lower === 'false' || lower === 'no' || lower === 'dislike' || lower === 'negative') val = 1;
          else {
            const parsed = parseFloat(ans);
            if (!isNaN(parsed)) val = Math.min(5, Math.max(1, parsed));
          }
        }
        counts[q.dimension].sum += val;
        counts[q.dimension].count += 1;
      }
    }
  }

  // Normalisation sur 100
  const scores: RiasecScores = {
    R: 50,
    I: 50,
    A: 50,
    S: 50,
    E: 50,
    C: 50,
  };

  (Object.keys(counts) as RiasecDimension[]).forEach((dim) => {
    const { sum, count } = counts[dim];
    if (count > 0) {
      // Échelle 1-5 convertie en pourcentage (1 -> 0%, 5 -> 100%)
      const normalized = Math.round(((sum - count) / (count * 4)) * 100);
      scores[dim] = Math.min(100, Math.max(0, normalized));
    }
  });

  return scores;
}

// Extraction des traits dominants et du code Holland
export function extractDominantTraits(scores: RiasecScores): {
  code: string;
  ranked: Array<{ dimension: RiasecDimension; name: string; score: number }>;
} {
  const mapping: Record<RiasecDimension, string> = {
    R: 'Réaliste',
    I: 'Investigateur',
    A: 'Artistique',
    S: 'Social',
    E: 'Entreprenant',
    C: 'Conventionnel',
  };

  const sorted = (Object.keys(scores) as RiasecDimension[])
    .map((dim) => ({
      dimension: dim,
      name: mapping[dim],
      score: scores[dim],
    }))
    .sort((a, b) => b.score - a.score || a.dimension.localeCompare(b.dimension));

  const code = sorted
    .slice(0, 3)
    .map((item) => item.dimension)
    .join('');

  return { code, ranked: sorted };
}

// Générateur de Profil Déterministe
function getArchetypeDetails(code: string, topTraits: string[]): {
  title: string;
  description: string;
  strengths: string[];
  advice: string;
} {
  const primary = code[0] || 'I';

  switch (primary) {
    case 'I':
      return {
        title: 'Profil Analyste Stratégique & Concepteur Technologique',
        description: 'Vous possédez une rigueur intellectuelle remarquable et un sens aigu de la résolution de problèmes. Vous excellez dans l’analyse méthodique des systèmes complexes et la valorisation des données pour guider les décisions stratégiques.',
        strengths: [
          'Capacité d’abstraction et pensée logique poussée',
          'Autonomie dans la résolution d’énigmes techniques',
          'Curiosité pour les innovations scientifiques et le code',
        ],
        advice: 'Orientez-vous vers les filières d’ingénierie logicielle, de science des données ou de recherche appliquée dans les universités et grandes écoles agréées de Lomé.',
      };
    case 'R':
      return {
        title: 'Profil Bâtisseur Concret & Ingénieur de Terrain',
        description: 'Vous vous distinguez par votre pragmatisme, votre habileté technique et votre volonté d’agir sur le monde réel. Vous appréciez les réalisations tangibles, les chantiers et les infrastructures concrètes.',
        strengths: [
          'Maîtrise pratique et sens du concret',
          'Capacité à opérer efficacement sur le terrain',
          'Esprit méthodique face aux contraintes matérielles',
        ],
        advice: 'Les cursus en génie civil, télécoms, génie mécanique ou agronomie tropicale sont parfaitement adaptés à votre profil.',
      };
    case 'A':
      return {
        title: 'Profil Créateur Visuel & Innovateur Conceptuel',
        description: 'Votre imagination fertile et votre sensibilité esthétique vous permettent de concevoir des solutions originales et inspirantes. Vous transformez des idées abstraites en identités visuelles fortes et expériences marquantes.',
        strengths: [
          'Créativité intuitive et sens du design',
          'Capacité à imaginer des concepts visuels uniques',
          'Pensée latérale et rejet des solutions stéréotypées',
        ],
        advice: 'Les formations d’architecture, de design UI/UX, de communication visuelle et d’urbanisme constituent votre voie royale.',
      };
    case 'S':
      return {
        title: 'Profil Facilitateur Humain & Leader Pédagogique',
        description: 'Votre empathie naturelle, votre sens de l’écoute et votre aisance relationnelle font de vous un pilier dans tout travail d’équipe. Vous trouvez votre épanouissement dans l’accompagnement, l’enseignement et le bien-être collectif.',
        strengths: [
          'Intelligence émotionnelle et écoute active',
          'Aptitude naturelle à transmettre et expliquer',
          'Engagement sincère pour la communauté et le collectif',
        ],
        advice: 'Privilégiez les filières en sciences de l’éducation, médecine, management des ressources humaines ou sciences sociales.',
      };
    case 'E':
      return {
        title: 'Profil Entrepreneur Dirigeant & Négociateur d’Impact',
        description: 'Dynamique et convaincant, vous possédez l’énergie nécessaire pour porter des projets d’envergure, mobiliser des partenaires et saisir les opportunités de marché à fort impact.',
        strengths: [
          'Sens aigu des opportunités d’affaires',
          'Aisance oratoire et force de persuasion',
          'Goût pour le leadership et la prise de décision rapide',
        ],
        advice: 'Les grandes écoles de management, de finance, de commerce international et d’entrepreneuriat à Lomé valoriseront votre tempérament.',
      };
    case 'C':
    default:
      return {
        title: 'Profil Gestionnaire Méthodique & Auditeur de Précision',
        description: 'La rigueur, le respect des procédures et la précision méticuleuse caractérisent votre démarche. Vous êtes le garant de la fiabilité financière, de la conformité réglementaire et de l’efficacité administrative.',
        strengths: [
          'Rigueur exemplaire et souci du détail',
          'Excellente gestion des flux de données chiffrées',
          'Fiabilité sans faille dans le suivi des procédures',
        ],
        advice: 'Les filières d’expertise comptable, d’audit financier, de gestion administrative et de conformité bancaire sont vos meilleurs tremplins.',
      };
  }
}

// Moteur de Repli Déterministe (Fallback Togo)
export function generateDeterministicMatch(scores: RiasecScores): MatchResponse {
  const { code, ranked } = extractDominantTraits(scores);
  const dominantTraits = ranked.slice(0, 3).map((item) => `${item.name} (${item.score}%)`);

  const archetype = getArchetypeDetails(code, dominantTraits);

  // Score de compatibilité pour chaque métier
  const scoredCareers = TOGO_CAREERS_CATALOG.map((career) => {
    let compatibilityScore = 0;
    career.primaryDimensions.forEach((dim, idx) => {
      const weight = idx === 0 ? 0.5 : idx === 1 ? 0.3 : 0.2;
      compatibilityScore += (scores[dim] ?? 50) * weight;
    });

    // Bonus de demande
    const demandBonus = career.demand === 'Tres Forte' ? 5 : 2;
    const finalScore = Math.min(96, Math.max(78, Math.round(compatibilityScore * 0.9 + demandBonus)));

    return {
      ...career,
      matchScore: finalScore,
    };
  });

  // Tri déterministe: score décroissant, puis demande, puis titre
  scoredCareers.sort((a, b) => (b.matchScore ?? 0) - (a.matchScore ?? 0) || a.title.localeCompare(b.title));

  const top3Careers = scoredCareers.slice(0, 3);

  // Sélection des 3 établissements togolais les plus adaptés
  const relevantSchoolNames = new Set<string>();
  top3Careers.forEach((c) => {
    c.relevantSchools.forEach((s) => relevantSchoolNames.add(s));
  });

  const selectedInstitutions: Institution[] = [];

  // Ajouter d'abord les écoles explicitement mentionnées dans les carrières
  for (const inst of TOGO_INSTITUTIONS_CATALOG) {
    if (
      relevantSchoolNames.has(inst.name) ||
      Array.from(relevantSchoolNames).some((name) => inst.name.includes(name) || name.includes(inst.name))
    ) {
      selectedInstitutions.push({ ...inst, matchScore: 92 - selectedInstitutions.length * 3 });
      if (selectedInstitutions.length === 3) break;
    }
  }

  // Compléter à 3 si besoin
  if (selectedInstitutions.length < 3) {
    for (const inst of TOGO_INSTITUTIONS_CATALOG) {
      if (!selectedInstitutions.some((s) => s.id === inst.id)) {
        selectedInstitutions.push({ ...inst, matchScore: 86 - selectedInstitutions.length * 2 });
        if (selectedInstitutions.length === 3) break;
      }
    }
  }

  const response: MatchResponse = {
    success: true,
    profile: {
      code,
      title: stripEmojis(archetype.title),
      description: stripEmojis(archetype.description),
      summary: stripEmojis(archetype.description),
      dominantTraits: dominantTraits.map(stripEmojis),
      strengths: archetype.strengths.map(stripEmojis),
      advice: stripEmojis(archetype.advice),
      scores,
    },
    careers: top3Careers.map((c) => ({
      ...c,
      title: stripEmojis(c.title),
      name: stripEmojis(c.name),
      sector: stripEmojis(c.sector),
      description: stripEmojis(c.description),
      growthTrend: stripEmojis(c.growthTrend),
      salary: stripEmojis(c.salary),
      averageSalary: stripEmojis(c.averageSalary),
      salaryRange: stripEmojis(c.salaryRange),
      requiredSkills: c.requiredSkills.map(stripEmojis),
      relevantSchools: c.relevantSchools.map(stripEmojis),
    })),
    institutions: selectedInstitutions.map((inst) => ({
      ...inst,
      name: stripEmojis(inst.name),
      city: stripEmojis(inst.city),
      accreditation: stripEmojis(inst.accreditation),
      status: stripEmojis(inst.status),
      programs: inst.programs.map(stripEmojis),
      admissionLevel: stripEmojis(inst.admissionLevel),
    })),
    schools: selectedInstitutions.map((inst) => ({
      ...inst,
      name: stripEmojis(inst.name),
      city: stripEmojis(inst.city),
      accreditation: stripEmojis(inst.accreditation),
      status: stripEmojis(inst.status),
      programs: inst.programs.map(stripEmojis),
      admissionLevel: stripEmojis(inst.admissionLevel),
    })),
    executionMode: 'fallback_deterministic',
  };

  return sanitizeObject(response);
}

// Appel de l'IA Groq avec le persona AÏDA
export async function generateGroqMatch(
  scores: RiasecScores,
  context?: { schoolLevel?: string; serieBac?: string; city?: string }
): Promise<MatchResponse> {
  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey || apiKey.trim() === '' || apiKey === 'dummy' || apiKey === 'test') {
    return generateDeterministicMatch(scores);
  }

  const { code, ranked } = extractDominantTraits(scores);
  const topTraits = ranked.slice(0, 3).map((item) => `${item.name}: ${item.score}%`).join(', ');

  const systemPrompt = `Tu es AÏDA, la conseillère d'orientation intelligente d'élite pour ActivEducation, spécialisée dans le système d'enseignement supérieur et le marché de l'emploi au Togo et en Afrique de l'Ouest.
Ta mission est d'analyser le profil RIASEC de l'étudiant, de générer son profil psychologique, de recommander EXACTEMENT 3 métiers d'avenir au Togo, et EXACTEMENT 3 établissements d'enseignement supérieur agréés au Togo (Ministère de l'Enseignement Supérieur et de la Recherche - MESR Togo ou CAMES).

RÈGLES ABSOLUES ET SANS EXCEPTION :
1. ZÉRO EMOJI : L'utilisation du moindre caractère emoji, émoticône ou symbole décoratif est formellement interdite dans toute la réponse.
2. Établissements réels du Togo uniquement : Choisis parmi Université de Lomé (UL), Université de Kara (UK), Institut Africain d'Informatique (IAI-Togo), École Africaine des Métiers de l'Architecture et de l'Urbanisme (EAMAU), ESGIS, ESAG-NDE, IPNET Institute of Technology, FORMATEC, INFA de Tové, UCAO-UUT.
3. Salaires en FCFA réalistes au Togo.
4. Réponds STRICTEMENT et UNIQUEMENT avec un objet JSON respectant le format suivant sans aucun texte autour :

{
  "profile": {
    "code": "${code}",
    "title": "Titre valorisant du profil",
    "description": "Synthèse bienveillante et analytique du profil",
    "dominantTraits": ["Trait 1", "Trait 2", "Trait 3"],
    "strengths": ["Force 1", "Force 2", "Force 3"],
    "advice": "Conseil d'orientation stratégique concret"
  },
  "careers": [
    {
      "id": "identifiant-unique",
      "title": "Nom du métier",
      "sector": "Secteur d'activité",
      "matchScore": 95,
      "demand": "Tres Forte",
      "salary": "350 000 - 850 000 FCFA / mois",
      "description": "Description du métier et impact au Togo",
      "requiredSkills": ["Compétence 1", "Compétence 2", "Compétence 3"],
      "relevantSchools": ["Nom École 1", "Nom École 2"]
    }
  ],
  "institutions": [
    {
      "id": "identifiant-etablissement",
      "name": "Nom officiel complet",
      "type": "public",
      "city": "Lomé",
      "accreditation": "MESR Togo / CAMES",
      "programs": ["Filière 1", "Filière 2"]
    }
  ]
}`;

  const userPrompt = `Voici les résultats de l'étudiant :
Code Holland calculé : ${code}
Scores dimensionnels : Réaliste: ${scores.R}%, Investigateur: ${scores.I}%, Artistique: ${scores.A}%, Social: ${scores.S}%, Entreprenant: ${scores.E}%, Conventionnel: ${scores.C}%
Traits dominants : ${topTraits}
Niveau : ${context?.schoolLevel || 'Terminale / Premier cycle universitaire'}
Série BAC : ${context?.serieBac || 'Générale'}

Génère la recommandation complète au format JSON. EXACTEMENT 3 métiers et EXACTEMENT 3 établissements au Togo. AUCUN EMOJI.`;

  const model = process.env.GROQ_MODEL || 'llama-3.3-70b-versatile';

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 9000); // 9 secondes timeout

  try {
    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
        response_format: { type: 'json_object' },
        temperature: 0.3,
        max_tokens: 1600,
      }),
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      console.warn(`Groq API returned HTTP ${response.status}. Falling back to deterministic engine.`);
      return generateDeterministicMatch(scores);
    }

    const data = await response.json();
    const content = data.choices?.[0]?.message?.content;
    if (!content) {
      return generateDeterministicMatch(scores);
    }

    const parsed = JSON.parse(content);

    // Valider la structure
    if (
      !parsed.profile ||
      !Array.isArray(parsed.careers) ||
      parsed.careers.length < 3 ||
      !Array.isArray(parsed.institutions) ||
      parsed.institutions.length < 3
    ) {
      console.warn('Groq response did not meet length requirements. Falling back to deterministic engine.');
      return generateDeterministicMatch(scores);
    }

    // Normaliser les 3 métiers et 3 institutions
    const careers: Career[] = parsed.careers.slice(0, 3).map((c: Record<string, unknown>, idx: number) => ({
      id: String(c.id || `career-${idx + 1}`),
      title: stripEmojis(String(c.title || c.name || 'Métier')).trim(),
      name: stripEmojis(String(c.name || c.title || 'Métier')).trim(),
      sector: stripEmojis(String(c.sector || 'Technologie & Économie')).trim(),
      hollandCode: String(c.hollandCode || code),
      primaryDimensions: ['I', 'R', 'E'],
      demand: (c.demand === 'Tres Forte' || c.demand === 'Forte' ? c.demand : 'Tres Forte') as 'Tres Forte',
      jobDemand: String(c.demand || 'Tres Forte'),
      growthTrend: stripEmojis(String(c.growthTrend || 'Secteur en forte expansion au Togo')),
      salary: stripEmojis(String(c.salary || c.salaryRange || c.averageSalary || '300 000 - 800 000 FCFA / mois')),
      averageSalary: stripEmojis(String(c.salary || c.salaryRange || c.averageSalary || '300 000 - 800 000 FCFA / mois')),
      salaryRange: stripEmojis(String(c.salary || c.salaryRange || c.averageSalary || '300 000 - 800 000 FCFA / mois')),
      description: stripEmojis(String(c.description || 'Métier porteur au Togo.')),
      requiredSkills: Array.isArray(c.requiredSkills) ? c.requiredSkills.map((s) => stripEmojis(String(s))) : ['Compétences techniques'],
      relevantSchools: Array.isArray(c.relevantSchools) ? c.relevantSchools.map((s) => stripEmojis(String(s))) : ['Université de Lomé (UL)'],
      matchScore: typeof c.matchScore === 'number' ? Math.min(100, Math.max(60, c.matchScore)) : 92 - idx * 4,
    }));

    const institutions: Institution[] = parsed.institutions.slice(0, 3).map((inst: Record<string, unknown>, idx: number) => ({
      id: String(inst.id || `inst-${idx + 1}`),
      name: stripEmojis(String(inst.name || 'Université de Lomé (UL)')).trim(),
      type: (inst.type === 'private' ? 'private' : 'public') as 'public' | 'private',
      city: stripEmojis(String(inst.city || 'Lomé')).trim(),
      accreditation: stripEmojis(String(inst.accreditation || 'MESR Togo / CAMES')).trim(),
      status: stripEmojis(String(inst.accreditation || 'MESR Togo / CAMES')).trim(),
      programs: Array.isArray(inst.programs) ? inst.programs.map((p) => stripEmojis(String(p))) : ['Formations d’excellence'],
      admissionLevel: stripEmojis(String(inst.admissionLevel || 'BAC sur concours ou étude de dossier')),
      matchScore: 90 - idx * 3,
    }));

    const result: MatchResponse = {
      success: true,
      profile: {
        code: stripEmojis(String(parsed.profile.code || code)),
        title: stripEmojis(String(parsed.profile.title || 'Profil Stratégique & Technologique')),
        description: stripEmojis(String(parsed.profile.description || parsed.profile.summary || 'Profil d’excellence.')),
        summary: stripEmojis(String(parsed.profile.summary || parsed.profile.description || 'Profil d’excellence.')),
        dominantTraits: Array.isArray(parsed.profile.dominantTraits)
          ? parsed.profile.dominantTraits.map((t: unknown) => stripEmojis(String(t)))
          : [topTraits],
        strengths: Array.isArray(parsed.profile.strengths)
          ? parsed.profile.strengths.map((s: unknown) => stripEmojis(String(s)))
          : ['Rigueur analytique', 'Autonomie'],
        advice: stripEmojis(String(parsed.profile.advice || 'Poursuivez un cursus d’enseignement supérieur adapté.')),
        scores,
      },
      careers,
      institutions,
      schools: institutions,
      executionMode: 'groq',
    };

    return sanitizeObject(result);
  } catch (error) {
    clearTimeout(timeoutId);
    console.warn('Groq fetch error or timeout, switching to deterministic fallback:', error);
    return generateDeterministicMatch(scores);
  }
}

// Fonction Principale de Matching
export async function matchOrientation(payload: {
  answers?: Record<string, number | boolean | string>;
  scores?: Record<string, number>;
  context?: { schoolLevel?: string; serieBac?: string; city?: string };
}): Promise<MatchResponse> {
  const scores = calculateRiasecScores(payload.answers, payload.scores);
  return generateGroqMatch(scores, payload.context);
}

// ============================================================================
// MILESTONE 3 : Interfaces & Moteur Déterministe Résilient R2
// ============================================================================

export interface PsychologicalProfileM3 {
  dominantTraits: string[];
  strengths: string[];
  weaknesses: string[];
  summary: string;
}

export interface RecommendedCareerM3 {
  title: string;
  matchPercentage: number;
  description: string;
  salaryRangeCFA: string;
  demandInTogo: 'Faible' | 'Moyenne' | 'Forte';
}

export interface RecommendedSchoolM3 {
  name: string;
  program: string;
  estimatedAnnualCostCFA: string;
  whyThisSchool: string;
}

export interface OrientationResultM3 {
  psychologicalProfile: PsychologicalProfileM3;
  recommendedCareers: RecommendedCareerM3[];
  recommendedSchools: RecommendedSchoolM3[];
  executionMode?: 'groq' | 'fallback_deterministic';
}

/**
 * Générateur Déterministe d'Orientation M3
 * Produit un résultat authentique, fondé sur les catalogues togolais,
 * 100% sans emoji et résilient même sans connexion internet ou clé API.
 */
export function generateDeterministicOrientationM3(rawAnswers: any): OrientationResultM3 {
  const answers = rawAnswers && typeof rawAnswers === 'object' && rawAnswers.answers ? rawAnswers.answers : (rawAnswers || {});

  const interestList: string[] = Array.isArray(answers.interests)
    ? answers.interests
    : Array.isArray(answers.interets)
      ? answers.interets
      : typeof answers.interests === 'string'
        ? [answers.interests]
        : [];

  const subjectList: string[] = Array.isArray(answers.strongSubjects)
    ? answers.strongSubjects
    : Array.isArray(answers.matieresFortes)
      ? answers.matieresFortes
      : typeof answers.strongSubjects === 'string'
        ? [answers.strongSubjects]
        : [];

  const otherSubject: string = String(answers.otherSubject || answers.autreMatiere || '');
  const budgetStr: string = String(answers.budget || '').toLowerCase();
  const mobilityStr: string = String(answers.mobility || answers.region || '').toLowerCase();
  const cityStr: string = String(answers.currentCity || answers.ville || answers.city || '').toLowerCase();

  const interestText = interestList.join(' ').toLowerCase();
  const subjectText = subjectList.join(' ').toLowerCase();
  const otherText = otherSubject.toLowerCase();
  const allTokens = `${interestText} ${subjectText} ${otherText} ${mobilityStr} ${cityStr}`.toLowerCase();

  // 1. Détection ciblée de l'intérêt principal de l'étudiant (Priorité Haute)
  const interestTech = /sciences?\s*(?:&|et)?\s*nouvelles?\s*technologies?|sciences-tech|informatique|numérique/i.test(interestText);
  const interestEng = /bâtiment|industrie|ingénierie|ingenierie-btp|génie\s*civil/i.test(interestText);
  const interestHealth = /santé|biologie|sciences?\s*médicales?|sante-bio|médecine/i.test(interestText);
  const interestEco = /économie|gestion|entrepreneuriat|economie-gestion|finance|commerce/i.test(interestText);
  const interestArt = /arts?|design|création\s*numérique|arts-design|visuel/i.test(interestText);
  const interestComm = /lettres?|langues?|communication|lettres-langues|droit/i.test(interestText);

  // 2. Détection complémentaire basée sur les matières fortes et le texte libre
  const hasTech = interestTech || /informatique|code|web|data|intelligence\s*artificielle|\bia\b|cloud|robot|cybersécur/i.test(allTokens) || (/math/i.test(subjectText) && !interestHealth && !interestComm);
  const hasEng = interestEng || /génie\s*civil|bâtiment|btp|chantier|mécanique|énergie|architecture|urbanisme/i.test(allTokens);
  const hasHealth = interestHealth || /médec|pharma|biolog|svt|santé|soin|clinique/i.test(allTokens);
  const hasEco = interestEco || /compta|financ|banque|audit|entrepre|pme|fiscal|commerce|vente/i.test(allTokens);
  const hasArt = interestArt || /design|graphi|ui|ux|illustration|ergonomie|visuel|multimédia/i.test(allTokens);
  const hasComm = interestComm || /droit|jurid|avocat|enseign|formateur|littérat|philo|journal|rh\b|ressources\s*humaines/i.test(allTokens);

  // Attribution de scores aux 16 métiers du catalogue togolais
  const scoredCareers = TOGO_CAREERS_CATALOG.map((career) => {
    let score = 50;

    // 1. Technologie & IT
    if (career.id === 'dev-web-mobile') {
      score += interestTech ? 45 : (hasTech ? 30 : 0);
      if (hasArt) score += 5;
    }
    if (career.id === 'data-analyst-ia') {
      score += interestTech ? 42 : (hasTech ? 28 : 0);
      if (hasEco) score += 8;
    }
    if (career.id === 'cybersecurite-reseaux') {
      score += interestTech ? 40 : (hasTech ? 25 : 0);
      if (hasEng) score += 5;
    }

    // 2. Ingénierie, BTP & Architecture
    if (career.id === 'ingenieur-btp-civil') {
      score += interestEng ? 45 : (hasEng ? 30 : 0);
      if (/math|physique/i.test(subjectText)) score += 5;
    }
    if (career.id === 'architecte-urbaniste') {
      score += (interestEng || interestArt) ? 42 : ((hasEng || hasArt) ? 28 : 0);
    }
    if (career.id === 'ingenieur-agronome') {
      score += (interestHealth || interestEng) ? 40 : ((hasHealth || hasEng || /agri|tové|bio/i.test(allTokens)) ? 26 : 0);
    }

    // 3. Santé & Soins
    if (career.id === 'medecin-sante') {
      score += interestHealth ? 46 : (hasHealth ? 30 : 0);
    }
    if (career.id === 'pharmacien-biologiste') {
      score += interestHealth ? 43 : (hasHealth ? 28 : 0);
    }

    // 4. Finance, Banque & Entrepreneuriat
    if (career.id === 'comptable-auditeur') {
      score += interestEco ? 45 : (hasEco ? 30 : 0);
    }
    if (career.id === 'banquier-analyste') {
      score += interestEco ? 42 : (hasEco ? 28 : 0);
    }
    if (career.id === 'entrepreneur-innovation') {
      score += interestEco ? 42 : (hasEco ? 28 : 0);
      if (interestTech || hasTech) score += 8;
    }

    // 5. Création, Médias & Communication
    if (career.id === 'designer-graphique') {
      score += interestArt ? 45 : ((hasArt || hasTech) ? 30 : 0);
    }
    if (career.id === 'marketing-digital') {
      score += (interestEco || interestComm || interestArt) ? 40 : ((hasEco || hasComm || hasArt) ? 26 : 0);
    }

    // 6. Droit, Administration, Éducation & RH
    if (career.id === 'juriste-affaires') {
      score += interestComm ? 45 : ((hasComm || hasEco || interestEco) ? 28 : 0);
    }
    if (career.id === 'enseignant-formateur') {
      score += interestComm ? 42 : (hasComm ? 26 : 0);
    }
    if (career.id === 'responsable-rh') {
      score += (interestEco || interestComm) ? 38 : ((hasEco || hasComm) ? 24 : 0);
    }

    // Bonus de demande nationale togolaise
    if (career.demand === 'Tres Forte') score += 5;
    else if (career.demand === 'Forte') score += 3;

    return { career, score };
  });

  // Tri décroissant selon affinité
  scoredCareers.sort((a, b) => b.score - a.score);

  // Top 3 Métiers recommandés
  const top3 = scoredCareers.slice(0, 3);
  const matchPercentages = [94, 88, 82];

  const recommendedCareers: RecommendedCareerM3[] = top3.map((item, idx) => {
    const c = item.career;
    const demand: 'Faible' | 'Moyenne' | 'Forte' =
      c.demand === 'Tres Forte' || c.demand === 'Forte'
        ? 'Forte'
        : c.demand === 'En Croissance'
          ? 'Moyenne'
          : 'Faible';

    return {
      title: stripEmojis(c.title),
      matchPercentage: matchPercentages[idx],
      description: stripEmojis(c.description),
      salaryRangeCFA: stripEmojis(c.salary || '250 000 - 850 000 FCFA / mois'),
      demandInTogo: demand,
    };
  });

  // Recommandation des Établissements selon budget et mobilité
  const isKaraOrNorth = /kara|nord|savanes/i.test(mobilityStr) || /kara|dapaong|mango/i.test(cityStr);
  const isHighBudget = /élevé|eleve|>|600/i.test(budgetStr);
  const isMediumBudget = /moyen|200k-600k|200 000/i.test(budgetStr);

  let recommendedSchools: RecommendedSchoolM3[] = [];

  if (isKaraOrNorth) {
    recommendedSchools = [
      {
        name: 'Université de Kara (UK)',
        program: 'Faculté des Sciences et Techniques (FaST) / ISMA',
        estimatedAnnualCostCFA: 'Public / 25 000 - 50 000 FCFA',
        whyThisSchool: 'Établissement public de référence dans le Nord Togo, garantissant des diplômes d’État agréés CAMES à coût accessible.',
      },
      {
        name: 'Université de Lomé (UL)',
        program: 'École Nationale Supérieure d’Ingénieurs (ENSI) & FDS',
        estimatedAnnualCostCFA: 'Public / 25 000 - 50 000 FCFA',
        whyThisSchool: 'Pôle national d’excellence doté de laboratoires de recherche et filières spécialisées complètes.',
      },
    ];
  } else if (isHighBudget) {
    recommendedSchools = [
      {
        name: 'École Supérieure de Gestion, d’Informatique et des Sciences (ESGIS)',
        program: 'Cycle Ingénieur & Doubles Diplômes Internationaux',
        estimatedAnnualCostCFA: '750 000 - 1 200 000 FCFA / an',
        whyThisSchool: 'Infrastructures modernes, certifications reconnues mondialement et partenariats étroits avec les multinationales de la zone UEMOA.',
      },
      {
        name: 'Institut Africain d’Informatique (IAI-Togo)',
        program: 'Cycle Ingénieur de Conception & Systèmes d’Information',
        estimatedAnnualCostCFA: '850 000 FCFA / an',
        whyThisSchool: 'Institution inter-États d’élite assurant une insertion professionnelle immédiate et un puissant réseau d’anciens.',
      },
      {
        name: 'Université de Lomé (UL)',
        program: 'Centres d’Excellence Régionaux & Masters Professionnels',
        estimatedAnnualCostCFA: 'Public / 25 000 - 50 000 FCFA',
        whyThisSchool: 'Option publique prestigieuse combinant renommée académique et recherche de haut niveau.',
      },
    ];
  } else if (isMediumBudget) {
    recommendedSchools = [
      {
        name: 'Institut Africain d’Informatique (IAI-Togo)',
        program: 'Licence Professionnelle en Génie Logiciel & Réseaux',
        estimatedAnnualCostCFA: '500 000 FCFA / an',
        whyThisSchool: 'Parfait équilibre entre excellence pratique, insertion sur le marché togolais et coût compatible avec votre budget.',
      },
      {
        name: 'École Supérieure de Gestion, d’Informatique et des Sciences (ESGIS)',
        program: 'Licence Spécialisée & Projets Tutorés en Entreprise',
        estimatedAnnualCostCFA: '450 000 - 600 000 FCFA / an',
        whyThisSchool: 'Formation pratique professionnalisante accélérant l’employabilité des diplômés dès la 3ème année.',
      },
      {
        name: 'Université de Lomé (UL)',
        program: 'Faculté des Sciences (FDS) / FASEG',
        estimatedAnnualCostCFA: 'Public / 25 000 - 50 000 FCFA',
        whyThisSchool: 'Parcours public d’excellence permettant de préserver vos économies pour vos projets d’insertion.',
      },
    ];
  } else {
    // Budget faible ou par défaut : focus public
    if (interestHealth) {
      recommendedSchools = [
        {
          name: 'Université de Lomé (UL)',
          program: 'Faculté des Sciences de la Santé (FSS) - Médecine & Pharmacie',
          estimatedAnnualCostCFA: 'Public / 25 000 - 50 000 FCFA',
          whyThisSchool: 'Faculté publique d’excellence formant les médecins, pharmaciens et spécialistes de santé au Togo avec droits universitaires publics.',
        },
        {
          name: 'Université de Lomé (UL)',
          program: 'Licence LMD - Sciences, Technologies & Gestion',
          estimatedAnnualCostCFA: 'Public / 25 000 - 50 000 FCFA',
          whyThisSchool: 'Première université publique du Togo, offrant un enseignement de haut rang accessible à tous les budgets avec bourses possibles.',
        },
      ];
    } else {
      recommendedSchools = [
        {
          name: 'Université de Lomé (UL)',
          program: 'Licence LMD - Sciences, Technologies & Gestion',
          estimatedAnnualCostCFA: 'Public / 25 000 - 50 000 FCFA',
          whyThisSchool: 'Première université publique du Togo, offrant un enseignement de haut rang accessible à tous les budgets avec bourses possibles.',
        },
        {
          name: 'Institut Africain d’Informatique (IAI-Togo)',
          program: 'Licence Professionnelle (Filière Conventionnée)',
          estimatedAnnualCostCFA: 'Public-Partenariat / Bourses d’État disponibles',
          whyThisSchool: 'Opportunités d’aides financières et d’exonérations partielles pour les étudiants rigoureux et motivés.',
        },
      ];
    }
  }

  // Profil psychologique personnalisé
  const topCareerTitle = recommendedCareers[0].title;
  const isDominantTech = /développeur|data|cyber|ingénieur/i.test(topCareerTitle);
  const isDominantEco = /comptable|financier|affaires|logistique/i.test(topCareerTitle);
  const isDominantHealth = /médecin|pharmacien|agronome/i.test(topCareerTitle);

  let dominantTraits = ['Analytique', 'Méthodique', 'Innovateur', 'Pragmatique'];
  if (isDominantEco) dominantTraits = ['Stratège', 'Entreprenant', 'Organisé', 'Négociateur'];
  else if (isDominantHealth) dominantTraits = ['Investigateur', 'Empathique', 'Rigoureux', 'Dévoué'];

  const strengths = [
    'Raisonnement logique et forte capacité de structuration des informations',
    'Aptitude naturelle à résoudre des défis concrets avec méthode et efficacité',
    'Persévérance dans l’apprentissage et faculté d’adaptation aux nouvelles exigences'
  ];

  const weaknesses = [
    'Tendance à approfondir l’analyse théorique avant de basculer dans l’expérimentation pratique',
    'Veiller à partager régulièrement vos idées pour favoriser une collaboration d’équipe fluide',
    'Bien hiérarchiser vos priorités afin de canaliser votre grande curiosité intellectuelle'
  ];

  const summary = `Votre profil révèle une affinité marquée pour la rigueur intellectuelle et l’action structurée, des qualités hautement valorisées sur le marché togolais. Vos matières fortes constituent un tremplin solide vers les carrières à fort potentiel identifiées. En rejoignant l’un des établissements recommandés, vous développerez des compétences pratiques directement recherchées par les entreprises togolaises et régionales.`;

  const result: OrientationResultM3 = {
    psychologicalProfile: {
      dominantTraits: dominantTraits.map((t) => stripEmojis(t)),
      strengths: strengths.map((s) => stripEmojis(s)),
      weaknesses: weaknesses.map((w) => stripEmojis(w)),
      summary: stripEmojis(summary),
    },
    recommendedCareers,
    recommendedSchools,
    executionMode: 'fallback_deterministic',
  };

  return sanitizeObject(result);
}

