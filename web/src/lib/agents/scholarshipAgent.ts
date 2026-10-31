import { db } from "@/db";
import { opportunities } from "@/db/schema";
import { eq } from "drizzle-orm";

export interface ScholarshipEntry {
  type: string;
  title: string;
  provider: string;
  location: string;
  amountOrSalary: string;
  deadline: Date;
  eventDate?: Date | null;
  link: string;
  image: string;
  isRecommended: boolean;
  isPublished: boolean;
  description: string;
  criteria: string[];
  documents: string[];
}

export const OFFICIAL_SCHOLARSHIPS: ScholarshipEntry[] = [
  {
    type: 'bourse',
    title: 'Bourse France Excellence Eiffel - Master & Doctorat',
    provider: "Campus France & Ministère de l'Europe et des Affaires Étrangères",
    location: 'France (Universités & Grandes Écoles)',
    amountOrSalary: '1 181 €/mois (Master) ou 1 800 €/mois (Doctorat) + Billets A/R + Sécurité Sociale',
    deadline: new Date('2027-01-06T23:59:59.000Z'),
    eventDate: null,
    link: 'https://www.campusfrance.org/fr/le-programme-de-bourses-france-excellence-eiffel',
    image: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&w=1200&q=80',
    isRecommended: true,
    isPublished: true,
    description: "Le programme de bourses France Excellence Eiffel est développé par le Ministère de l'Europe et des Affaires étrangères pour permettre aux établissements français d’enseignement supérieur d’attirer les meilleurs étudiants étrangers dans des formations diplômantes de niveau Master et en Doctorat. Les domaines d'études prioritaires couvrent les Sciences et techniques (Biologie et santé, Transition écologique, Mathématiques et numérique, Sciences de l’ingénieur) ainsi que les Sciences humaines et sociales (Économie-Gestion, Droit et Science politique, Histoire et civilisation).",
    criteria: [
      "Nationalité étrangère exclusive (les binationaux ayant la nationalité française ne sont pas éligibles)",
      "Âge maximal : 29 ans révolus au moment de la sélection pour le niveau Master",
      "Âge maximal : 35 ans révolus au moment de la sélection pour le niveau Doctorat",
      "Excellence académique démontrée dans le parcours universitaire antérieur",
      "Candidature présentée et soutenue obligatoirement par un établissement d'enseignement supérieur français (pas de candidature directe individuelle)",
      "Non-cumul avec une autre bourse du gouvernement français"
    ],
    documents: [
      "Curriculum Vitae récent rédigé en français ou en anglais (1 à 2 pages)",
      "Projet professionnel rédigé expliquant le choix des études en France",
      "Relevés de notes de l'ensemble du parcours universitaire et diplômes obtenus",
      "Classement académique ou attestation d'excellence délivrée par l'université d'origine",
      "Attestation de niveau de langue (DELF/DALF ou TCF pour formations en français, TOEFL/IELTS pour formations en anglais)",
      "Projet de thèse et convention de cotutelle/codirection (pour les candidats au Doctorat)"
    ]
  },
  {
    type: 'bourse',
    title: 'Bourse Chevening du Gouvernement Britannique (UK Government)',
    provider: 'Foreign, Commonwealth & Development Office (FCDO)',
    location: 'Royaume-Uni (Toutes universités britanniques)',
    amountOrSalary: 'Prise en charge intégrale (100% frais de scolarité + allocation mensuelle + billets d\'avion + visa)',
    deadline: new Date('2026-11-05T12:00:00.000Z'),
    eventDate: null,
    link: 'https://www.chevening.org',
    image: 'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?auto=format&fit=crop&w=1200&q=80',
    isRecommended: true,
    isPublished: true,
    description: "Le programme de bourses Chevening est le programme mondial de bourses d'études du gouvernement britannique, financé par le Foreign, Commonwealth & Development Office (FCDO) et des organisations partenaires. Il offre un financement intégral pour poursuivre un Master d'un an dans n'importe quelle université du Royaume-Uni pour les futurs leaders, décideurs et innovateurs engagés pour le développement durable de leur pays d'origine.",
    criteria: [
      "Être citoyen d'un pays ou territoire éligible à Chevening (inclut Bénin, Côte d'Ivoire, Sénégal, Togo, Ghana, Nigéria...)",
      "S'engager formellement à retourner dans son pays d'origine pendant au moins deux ans après la fin de la bourse",
      "Avoir validé un diplôme de premier cycle universitaire (équivalent 2:1 honours degree britannique / Licence avec mention)",
      "Avoir accumulé au moins deux ans d'expérience professionnelle (soit un minimum de 2 800 heures)",
      "Postuler à trois programmes universitaires britanniques éligibles différents et obtenir au moins une offre inconditionnelle"
    ],
    documents: [
      "Diplômes universitaires et relevés de notes officiels traduits en anglais",
      "Deux lettres de recommandation académiques ou professionnelles rédigées en anglais",
      "Quatre essais de candidature Chevening (Leadership & Influence, Réseautage, Études au Royaume-Uni, Plan de carrière)",
      "Passeport en cours de validité",
      "Offre d'admission universitaire inconditionnelle au Royaume-Uni"
    ]
  },
  {
    type: 'bourse',
    title: 'Mastercard Foundation Scholars Program - Premier & Deuxième Cycle',
    provider: 'Mastercard Foundation',
    location: 'Afrique & Universités Partenaires Mondiales (Sciences Po, McGill, Edinburgh, UCT...)',
    amountOrSalary: 'Prise en charge à 100% (Frais universitaires, hébergement, livres, ordinateur portable, allocation et mentorat)',
    deadline: new Date('2027-01-15T23:59:59.000Z'),
    eventDate: null,
    link: 'https://mastercardfdn.org',
    image: 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?auto=format&fit=crop&w=1200&q=80',
    isRecommended: true,
    isPublished: true,
    description: "Le Mastercard Foundation Scholars Program permet à des jeunes africains talentueux et engagés, issus de milieux économiquement vulnérables, d'accéder à une éducation universitaire d'excellence mondiale. Le programme vise à former des leaders transformationnels qui réinvestiront leurs compétences au service du développement économique et social du continent africain.",
    criteria: [
      "Être citoyen ou résident d'un pays d'Afrique subsaharienne (ou statut de réfugié / personne déplacée interne)",
      "Démontrer des barrières socio-économiques ou financières avérées entravant l'accès aux études supérieures",
      "Excellence académique remarquable et fort potentiel intellectuel",
      "Preuve d'engagement communautaire actif et potentiel de leadership éthique",
      "Pour les programmes Master : être titulaire d'une Licence et ne pas avoir déjà complété de Master"
    ],
    documents: [
      "Relevés de notes officiels et attestations des diplômes obtenus",
      "Preuves et attestations de situation socio-économique (revenus familiaux, certificats d'indigence ou avis officiels)",
      "Essais de motivation et déclarations de leadership personnel",
      "Lettres de recommandation académiques et attestations d'engagement associatif/communautaire",
      "Copie de la pièce d'identité ou du passeport"
    ]
  },
  {
    type: 'bourse',
    title: 'Bourses Erasmus Mundus Joint Masters (EMJM) - Union Européenne',
    provider: 'Commission Européenne (EACEA)',
    location: 'Union Européenne (Consortium de 3+ universités européennes)',
    amountOrSalary: '1 400 €/mois (jusqu\'à 33 600 € sur 2 ans) + 100% frais de scolarité + assurance santé internationale',
    deadline: new Date('2027-01-31T23:59:59.000Z'),
    eventDate: null,
    link: 'https://www.eacea.ec.europa.eu/scholarships/erasmus-mundus-catalogue_en',
    image: 'https://images.unsplash.com/photo-1467269204594-9661b134dd2b?auto=format&fit=crop&w=1200&q=80',
    isRecommended: true,
    isPublished: true,
    description: "Les masters conjoints Erasmus Mundus (EMJM) sont des programmes d'études intégrés de très haut niveau, dispensés par un consortium international d'établissements d'enseignement supérieur européens. Les étudiants étudient dans au moins deux pays européens différents et reçoivent un diplôme conjoint ou multiple. Les bourses financées par l'UE couvrent l'intégralité des frais d'inscription, les déplacements internationaux et une bourse de subsistance mensuelle.",
    criteria: [
      "Être titulaire d'un diplôme d'études supérieures de premier cycle (Licence / Bachelor ou équivalent validé)",
      "Posséder d'excellents résultats académiques dans le domaine du Master ciblé",
      "Respecter la règle de candidature : postuler à un maximum de 3 programmes Erasmus Mundus par session",
      "Très bon niveau d'anglais certifié (ou autre langue d'enseignement selon le consortium)",
      "Ouvert sans restriction de nationalité (quotas réservés aux pays partenaires africains)"
    ],
    documents: [
      "Curriculum Vitae au format Europass",
      "Diplômes et relevés de notes traduits et certifiés conformes",
      "Lettre de motivation argumentée pour le consortium choisi",
      "Deux lettres de recommandation académiques récentes",
      "Certificat de compétence linguistique en anglais (TOEFL, IELTS ou équivalent C1/B2)",
      "Copie du passeport valide"
    ]
  },
  {
    type: 'bourse',
    title: 'Bourse DAAD Helmut-Schmidt - Politiques Publiques & Bonne Gouvernance',
    provider: 'Deutscher Akademischer Austauschdienst (DAAD)',
    location: 'Allemagne (Universités partenaires allemandes)',
    amountOrSalary: '934 €/mois + Assurance santé + Billet d\'avion + Cours d\'allemand préparatoire de 6 mois',
    deadline: new Date('2027-07-31T23:59:59.000Z'),
    eventDate: null,
    link: 'https://www2.daad.de/deutschland/stipendien/stipendienkompass/en/32205-helmut-schmidt-programme-master-s-scholarships-for-public-policy-and-good-governance/',
    image: 'https://images.unsplash.com/photo-1467269204594-9661b134dd2b?auto=format&fit=crop&w=1200&q=80',
    isRecommended: false,
    isPublished: true,
    description: "Le programme Helmut-Schmidt du DAAD (Public Policy and Good Governance) offre aux diplômés hautement qualifiés de pays émergents et en développement l'opportunité d'obtenir un Master orienté vers la gouvernance, les politiques publiques, l'administration, le droit ou l'économie dans des universités de renom en Allemagne. Le programme comprend également des cours d'allemand intensifs et un réseau d'anciens boursiers influent.",
    criteria: [
      "Être citoyen d'un pays éligible de la liste CAD/DAC de l'OCDE (inclut les pays d'Afrique de l'Ouest)",
      "Être titulaire d'un diplôme universitaire obtenu avec d'excellents résultats (mention requise)",
      "Dernier diplôme universitaire obtenu il y a moins de 6 ans au moment de la candidature",
      "Candidater à un maximum de deux cours de master parmi la liste officielle du programme Helmut-Schmidt",
      "Maîtrise de l'anglais (cours dispensés en anglais) et volonté d'apprendre l'allemand"
    ],
    documents: [
      "Formulaire officiel de candidature DAAD complété",
      "CV détaillé au format Europass (avec date et signature manuscrite)",
      "Lettre de motivation unique justifiant le choix des cours de Master ciblés",
      "Copies certifiées conformes des diplômes et relevés de notes",
      "Certificat de langue anglaise (IELTS ou TOEFL iBT)",
      "Lettre de recommandation récente d'un professeur universitaire ou d'un employeur"
    ]
  },
  {
    type: 'bourse',
    title: 'Programme de Bourses de l\'IsDB (Banque Islamique de Développement)',
    provider: 'Islamic Development Bank (IsDB)',
    location: 'Universités des Pays Membres IsDB & Partenaires Internationaux',
    amountOrSalary: 'Prise en charge intégrale (Frais de scolarité + allocation mensuelle + assurance + billets d\'avion + allocation livres)',
    deadline: new Date('2027-01-31T23:59:59.000Z'),
    eventDate: null,
    link: 'https://isdbscholarships.smartsimple.com',
    image: 'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?auto=format&fit=crop&w=1200&q=80',
    isRecommended: true,
    isPublished: true,
    description: "La Banque Islamique de Développement (IsDB) finance des bourses d'études complètes pour les étudiants et chercheurs des pays membres (notamment Côte d'Ivoire, Sénégal, Bénin, Guinée, Mali, Niger, Burkina Faso, Togo). Le programme couvre les études de premier cycle (Licence/Bachelor), Master, Doctorat et Recherche Post-doctorale dans les domaines scientifiques et technologiques favorisant le développement durable.",
    criteria: [
      "Être ressortissant de l'un des pays membres de l'IsDB ou d'une communauté musulmane dans un pays non-membre",
      "Dossier académique solide avec mention Très Bien ou Bien dans les matières scientifiques",
      "Aptitude médicale certifiée (certificat de santé exigé)",
      "Engagement à participer activement au développement de sa communauté et de son pays après l'obtention du diplôme",
      "Ne pas bénéficier d'une autre bourse au moment de l'octroi"
    ],
    documents: [
      "Copie du certificat de nationalité ou du passeport",
      "Diplômes académiques et relevés de notes complets traduits",
      "Certificat médical d'aptitude délivré par un établissement public hospitalier",
      "Proposition de recherche détaillée (pour les candidats au Master recherche et Doctorat)",
      "Deux lettres de recommandation professionnelles ou académiques"
    ]
  },
  {
    type: 'bourse',
    title: 'Bourses de l\'Université Panafricaine (Commission de l\'Union Africaine)',
    provider: 'Union Africaine & Pan African University',
    location: 'Pôles d\'Excellence en Afrique (Kenya, Nigeria, Cameroun, Algérie)',
    amountOrSalary: '100% frais de scolarité + Allocation mensuelle + Logement sur campus + Assurance médicale',
    deadline: new Date('2027-02-28T23:59:59.000Z'),
    eventDate: null,
    link: 'https://pau-au.africa',
    image: 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?auto=format&fit=crop&w=1200&q=80',
    isRecommended: true,
    isPublished: true,
    description: "L'Université Panafricaine (PAU) est l'institution continentale phare de l'Union Africaine dédiée à l'enseignement supérieur et à la recherche de haut niveau. Elle regroupe quatre instituts majeurs : PAUSTI au Kenya (Sciences de base et technologie), PAULESI au Nigeria (Sciences de la vie et de la terre), PAUGHSS au Cameroun (Gouvernance et sciences humaines) et PAUWES en Algérie (Eau et énergie renouvelable). L'Union Africaine octroie des bourses complètes à tous les lauréats retenus.",
    criteria: [
      "Être citoyen d'un État membre de l'Union Africaine ou de la diaspora africaine",
      "Pour le Master : être titulaire d'une Licence avec mention Assez Bien / Bien minimum, être âgé de moins de 30 ans (hommes) ou 35 ans (femmes)",
      "Pour le Doctorat : être titulaire d'un Master pertinent, être âgé de moins de 35 ans (hommes) ou 40 ans (femmes)",
      "Engagement à servir un État membre de l'Union Africaine pendant une durée équivalente à la bourse après l'obtention du diplôme"
    ],
    documents: [
      "Copies certifiées conformes des diplômes et relevés de notes",
      "Page d'identité du passeport en cours de validité",
      "Curriculum Vitae actualisé",
      "Projet de recherche synthétique de 3 à 4 pages (pour les candidats au doctorat)",
      "Deux lettres de recommandation académiques signées"
    ]
  },
  {
    type: 'bourse',
    title: 'Bourses d\'Excellence Türkiye Bursları - Licence, Master & Doctorat',
    provider: 'Gouvernement de la République de Turquie (YTB)',
    location: 'Turquie (Universités partenaires d\'État et privées)',
    amountOrSalary: 'Prise en charge intégrale (Frais universitaires, hébergement en résidence, allocation mensuelle, vols A/R, assurance et cours de turc)',
    deadline: new Date('2027-02-20T23:59:59.000Z'),
    eventDate: null,
    link: 'https://www.turkiyeburslari.gov.tr',
    image: 'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=1200&q=80',
    isRecommended: false,
    isPublished: true,
    description: "Türkiye Bursları est un programme de bourses gouvernementales complètes financé par la République de Turquie pour les étudiants internationaux d'excellence. En plus de l'accès direct aux cursus universitaires sans passer par les concours locaux, les boursiers bénéficient d'une année préparatoire d'apprentissage de la langue turque, d'un logement en résidence universitaire et d'une prise en charge médicale et de voyage complète.",
    criteria: [
      "Ne pas détenir la nationalité turque",
      "Critère d'âge : moins de 21 ans pour la Licence, moins de 30 ans pour le Master, moins de 35 ans pour le Doctorat",
      "Critère de moyenne académique minimale : 70% pour la Licence, 75% pour Master et Doctorat, 90% pour Médecine et Pharmacie",
      "Candidature ouverte à toutes les disciplines académiques"
    ],
    documents: [
      "Diplôme ou attestation provisoire de réussite et relevés de notes",
      "Pièce d'identité ou passeport valide",
      "Photo d'identité récente au format numérique",
      "Lettre de motivation rédigée via la plateforme officielle",
      "Certificats extrascolaires, attestations de bénévolat ou de stage"
    ]
  },
  {
    type: 'bourse',
    title: 'Programme de Bourses Fulbright Foreign Student (États-Unis)',
    provider: 'Département d\'État des États-Unis & Commissions Binationales',
    location: 'États-Unis (Universités américaines)',
    amountOrSalary: 'Financement complet (Frais de scolarité, allocation de vie mensuelle, assurance santé ASPE, billets d\'avion)',
    deadline: new Date('2027-05-31T23:59:59.000Z'),
    eventDate: null,
    link: 'https://foreign.fulbrightonline.org',
    image: 'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?auto=format&fit=crop&w=1200&q=80',
    isRecommended: true,
    isPublished: true,
    description: "Le programme Fulbright Foreign Student permet aux étudiants diplômés, jeunes professionnels et artistes étrangers d'étudier et de mener des recherches aux États-Unis. Opérant dans plus de 160 pays à travers le monde, il finance des cursus complets de Master et de Doctorat. Les boursiers reviennent ensuite enrichir le tissu socio-économique de leur pays d'origine sous les dispositions du visa d'échange J-1.",
    criteria: [
      "Être citoyen et résident du pays de candidature (pays d'Afrique éligible avec mission diplomatique US)",
      "Être titulaire d'un diplôme de premier cycle universitaire équivalent au Bachelor américain (Bac+4 / Licence + Master 1)",
      "Excellente maîtrise de l'anglais certifiée (TOEFL ou IELTS) ou admissibilité au programme préparatoire Long-Term English (LTE)",
      "Engagement ferme à rentrer dans son pays d'origine pour au moins deux ans au terme des études (règle du visa J-1)"
    ],
    documents: [
      "Formulaire de candidature en ligne officiel Fulbright (IIE)",
      "Relevés de notes universitaires officiels traduits en anglais",
      "Trois lettres de recommandation professionnelles ou académiques",
      "Essai de projet d'études (Study/Research Objective) et déclaration personnelle (Personal Statement)",
      "Score officiel aux tests de langue TOEFL ou GRE (si requis par la filière)"
    ]
  },
  {
    type: 'bourse',
    title: 'Bourses de Coopération du Royaume du Maroc (AMCI)',
    provider: 'Agence Marocaine de Coopération Internationale (AMCI)',
    location: 'Maroc (Universités, facultés et grandes écoles publiques marocaines)',
    amountOrSalary: 'Exonération des frais universitaires + Allocation de subsistance + Accès aux cités universitaires + Couverture AMO',
    deadline: new Date('2027-07-15T23:59:59.000Z'),
    eventDate: null,
    link: 'https://www.amci.ma',
    image: 'https://images.unsplash.com/photo-1539020140153-e479b8c22e70?auto=format&fit=crop&w=1200&q=80',
    isRecommended: false,
    isPublished: true,
    description: "L'Agence Marocaine de Coopération Internationale (AMCI) attribue chaque année plusieurs milliers de bourses aux étudiants africains dans le cadre des accords bilatéraux entre le Maroc et les pays frères d'Afrique subsaharienne. Les formations couvrent les facultés universitaires, les facultés de médecine, les classes préparatoires, les écoles d'ingénieurs (EMI, ENSIAS, etc.) et les écoles de management.",
    criteria: [
      "Être ressortissant d'un pays africain partenaire lié au Maroc par accord bilatéral de coopération",
      "Pour la Licence : être titulaire du Baccalauréat avec mention Bien ou Assez Bien selon les quotas nationaux",
      "Pour les cycles Master / Doctorat : être titulaire d'une Licence ou Master avec de très bons résultats académiques",
      "Dossier obligatoirement transmis par le Ministère de l'Enseignement supérieur ou la Direction des bourses du pays d'origine (aucun dossier individuel direct)"
    ],
    documents: [
      "Attestation de réussite au Baccalauréat et relevé de notes certifiés conformes",
      "Copie d'extrait d'acte de naissance et certificat de nationalité",
      "Copie du passeport en cours de validité",
      "Certificat médical d'aptitude physique et carnet de vaccinations",
      "Deux photos d'identité récentes"
    ]
  },
  {
    type: 'bourse',
    title: 'Bourse MEXT du Gouvernement du Japon (Embassy Recommendation)',
    provider: 'Ministère de l\'Éducation du Japon (MEXT)',
    location: 'Japon (Universités nationales et publiques japonaises)',
    amountOrSalary: '143 000 à 145 000 JPY/mois + 100% frais d\'examen et de scolarité + Billets d\'avion A/R + Cours intensif de japonais',
    deadline: new Date('2027-05-31T23:59:59.000Z'),
    eventDate: null,
    link: 'https://www.studyinjapan.go.jp',
    image: 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=1200&q=80',
    isRecommended: false,
    isPublished: true,
    description: "Le Ministère japonais de l'Éducation (MEXT) offre des bourses d'études prestigieuses pour les étudiants internationaux désireux d'étudier dans des universités japonaises en tant qu'étudiants chercheurs (Research Students pour Master ou Doctorat) ou étudiants de premier cycle. Le processus de sélection comprend un examen écrit et un entretien mené par l'Ambassade du Japon dans le pays d'origine.",
    criteria: [
      "Nationalité d'un pays ayant des relations diplomatiques avec le Japon",
      "Moins de 35 ans pour les étudiants chercheurs (Master / Doctorat)",
      "Moins de 25 ans pour les candidats en premier cycle (Undergraduate)",
      "Volonté d'apprendre la langue japonaise et de s'adapter à la vie au Japon",
      "Excellents résultats aux épreuves écrites (anglais/japonais et matières scientifiques ou humaines)"
    ],
    documents: [
      "Formulaire officiel de candidature MEXT",
      "Formulaire de préférence de placement dans les universités japonaises",
      "Relevés de notes de l'ensemble des années universitaires",
      "Projet de recherche détaillé (Field of Study and Research Plan)",
      "Lettre de recommandation du doyen ou directeur de thèse",
      "Certificat de santé délivré selon le modèle officiel MEXT"
    ]
  },
  {
    type: 'bourse',
    title: 'Bourses ICP Connect de la Coopération Belge (VLIR-UOS)',
    provider: 'VLIR-UOS (Coopération Universitaire Flamande pour le Développement)',
    location: 'Belgique (Universités flamandes : KU Leuven, Gand, Anvers, VUB, Hasselt)',
    amountOrSalary: '1 400 €/mois + Frais de scolarité complets + Assurance maladie + Logement + Billets d\'avion',
    deadline: new Date('2027-02-28T23:59:59.000Z'),
    eventDate: null,
    link: 'https://www.vliruos.be/en/icpconnect-scholarships',
    image: 'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=1200&q=80',
    isRecommended: false,
    isPublished: true,
    description: "Le programme ICP Connect financé par le gouvernement belge attribue des bourses complètes pour des programmes de Master enseignés en anglais en Flandre (Belgique). Les formations portent sur des thématiques clés de développement durable : sécurité alimentaire, gestion de l'eau, santé publique, écologie, statistiques appliquées et technologies durables.",
    criteria: [
      "Être citoyen et résident de l'un des 29 pays partenaires éligibles (dont Bénin, Burkina Faso, RD Congo, Sénégal, etc.)",
      "Âge maximal : 35 ans au 1er janvier de l'année d'admission pour un premier Master",
      "Ne pas avoir résidé ou étudié précédemment dans un établissement supérieur belge",
      "Postuler à un seul programme ICP Connect par an (les candidatures multiples entraînent la disqualification)",
      "Excellent niveau académique et motivation orientée vers le développement durable"
    ],
    documents: [
      "Dossier d'admission universitaire soumis auprès de l'université flamande partenaire",
      "Diplômes universitaires et relevés de notes légalisés",
      "Preuve de maîtrise de la langue anglaise (TOEFL ou IELTS)",
      "Lettre de motivation expliquant l'impact attendu dans le pays d'origine",
      "Deux lettres de recommandation professionnelles ou académiques"
    ]
  },
  {
    type: 'bourse',
    title: 'Bourse d\'Excellence de la Commission de l\'UEMOA',
    provider: 'Commission de l\'Union Économique et Monétaire Ouest-Africaine (UEMOA)',
    location: 'Espace UEMOA (Centres d\'Excellence Régionaux)',
    amountOrSalary: 'Prise en charge intégrale (Frais de formation + allocation mensuelle de subsistance + transport)',
    deadline: new Date('2027-08-31T23:59:59.000Z'),
    eventDate: null,
    link: 'http://www.uemoa.int',
    image: 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?auto=format&fit=crop&w=1200&q=80',
    isRecommended: true,
    isPublished: true,
    description: "La Commission de l'UEMOA met en œuvre son programme de bourses d'excellence pour soutenir la mobilité et la formation des meilleurs étudiants et chercheurs ressortissants des 8 États membres (Bénin, Burkina Faso, Côte d'Ivoire, Guinée-Bissau, Mali, Niger, Sénégal, Togo) dans les institutions régionales d'enseignement supérieur et centres d'excellence agréés.",
    criteria: [
      "Être ressortissant de l'un des 8 pays membres de l'espace UEMOA",
      "Être âgé de moins de 28 ans pour le niveau Master ou moins de 35 ans pour le Doctorat",
      "Être titulaire d'une Licence ou d'un Master avec au moins la mention Bien",
      "Être pré-admis dans un centre d'excellence régional accrédité au sein de l'UEMOA"
    ],
    documents: [
      "Certificat de nationalité de l'un des États membres de l'UEMOA",
      "Copie légalisée de l'attestation de diplôme et des relevés de notes",
      "Attestation de pré-inscription dans un centre d'excellence régional",
      "Lettre de motivation et curriculum vitae détaillé",
      "Certificat médical d'aptitude"
    ]
  }
];

export async function runScholarshipAgent(onProgress?: (message: string) => void) {
  const log = (msg: string) => {
    if (onProgress) onProgress(msg);
  };

  log(`[AGENT IA] Lancement du moissonnage de ${OFFICIAL_SCHOLARSHIPS.length} bourses officielles...`);

  // Récupérer les opportunités de type bourse existantes
  const existing = await db.select().from(opportunities).where(eq(opportunities.type, 'bourse'));

  let inserted = 0;
  let updated = 0;
  const errors: string[] = [];

  for (const item of OFFICIAL_SCHOLARSHIPS) {
    try {
      const match = existing.find(e => {
        if (e.link && item.link && e.link.toLowerCase().trim() === item.link.toLowerCase().trim()) return true;
        if (e.title && item.title) {
          const t1 = e.title.toLowerCase().replace(/[^a-z0-9]/g, '');
          const t2 = item.title.toLowerCase().replace(/[^a-z0-9]/g, '');
          return t1.includes(t2) || t2.includes(t1);
        }
        return false;
      });

      if (match) {
        await db.update(opportunities)
          .set({
            title: item.title,
            provider: item.provider,
            description: item.description,
            location: item.location,
            amountOrSalary: item.amountOrSalary,
            deadline: item.deadline,
            eventDate: item.eventDate || null,
            criteria: item.criteria,
            documents: item.documents,
            link: item.link,
            image: item.image,
            isRecommended: item.isRecommended,
            isPublished: item.isPublished
          })
          .where(eq(opportunities.id, match.id));
        updated++;
        log(`[AGENT IA] Mise à jour : ${item.title}`);
      } else {
        await db.insert(opportunities).values({
          type: item.type,
          title: item.title,
          provider: item.provider,
          description: item.description,
          location: item.location,
          amountOrSalary: item.amountOrSalary,
          deadline: item.deadline,
          eventDate: item.eventDate || null,
          criteria: item.criteria,
          documents: item.documents,
          link: item.link,
          image: item.image,
          isRecommended: item.isRecommended,
          isPublished: item.isPublished
        });
        inserted++;
        log(`[AGENT IA] Insertion : ${item.title}`);
      }
    } catch (err: any) {
      const msg = `Erreur sur "${item.title}": ${err?.message || err}`;
      errors.push(msg);
      log(`[AGENT IA ERROR] ${msg}`);
    }
  }

  return {
    totalScanned: OFFICIAL_SCHOLARSHIPS.length,
    inserted,
    updated,
    errors
  };
}
