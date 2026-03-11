import '../models/career_model.dart';
import '../../domain/entities/career.dart';

/// Base de données des métiers au Togo avec informations détaillées
/// Cette classe fournit des données statiques pour les métiers recommandés.
class CareersDatabase {
  CareersDatabase._();

  static const List<CareerModel> allCareers = [
    // ============================================
    // SECTEUR: TECHNOLOGIE & INFORMATIQUE
    // ============================================
    CareerModel(
      id: 'dev_logiciel',
      name: 'Développeur Logiciel',
      description: 
          'Le développeur logiciel conçoit, programme et maintient des applications '
          'informatiques. Au Togo, ce métier est en plein essor avec la digitalisation '
          'croissante des entreprises et l\'émergence des startups tech.',
      sector: 'Technologie & Informatique',
      requiredSkills: [
        'Programmation (Python, Java, JavaScript)',
        'Résolution de problèmes',
        'Travail en équipe',
        'Apprentissage continu',
        'Anglais technique',
      ],
      relatedTraits: ['Investigateur', 'Conventionnel', 'Logico-Mathématique'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+3',
        recommendedFormations: [
          'Licence en Informatique',
          'Licence en Génie Logiciel',
          'DUT Informatique',
          'Formation Bootcamp (6 mois intensif)',
        ],
        schoolsInTogo: [
          'Université de Lomé - Faculté des Sciences',
          'ESIBA (École Supérieure d\'Informatique)',
          'IAI-TOGO',
          'ESGIS',
        ],
        durationYears: 3,
        certifications: 'AWS, Google Cloud, Microsoft Azure',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 150000,
        maxMonthlyFCFA: 800000,
        averageMonthlyFCFA: 350000,
        experienceNote: 'Les seniors (5+ ans) peuvent atteindre 1M+ FCFA, '
            'surtout en freelance pour des clients internationaux.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.growing,
        description: 'Secteur en forte croissance avec la transformation digitale. '
            'Opportunités locales et internationales (télétravail).',
        topEmployers: [
          'TOGOCOM',
          'Moov Africa',
          'Gozem',
          'Semoa',
          'Startups locales',
        ],
        entrepreneurshipPotential: true,
      ),
    ),

    CareerModel(
      id: 'data_analyst',
      name: 'Analyste de Données',
      description: 
          'L\'analyste de données collecte, traite et interprète des données '
          'pour aider les entreprises à prendre des décisions éclairées. '
          'Métier émergent au Togo avec un fort potentiel.',
      sector: 'Technologie & Informatique',
      requiredSkills: [
        'Statistiques et mathématiques',
        'Excel avancé, SQL',
        'Python ou R',
        'Visualisation (Power BI, Tableau)',
        'Esprit analytique',
      ],
      relatedTraits: ['Investigateur', 'Conventionnel', 'Logico-Mathématique'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+3',
        recommendedFormations: [
          'Licence en Statistiques',
          'Licence en Mathématiques Appliquées',
          'Master en Data Science',
          'Certifications en ligne (Coursera, DataCamp)',
        ],
        schoolsInTogo: [
          'ENSEA (École Nationale de Statistique)',
          'Université de Lomé - Maths/Stats',
          'Formations en ligne certifiantes',
        ],
        durationYears: 3,
        certifications: 'Google Data Analytics, IBM Data Science',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 200000,
        maxMonthlyFCFA: 700000,
        averageMonthlyFCFA: 400000,
        experienceNote: 'Forte demande internationale, possibilité de télétravail '
            'avec salaires alignés sur les marchés européens.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.growing,
        description: 'La data devient centrale pour toutes les organisations. '
            'Métier d\'avenir avec peu de concurrence locale.',
        topEmployers: [
          'Banques (Ecobank, ORABANK)',
          'Télécoms',
          'ONG internationales',
          'Consulting',
        ],
        entrepreneurshipPotential: true,
      ),
    ),

    // ============================================
    // SECTEUR: SANTÉ
    // ============================================
    CareerModel(
      id: 'medecin',
      name: 'Médecin Généraliste',
      description: 
          'Le médecin généraliste diagnostique et traite les maladies courantes, '
          'oriente vers les spécialistes et assure le suivi médical des patients. '
          'Profession très respectée au Togo avec un rôle social important.',
      sector: 'Santé',
      requiredSkills: [
        'Connaissances médicales approfondies',
        'Empathie et écoute',
        'Résistance au stress',
        'Communication',
        'Éthique professionnelle',
      ],
      relatedTraits: ['Social', 'Investigateur', 'Interpersonnelle'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+7',
        recommendedFormations: [
          'Doctorat en Médecine',
          'Spécialisation optionnelle (+3-5 ans)',
        ],
        schoolsInTogo: [
          'Faculté des Sciences de la Santé - Université de Lomé',
          'Possibilité d\'études au Maroc, Sénégal (bourses)',
        ],
        durationYears: 7,
        certifications: 'Inscription à l\'Ordre des Médecins du Togo',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 300000,
        maxMonthlyFCFA: 1500000,
        averageMonthlyFCFA: 600000,
        experienceNote: 'Revenus variables selon le secteur (public/privé) '
            'et la spécialisation. Les cliniques privées paient mieux.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.stable,
        description: 'Besoin permanent de médecins, surtout en zones rurales. '
            'Ratio médecin/population encore faible au Togo.',
        topEmployers: [
          'CHU Sylvanus Olympio',
          'CHR Lomé Commune',
          'Cliniques privées',
          'ONG médicales (MSF, etc.)',
        ],
        entrepreneurshipPotential: true,
      ),
    ),

    CareerModel(
      id: 'infirmier',
      name: 'Infirmier(e)',
      description: 
          'L\'infirmier assure les soins aux patients, administre les traitements, '
          'et accompagne les malades au quotidien. Pilier essentiel du système de santé togolais.',
      sector: 'Santé',
      requiredSkills: [
        'Soins infirmiers',
        'Empathie',
        'Rigueur',
        'Travail en équipe',
        'Gestion du stress',
      ],
      relatedTraits: ['Social', 'Conventionnel', 'Interpersonnelle'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+3',
        recommendedFormations: [
          'Diplôme d\'État d\'Infirmier',
          'Licence en Sciences Infirmières',
        ],
        schoolsInTogo: [
          'École Nationale des Auxiliaires Médicaux (ENAM)',
          'ESTBA - Université de Lomé',
        ],
        durationYears: 3,
        certifications: 'Inscription à l\'Ordre des Infirmiers',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 120000,
        maxMonthlyFCFA: 400000,
        averageMonthlyFCFA: 200000,
        experienceNote: 'Salaires plus élevés dans le privé et les ONG internationales. '
            'Possibilité de travail à l\'étranger.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.growing,
        description: 'Forte demande nationale et internationale. '
            'Métier stable avec sécurité d\'emploi.',
        topEmployers: [
          'Hôpitaux publics',
          'Cliniques privées',
          'ONG médicales',
          'Entreprises (infirmerie)',
        ],
        entrepreneurshipPotential: false,
      ),
    ),

    CareerModel(
      id: 'pharmacien',
      name: 'Pharmacien',
      description: 
          'Le pharmacien délivre les médicaments, conseille les patients et gère '
          'l\'approvisionnement pharmaceutique. Profession réglementée et respectée.',
      sector: 'Santé',
      requiredSkills: [
        'Connaissances pharmaceutiques',
        'Précision et rigueur',
        'Conseil aux patients',
        'Gestion de stock',
        'Réglementation',
      ],
      relatedTraits: ['Investigateur', 'Conventionnel', 'Social'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+6',
        recommendedFormations: [
          'Doctorat en Pharmacie',
        ],
        schoolsInTogo: [
          'Faculté des Sciences de la Santé - Université de Lomé',
          'Universités partenaires au Sénégal, Maroc',
        ],
        durationYears: 6,
        certifications: 'Inscription à l\'Ordre des Pharmaciens du Togo',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 300000,
        maxMonthlyFCFA: 1000000,
        averageMonthlyFCFA: 500000,
        experienceNote: 'Les propriétaires de pharmacies peuvent gagner beaucoup plus. '
            'L\'industrie pharmaceutique offre aussi des opportunités.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.medium,
        trend: GrowthTrend.stable,
        description: 'Nombre de pharmaciens réglementé. Marché stable '
            'avec bonnes opportunités pour les pharmacies en zone rurale.',
        topEmployers: [
          'Pharmacies officinales',
          'Hôpitaux',
          'Industrie pharmaceutique',
          'Grossistes (SOTOMED, etc.)',
        ],
        entrepreneurshipPotential: true,
      ),
    ),

    // ============================================
    // SECTEUR: ÉDUCATION
    // ============================================
    CareerModel(
      id: 'enseignant',
      name: 'Enseignant',
      description: 
          'L\'enseignant transmet des connaissances et forme les futures générations. '
          'Métier noble et crucial pour le développement du Togo. Options variées: primaire, '
          'secondaire, supérieur.',
      sector: 'Éducation',
      requiredSkills: [
        'Maîtrise de la matière',
        'Pédagogie',
        'Patience',
        'Communication',
        'Gestion de classe',
      ],
      relatedTraits: ['Social', 'Artistique', 'Linguistique'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+3',
        recommendedFormations: [
          'CAPES (Certificat d\'Aptitude au Professorat)',
          'Licence dans la discipline + formation pédagogique',
          'ENS (École Normale Supérieure)',
        ],
        schoolsInTogo: [
          'ENS Atakpamé',
          'Université de Lomé',
          'ENI (Enseignement Primaire)',
        ],
        durationYears: 3,
        certifications: 'CAPES, CAEN selon le niveau',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 100000,
        maxMonthlyFCFA: 350000,
        averageMonthlyFCFA: 180000,
        experienceNote: 'Salaires dans le public selon l\'échelon. '
            'Écoles privées internationales paient mieux (300K+).',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.stable,
        description: 'Besoin constant d\'enseignants qualifiés. '
            'Les matières scientifiques et l\'anglais sont très demandés.',
        topEmployers: [
          'Éducation Nationale',
          'Écoles privées',
          'Établissements internationaux',
          'Cours particuliers',
        ],
        entrepreneurshipPotential: true,
      ),
    ),

    // ============================================
    // SECTEUR: FINANCE & BANQUE
    // ============================================
    CareerModel(
      id: 'comptable',
      name: 'Comptable',
      description: 
          'Le comptable gère les comptes, établit les bilans et assure la conformité '
          'financière des entreprises. Profession essentielle pour toute organisation.',
      sector: 'Finance & Banque',
      requiredSkills: [
        'Comptabilité générale et analytique',
        'Maîtrise des logiciels comptables',
        'Fiscalité',
        'Rigueur et précision',
        'Organisation',
      ],
      relatedTraits: ['Conventionnel', 'Investigateur', 'Logico-Mathématique'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+2',
        recommendedFormations: [
          'BTS Comptabilité',
          'Licence en Comptabilité',
          'DCG (Diplôme de Comptabilité et Gestion)',
          'DSCG, Expert-Comptable',
        ],
        schoolsInTogo: [
          'ESAG-NDE',
          'UCAO',
          'Université de Lomé - FASEG',
          'ESGIS',
        ],
        durationYears: 2,
        certifications: 'Inscription OECT pour Expert-Comptable',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 120000,
        maxMonthlyFCFA: 600000,
        averageMonthlyFCFA: 250000,
        experienceNote: 'Les experts-comptables et directeurs financiers '
            'peuvent dépasser 800K FCFA. Cabinet propre très lucratif.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.stable,
        description: 'Toute entreprise a besoin d\'un comptable. '
            'Demande stable et opportunités d\'évolution.',
        topEmployers: [
          'Cabinets comptables',
          'Banques',
          'Entreprises diverses',
          'ONG',
        ],
        entrepreneurshipPotential: true,
      ),
    ),

    CareerModel(
      id: 'banquier',
      name: 'Agent Bancaire',
      description: 
          'L\'agent bancaire gère les opérations bancaires, conseille les clients '
          'sur les produits financiers et participe au développement commercial de la banque.',
      sector: 'Finance & Banque',
      requiredSkills: [
        'Connaissances bancaires',
        'Relation client',
        'Commercial',
        'Analyse financière',
        'Discrétion',
      ],
      relatedTraits: ['Entrepreneur', 'Conventionnel', 'Social'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+3',
        recommendedFormations: [
          'Licence en Banque-Finance',
          'Master en Finance',
          'BTS Banque',
        ],
        schoolsInTogo: [
          'FASEG - Université de Lomé',
          'ESAG-NDE',
          'UCAO',
          'ESGIS',
        ],
        durationYears: 3,
        certifications: 'Certifications bancaires internes',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 200000,
        maxMonthlyFCFA: 800000,
        averageMonthlyFCFA: 350000,
        experienceNote: 'Primes et avantages importants dans les grandes banques. '
            'Les directeurs d\'agence dépassent 1M FCFA.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.medium,
        trend: GrowthTrend.stable,
        description: 'Secteur bancaire mature mais en évolution digitale. '
            'Nouvelles compétences tech recherchées.',
        topEmployers: [
          'Ecobank',
          'ORABANK',
          'BTCI',
          'UTB',
          'Coris Bank',
        ],
        entrepreneurshipPotential: false,
      ),
    ),

    // ============================================
    // SECTEUR: COMMERCE & ENTREPRENEURIAT
    // ============================================
    CareerModel(
      id: 'commercial',
      name: 'Commercial / Chef des Ventes',
      description: 
          'Le commercial développe le portefeuille clients, négocie les contrats '
          'et atteint les objectifs de vente. Rôle clé pour la croissance des entreprises.',
      sector: 'Commerce & Entrepreneuriat',
      requiredSkills: [
        'Négociation',
        'Persuasion',
        'Relation client',
        'Atteinte d\'objectifs',
        'Résistance au stress',
      ],
      relatedTraits: ['Entrepreneur', 'Social', 'Interpersonnelle'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+2',
        recommendedFormations: [
          'BTS Commerce',
          'Licence Marketing',
          'Master Commerce International',
        ],
        schoolsInTogo: [
          'ESAG-NDE',
          'ESGIS',
          'UCAO',
          'Université de Lomé',
        ],
        durationYears: 2,
        certifications: 'Formations commerciales certifiantes',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 100000,
        maxMonthlyFCFA: 700000,
        averageMonthlyFCFA: 250000,
        experienceNote: 'Commissions et primes peuvent doubler le salaire fixe. '
            'Les top performers gagnent très bien.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.growing,
        description: 'Toujours besoin de bons commerciaux. '
            'Secteurs FMCG, télécom et tech très actifs.',
        topEmployers: [
          'Nestlé',
          'Unilever',
          'Télécoms',
          'Banques',
          'Distribution',
        ],
        entrepreneurshipPotential: true,
      ),
    ),

    CareerModel(
      id: 'entrepreneur',
      name: 'Entrepreneur / Chef d\'Entreprise',
      description: 
          'L\'entrepreneur crée et développe sa propre entreprise. Au Togo, l\'écosystème '
          'entrepreneurial se développe avec de nombreuses opportunités dans le digital, '
          'l\'agribusiness et les services.',
      sector: 'Commerce & Entrepreneuriat',
      requiredSkills: [
        'Vision stratégique',
        'Leadership',
        'Gestion financière',
        'Résilience',
        'Networking',
      ],
      relatedTraits: ['Entrepreneur', 'Artistique', 'Intrapersonnelle'],
      educationPath: EducationPathModel(
        minimumLevel: 'Variable',
        recommendedFormations: [
          'Tout diplôme pertinent au secteur',
          'Formations en entrepreneuriat',
          'MBA (optionnel)',
        ],
        schoolsInTogo: [
          'Incubateurs: Woelab, CUBE',
          'FAIEJ',
          'Formations GIZ, AFD',
        ],
        durationYears: 0,
        certifications: 'Pas obligatoire, formations en gestion recommandées',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 0,
        maxMonthlyFCFA: 5000000,
        averageMonthlyFCFA: 300000,
        experienceNote: 'Revenus très variables. Premiers mois/années difficiles. '
            'Potentiel de gains illimité avec le succès.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.growing,
        description: 'Le Togo encourage l\'entrepreneuriat (FAIEJ, fonds). '
            'Opportunités dans le digital, l\'agro et les services.',
        topEmployers: [
          'Votre propre entreprise',
        ],
        entrepreneurshipPotential: true,
      ),
    ),

    // ============================================
    // SECTEUR: INGÉNIERIE & BTP
    // ============================================
    CareerModel(
      id: 'ingenieur_civil',
      name: 'Ingénieur Civil / BTP',
      description: 
          'L\'ingénieur civil conçoit et supervise la construction d\'infrastructures: '
          'routes, bâtiments, ponts. Secteur en croissance avec les projets de développement au Togo.',
      sector: 'Ingénierie & BTP',
      requiredSkills: [
        'Calcul de structures',
        'Logiciels CAO (AutoCAD, etc.)',
        'Gestion de chantier',
        'Connaissances matériaux',
        'Travail en équipe',
      ],
      relatedTraits: ['Réaliste', 'Investigateur', 'Spatiale'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+5',
        recommendedFormations: [
          'Diplôme d\'Ingénieur Génie Civil',
          'Master en BTP',
        ],
        schoolsInTogo: [
          'ENSI - Université de Lomé',
          'FORMATEC',
          'Écoles d\'ingénieurs au Maroc, Sénégal',
        ],
        durationYears: 5,
        certifications: 'Inscription Ordre des Ingénieurs',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 250000,
        maxMonthlyFCFA: 1200000,
        averageMonthlyFCFA: 500000,
        experienceNote: 'Les chefs de projet et directeurs techniques '
            'dépassent 1M FCFA. Expatriation lucrative.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.growing,
        description: 'Nombreux projets d\'infrastructure au Togo. '
            'Demande forte pour ingénieurs qualifiés.',
        topEmployers: [
          'Entreprises BTP locales',
          'Groupes internationaux',
          'Administration (Ministère)',
          'Bureaux d\'études',
        ],
        entrepreneurshipPotential: true,
      ),
    ),

    CareerModel(
      id: 'architecte',
      name: 'Architecte',
      description: 
          'L\'architecte conçoit des bâtiments en alliant esthétique, fonctionnalité '
          'et normes techniques. Métier créatif très demandé dans un Togo en construction.',
      sector: 'Ingénierie & BTP',
      requiredSkills: [
        'Conception architecturale',
        'Logiciels 3D (Revit, SketchUp)',
        'Créativité',
        'Connaissance des normes',
        'Relation client',
      ],
      relatedTraits: ['Artistique', 'Réaliste', 'Spatiale'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+5',
        recommendedFormations: [
          'Diplôme d\'Architecte',
        ],
        schoolsInTogo: [
          'EAMAU (École Africaine) - Lomé',
          'Écoles d\'architecture au Maroc, Bénin',
        ],
        durationYears: 5,
        certifications: 'Inscription Ordre des Architectes',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 200000,
        maxMonthlyFCFA: 1000000,
        averageMonthlyFCFA: 450000,
        experienceNote: 'Les architectes avec leur propre cabinet '
            'et des projets prestigieux gagnent bien plus.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.medium,
        trend: GrowthTrend.growing,
        description: 'Croissance urbaine = besoin d\'architectes. '
            'Marchés publics et privés en développement.',
        topEmployers: [
          'Cabinets d\'architecture',
          'Entreprises BTP',
          'Ministère de l\'Urbanisme',
          'Freelance',
        ],
        entrepreneurshipPotential: true,
      ),
    ),

    // ============================================
    // SECTEUR: AGRICULTURE & ENVIRONNEMENT
    // ============================================
    CareerModel(
      id: 'agronome',
      name: 'Ingénieur Agronome',
      description: 
          'L\'agronome améliore les techniques agricoles, conseille les agriculteurs '
          'et développe des solutions pour augmenter les rendements. Secteur clé au Togo, '
          'pays à vocation agricole.',
      sector: 'Agriculture & Environnement',
      requiredSkills: [
        'Sciences agronomiques',
        'Connaissance des cultures locales',
        'Conseil agricole',
        'Gestion de projet',
        'Travail terrain',
      ],
      relatedTraits: ['Réaliste', 'Investigateur', 'Naturaliste'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+5',
        recommendedFormations: [
          'Diplôme d\'Ingénieur Agronome',
          'Master en Agronomie',
        ],
        schoolsInTogo: [
          'ESA - Université de Lomé',
          'INFA de Tové',
          'Écoles au Bénin, Sénégal, Maroc',
        ],
        durationYears: 5,
        certifications: 'Certifications en agriculture durable',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 150000,
        maxMonthlyFCFA: 700000,
        averageMonthlyFCFA: 350000,
        experienceNote: 'ONG et organisations internationales paient bien. '
            'L\'agribusiness propre peut être très lucratif.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.growing,
        description: 'Agriculture = 40% du PIB togolais. Fort potentiel '
            'dans l\'agribusiness et l\'agriculture durable.',
        topEmployers: [
          'Ministère de l\'Agriculture',
          'ONG (GIZ, PNUD)',
          'Entreprises agro-alimentaires',
          'Agribusiness privé',
        ],
        entrepreneurshipPotential: true,
      ),
    ),

    // ============================================
    // SECTEUR: TECHNOLOGIE & INFORMATIQUE (suite)
    // ============================================
    CareerModel(
      id: 'dev_mobile',
      name: 'Développeur Mobile',
      description:
          'Le développeur mobile crée des applications Android et iOS. '
          'Métier en forte demande avec la pénétration croissante des smartphones en Afrique.',
      sector: 'Technologie & Informatique',
      requiredSkills: [
        'Flutter, React Native ou Kotlin/Swift',
        'Conception UI/UX mobile',
        'APIs REST',
        'Débogage mobile',
        'Publication sur stores',
      ],
      relatedTraits: ['Investigateur', 'Artistique', 'Conventionnel'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+2',
        recommendedFormations: [
          'Licence en Informatique',
          'BTS Informatique',
          'Bootcamp Mobile (3-6 mois)',
        ],
        schoolsInTogo: [
          'IAI-TOGO',
          'ESIBA',
          'ESGIS',
          'Formations en ligne (Udemy, Coursera)',
        ],
        durationYears: 2,
        certifications: 'Google Associate Android Developer',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 150000,
        maxMonthlyFCFA: 700000,
        averageMonthlyFCFA: 320000,
        experienceNote: 'Freelance international très lucratif. Upwork et Fiverr ouvrent des marchés globaux.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.growing,
        description: 'L\'économie mobile africaine explose. Fintech, e-commerce, m-santé.',
        topEmployers: ['Gozem', 'Semoa', 'Startups Fintech', 'Freelance'],
        entrepreneurshipPotential: true,
      ),
    ),

    CareerModel(
      id: 'admin_systemes',
      name: 'Administrateur Systèmes & Réseaux',
      description:
          'L\'administrateur gère les serveurs, réseaux et sécurité informatique des entreprises. '
          'Métier stable et indispensable à toute organisation moderne.',
      sector: 'Technologie & Informatique',
      requiredSkills: [
        'Linux / Windows Server',
        'Réseaux (TCP/IP, VPN)',
        'Sécurité informatique',
        'Virtualisation (VMware, Hyper-V)',
        'Cloud (AWS, Azure)',
      ],
      relatedTraits: ['Investigateur', 'Conventionnel', 'Réaliste'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+2',
        recommendedFormations: [
          'BTS Réseaux & Télécoms',
          'Licence Génie Informatique',
          'Certifications Cisco (CCNA)',
        ],
        schoolsInTogo: [
          'IAI-TOGO',
          'ESIBA',
          'Université de Lomé - IUT',
        ],
        durationYears: 2,
        certifications: 'CCNA, CompTIA Network+, Microsoft Azure',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 150000,
        maxMonthlyFCFA: 600000,
        averageMonthlyFCFA: 280000,
        experienceNote: 'Les certifications internationales doublent la valeur sur le marché.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.growing,
        description: 'Toute entreprise, banque, ONG a besoin d\'un admin réseau.',
        topEmployers: ['Banques', 'Télécoms', 'ONG', 'Administrations', 'BCEAO'],
        entrepreneurshipPotential: false,
      ),
    ),

    CareerModel(
      id: 'responsable_digital',
      name: 'Responsable Digital / Chef de Projet IT',
      description:
          'Le chef de projet IT coordonne les équipes techniques, gère les délais et '
          'traduit les besoins métier en solutions informatiques.',
      sector: 'Technologie & Informatique',
      requiredSkills: [
        'Gestion de projet (Agile, Scrum)',
        'Communication transversale',
        'Culture technique (sans coder)',
        'Budget et planning',
        'Outils collaboratifs',
      ],
      relatedTraits: ['Entrepreneur', 'Conventionnel', 'Investigateur'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+3',
        recommendedFormations: [
          'Licence en Informatique de Gestion',
          'Master Management des SI',
          'MBA avec spécialisation IT',
        ],
        schoolsInTogo: [
          'ESGIS',
          'ESAG-NDE',
          'Université de Lomé',
        ],
        durationYears: 3,
        certifications: 'PMP, PRINCE2, Scrum Master',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 250000,
        maxMonthlyFCFA: 900000,
        averageMonthlyFCFA: 450000,
        experienceNote: 'Profil hybride tech+business très recherché. Évolution vers DSI.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.growing,
        description: 'La transformation digitale crée une forte demande pour les chefs de projet IT.',
        topEmployers: ['Banques', 'Grandes entreprises', 'Consulting', 'ONG internationales'],
        entrepreneurshipPotential: true,
      ),
    ),

    // ============================================
    // SECTEUR: SANTÉ (suite)
    // ============================================
    CareerModel(
      id: 'sage_femme',
      name: 'Sage-Femme / Maïeuticien',
      description:
          'La sage-femme accompagne les femmes pendant la grossesse, l\'accouchement et '
          'le post-partum. Profession indispensable pour améliorer la santé maternelle au Togo.',
      sector: 'Santé',
      requiredSkills: [
        'Obstétrique et gynécologie',
        'Soins néonataux',
        'Empathie et gestion du stress',
        'Protocoles d\'urgence',
        'Santé publique',
      ],
      relatedTraits: ['Social', 'Conventionnel', 'Réaliste'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+3',
        recommendedFormations: [
          'Diplôme d\'État de Sage-Femme',
          'Licence en Maïeutique',
        ],
        schoolsInTogo: [
          'ENAM (École Nationale des Auxiliaires Médicaux)',
          'ESTBA - Université de Lomé',
        ],
        durationYears: 3,
        certifications: 'Inscription à l\'Ordre des Sages-Femmes',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 120000,
        maxMonthlyFCFA: 450000,
        averageMonthlyFCFA: 220000,
        experienceNote: 'ONG de santé maternelle et cliniques privées offrent des salaires plus élevés.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.growing,
        description: 'Fort besoin national. Le taux de mortalité maternelle crée une urgence professionnelle.',
        topEmployers: ['Maternités publiques', 'Cliniques privées', 'ONG (UNFPA, UNICEF)', 'MSF'],
        entrepreneurshipPotential: false,
      ),
    ),

    CareerModel(
      id: 'laborantin',
      name: 'Technicien de Laboratoire Médical',
      description:
          'Le laborantin réalise les analyses biologiques (sang, urines, microbiologie) '
          'qui guident le diagnostic médical. Métier discret mais essentiel.',
      sector: 'Santé',
      requiredSkills: [
        'Analyses biologiques',
        'Manipulation des réactifs',
        'Rigueur et précision',
        'Protocoles d\'hygiène et sécurité',
        'Informatique médicale',
      ],
      relatedTraits: ['Investigateur', 'Conventionnel', 'Réaliste'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+2',
        recommendedFormations: [
          'BTS Analyses de Biologie Médicale',
          'Licence Sciences Biologiques',
        ],
        schoolsInTogo: [
          'ENAM',
          'Faculté des Sciences - Université de Lomé',
        ],
        durationYears: 2,
        certifications: 'Accréditation ISO 15189 (normes labo)',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 100000,
        maxMonthlyFCFA: 350000,
        averageMonthlyFCFA: 190000,
        experienceNote: 'Les laboratoires privés et les cliniques internationales paient mieux.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.stable,
        description: 'Demande constante dans les hôpitaux, cliniques, et laboratoires indépendants.',
        topEmployers: ['Hôpitaux publics', 'Cliniques privées', 'Laboratoires indépendants', 'ONG'],
        entrepreneurshipPotential: true,
      ),
    ),

    // ============================================
    // SECTEUR: ÉDUCATION (suite)
    // ============================================
    CareerModel(
      id: 'formateur',
      name: 'Formateur Professionnel',
      description:
          'Le formateur conçoit et anime des formations pour adultes en entreprise ou '
          'en centre de formation. Rôle clé dans le développement des compétences.',
      sector: 'Éducation',
      requiredSkills: [
        'Ingénierie pédagogique',
        'Animation de groupe',
        'Expertise métier',
        'Communication orale',
        'Évaluation des acquis',
      ],
      relatedTraits: ['Social', 'Entrepreneur', 'Artistique'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+3',
        recommendedFormations: [
          'Licence en Sciences de l\'Éducation',
          'Licence dans la discipline + formation pédagogique',
          'Master en Ingénierie de Formation',
        ],
        schoolsInTogo: [
          'ENS Atakpamé',
          'FASEG - Université de Lomé',
          'UCAO',
        ],
        durationYears: 3,
        certifications: 'Certification de formateur (CQP)',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 120000,
        maxMonthlyFCFA: 500000,
        averageMonthlyFCFA: 250000,
        experienceNote: 'Les formateurs freelance pour ONG et entreprises gagnent bien. Journées facturées.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.growing,
        description: 'La formation professionnelle est prioritaire pour les entreprises et ONG au Togo.',
        topEmployers: ['Centres de formation', 'ONG (GIZ, AFD)', 'Entreprises (formation interne)', 'Freelance'],
        entrepreneurshipPotential: true,
      ),
    ),

    CareerModel(
      id: 'conseiller_orientation',
      name: 'Conseiller d\'Orientation Scolaire',
      description:
          'Le conseiller aide les élèves à construire leur projet scolaire et professionnel. '
          'Métier utile et valorisant au cœur de l\'éducation nationale.',
      sector: 'Éducation',
      requiredSkills: [
        'Psychologie de l\'adolescent',
        'Connaissance du système éducatif',
        'Entretien individuel',
        'Tests d\'orientation',
        'Écoute et empathie',
      ],
      relatedTraits: ['Social', 'Investigateur', 'Conventionnel'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+3',
        recommendedFormations: [
          'Licence en Psychologie',
          'Licence en Sciences de l\'Éducation',
          'Master en Conseil et Orientation',
        ],
        schoolsInTogo: [
          'ENS Atakpamé',
          'Université de Lomé - Psychologie',
        ],
        durationYears: 3,
        certifications: 'CAPES Orientation, formations spécialisées',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 100000,
        maxMonthlyFCFA: 300000,
        averageMonthlyFCFA: 180000,
        experienceNote: 'Fonction publique avec évolution par échelon. Privé et ONG offrent plus.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.medium,
        trend: GrowthTrend.growing,
        description: 'Les établissements privés et les plateformes numériques créent de nouveaux débouchés.',
        topEmployers: ['Éducation Nationale', 'Lycées privés', 'Plateformes EdTech', 'ONG jeunesse'],
        entrepreneurshipPotential: true,
      ),
    ),

    CareerModel(
      id: 'responsable_pedagogique',
      name: 'Responsable Pédagogique / Directeur d\'École',
      description:
          'Le responsable pédagogique coordonne les programmes, encadre les enseignants '
          'et veille à la qualité de l\'enseignement.',
      sector: 'Éducation',
      requiredSkills: [
        'Leadership éducatif',
        'Gestion d\'équipe',
        'Élaboration de curricula',
        'Suivi des résultats',
        'Relation parents/partenaires',
      ],
      relatedTraits: ['Social', 'Entrepreneur', 'Conventionnel'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+5',
        recommendedFormations: [
          'Master en Administration Éducative',
          'Master en Sciences de l\'Éducation',
          'Diplôme d\'administration scolaire',
        ],
        schoolsInTogo: [
          'ENS Atakpamé',
          'Université de Lomé',
          'UCAO',
        ],
        durationYears: 5,
        certifications: 'Autorisation d\'ouverture d\'établissement (MEN Togo)',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 200000,
        maxMonthlyFCFA: 800000,
        averageMonthlyFCFA: 380000,
        experienceNote: 'Les directeurs d\'écoles privées réputées ont des revenus attractifs.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.medium,
        trend: GrowthTrend.stable,
        description: 'Multiplication des établissements privés = besoin de cadres pédagogiques.',
        topEmployers: ['Groupes scolaires privés', 'Écoles internationales', 'ONG éducation', 'MEN Togo'],
        entrepreneurshipPotential: true,
      ),
    ),

    // ============================================
    // SECTEUR: FINANCE & BANQUE (suite)
    // ============================================
    CareerModel(
      id: 'analyste_financier',
      name: 'Analyste Financier',
      description:
          'L\'analyste financier évalue la santé financière des entreprises, analyse '
          'les marchés et formule des recommandations d\'investissement.',
      sector: 'Finance & Banque',
      requiredSkills: [
        'Analyse financière et comptable',
        'Modélisation financière (Excel avancé)',
        'Marchés financiers',
        'Rédaction de rapports',
        'Anglais professionnel',
      ],
      relatedTraits: ['Conventionnel', 'Investigateur', 'Entrepreneur'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+4',
        recommendedFormations: [
          'Master Finance d\'Entreprise',
          'Master Banque & Finance',
          'Licence + CFA (Chartered Financial Analyst)',
        ],
        schoolsInTogo: [
          'FASEG - Université de Lomé',
          'ESAG-NDE',
          'ESGIS',
        ],
        durationYears: 4,
        certifications: 'CFA, ACCA, certifications Bloomberg',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 300000,
        maxMonthlyFCFA: 1200000,
        averageMonthlyFCFA: 550000,
        experienceNote: 'Profil très demandé par les banques, fonds d\'investissement et cabinets de conseil.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.medium,
        trend: GrowthTrend.growing,
        description: 'Le développement des marchés financiers régionaux BRVM crée des opportunités.',
        topEmployers: ['Ecobank', 'ORABANK', 'Fonds d\'investissement', 'Cabinets conseil', 'BCEAO'],
        entrepreneurshipPotential: false,
      ),
    ),

    CareerModel(
      id: 'agent_assurance',
      name: 'Agent / Chargé d\'Assurance',
      description:
          'L\'agent d\'assurance conseille les clients sur les produits (vie, auto, habitation, santé), '
          'gère les sinistres et développe son portefeuille.',
      sector: 'Finance & Banque',
      requiredSkills: [
        'Techniques d\'assurance',
        'Commercial et négociation',
        'Gestion des sinistres',
        'Analyse des risques',
        'Relation client',
      ],
      relatedTraits: ['Entrepreneur', 'Conventionnel', 'Social'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+2',
        recommendedFormations: [
          'BTS Assurance',
          'Licence Banque-Assurance',
          'Formations internes (FANAF)',
        ],
        schoolsInTogo: [
          'ESAG-NDE',
          'UCAO',
          'Université de Lomé',
        ],
        durationYears: 2,
        certifications: 'Certifications FANAF (Fédération Africaine des Assureurs)',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 100000,
        maxMonthlyFCFA: 600000,
        averageMonthlyFCFA: 220000,
        experienceNote: 'Les commissions sur ventes peuvent dépasser le salaire de base. Potentiel élevé.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.medium,
        trend: GrowthTrend.growing,
        description: 'Le taux de pénétration de l\'assurance au Togo est faible = fort potentiel de développement.',
        topEmployers: ['NSIA Assurances', 'Gras Savoye', 'GFA Vie', 'COLINA', 'Compagnies locales'],
        entrepreneurshipPotential: true,
      ),
    ),

    CareerModel(
      id: 'controleur_gestion',
      name: 'Contrôleur de Gestion',
      description:
          'Le contrôleur de gestion suit les performances financières de l\'entreprise, '
          'pilote les budgets et aide à la prise de décision stratégique.',
      sector: 'Finance & Banque',
      requiredSkills: [
        'Comptabilité analytique',
        'Tableaux de bord et reporting',
        'Analyse des écarts budgétaires',
        'Excel / Power BI',
        'Planification financière',
      ],
      relatedTraits: ['Conventionnel', 'Investigateur', 'Entrepreneur'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+4',
        recommendedFormations: [
          'Master Contrôle de Gestion',
          'Master Finance & Comptabilité',
          'DSCG (Diplôme Supérieur de Comptabilité)',
        ],
        schoolsInTogo: [
          'FASEG - Université de Lomé',
          'ESAG-NDE',
          'ESGIS',
        ],
        durationYears: 4,
        certifications: 'DSCG, certifications OHADA',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 280000,
        maxMonthlyFCFA: 1000000,
        averageMonthlyFCFA: 500000,
        experienceNote: 'Poste stratégique avec forte évolution vers DAF (Directeur Administratif et Financier).',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.stable,
        description: 'Indispensable dans les grandes entreprises, multinationales et ONG.',
        topEmployers: ['Multinationales', 'Banques', 'Grandes entreprises togolaises', 'ONG internationales'],
        entrepreneurshipPotential: false,
      ),
    ),

    // ============================================
    // SECTEUR: COMMERCE & ENTREPRENEURIAT (suite)
    // ============================================
    CareerModel(
      id: 'responsable_marketing',
      name: 'Responsable Marketing / Digital',
      description:
          'Le responsable marketing conçoit et pilote les stratégies de communication, '
          'gère les réseaux sociaux, les campagnes et l\'image de marque.',
      sector: 'Commerce & Entrepreneuriat',
      requiredSkills: [
        'Stratégie marketing',
        'Réseaux sociaux et publicité digitale',
        'Rédaction et création de contenu',
        'Analyse des données (Google Analytics)',
        'Créativité',
      ],
      relatedTraits: ['Entrepreneur', 'Artistique', 'Social'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+3',
        recommendedFormations: [
          'Licence Marketing',
          'Master en Communication et Marketing',
          'BTS Commerce + formations digitales',
        ],
        schoolsInTogo: [
          'ESAG-NDE',
          'ESGIS',
          'UCAO',
          'Formations en ligne (Google, HubSpot)',
        ],
        durationYears: 3,
        certifications: 'Google Ads, Meta Blueprint, HubSpot Marketing',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 120000,
        maxMonthlyFCFA: 700000,
        averageMonthlyFCFA: 300000,
        experienceNote: 'Le marketing digital freelance pour clients africains et internationaux est très rentable.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.growing,
        description: 'Toutes les entreprises ont besoin de visibilité digitale. Marché en explosion.',
        topEmployers: ['Agences digitales', 'Startups', 'Grandes entreprises', 'Freelance'],
        entrepreneurshipPotential: true,
      ),
    ),

    CareerModel(
      id: 'logisticien',
      name: 'Logisticien / Gestionnaire Import-Export',
      description:
          'Le logisticien gère la chaîne d\'approvisionnement, les flux de marchandises, '
          'les douanes et les transports. Rôle clé dans le commerce togolais.',
      sector: 'Commerce & Entrepreneuriat',
      requiredSkills: [
        'Gestion de la supply chain',
        'Réglementation douanière',
        'Incoterms et commerce international',
        'Logiciels de gestion (ERP)',
        'Négociation fournisseurs',
      ],
      relatedTraits: ['Conventionnel', 'Entrepreneur', 'Réaliste'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+2',
        recommendedFormations: [
          'BTS Commerce International',
          'Licence Logistique & Transport',
          'Master Supply Chain Management',
        ],
        schoolsInTogo: [
          'Université de Lomé - FASEG',
          'ESAG-NDE',
          'Écoles de transit et douane',
        ],
        durationYears: 2,
        certifications: 'Déclarant en douane, CSCMP',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 150000,
        maxMonthlyFCFA: 700000,
        averageMonthlyFCFA: 300000,
        experienceNote: 'Le port autonome de Lomé et le transit font de la logistique un secteur clé au Togo.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.growing,
        description: 'Port de Lomé = hub régional. Forte demande en logistique et transit.',
        topEmployers: ['TOGO PORT', 'Transitaires', 'Groupes GETMA, BOLLORÉ', 'Entreprises import-export'],
        entrepreneurshipPotential: true,
      ),
    ),

    // ============================================
    // SECTEUR: INGÉNIERIE & BTP (suite)
    // ============================================
    CareerModel(
      id: 'ingenieur_electricien',
      name: 'Ingénieur Électricien / Électrotechnicien',
      description:
          'L\'ingénieur électricien conçoit et maintient les installations électriques '
          'industrielles, les réseaux d\'énergie et les systèmes d\'automatisation.',
      sector: 'Ingénierie & BTP',
      requiredSkills: [
        'Électrotechnique et électronique de puissance',
        'Normes électriques',
        'Automatisation (PLC)',
        'Énergie solaire et renouvelable',
        'Sécurité électrique',
      ],
      relatedTraits: ['Réaliste', 'Investigateur', 'Conventionnel'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+3',
        recommendedFormations: [
          'Licence Génie Électrique',
          'DUT Génie Électrique et Informatique Industrielle',
          'Diplôme d\'Ingénieur Électricien',
        ],
        schoolsInTogo: [
          'ENSI - Université de Lomé',
          'IUT Lomé',
          'FORMATEC',
        ],
        durationYears: 3,
        certifications: 'Habilitation électrique, Certifications énergie solaire',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 200000,
        maxMonthlyFCFA: 900000,
        averageMonthlyFCFA: 400000,
        experienceNote: 'Le boom du solaire et des énergies renouvelables crée des opportunités inédites.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.growing,
        description: 'CEET, énergies renouvelables et construction industrielle tirent la demande.',
        topEmployers: ['CEET', 'SINOPEC', 'Entreprises minières', 'Sociétés solaires', 'BTP industriel'],
        entrepreneurshipPotential: true,
      ),
    ),

    CareerModel(
      id: 'topographe',
      name: 'Technicien Topographe / Géomètre',
      description:
          'Le topographe mesure et cartographie les terrains, indispensable pour les projets '
          'de construction, d\'urbanisme et de gestion foncière.',
      sector: 'Ingénierie & BTP',
      requiredSkills: [
        'Levés topographiques (station totale, GPS)',
        'SIG (ArcGIS, QGIS)',
        'Dessin technique (AutoCAD)',
        'Droit foncier',
        'Travail terrain',
      ],
      relatedTraits: ['Réaliste', 'Investigateur', 'Conventionnel'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+2',
        recommendedFormations: [
          'DUT Génie Civil option Topographie',
          'BTS Géomètre-Topographe',
          'Licence Génie Géomatique',
        ],
        schoolsInTogo: [
          'IUT - Université de Lomé',
          'INFA de Tové (formation agricole/topographie)',
          'Écoles au Bénin et Ghana',
        ],
        durationYears: 2,
        certifications: 'Inscription à l\'Ordre des Géomètres Experts',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 150000,
        maxMonthlyFCFA: 600000,
        averageMonthlyFCFA: 280000,
        experienceNote: 'Les géomètres experts indépendants avec clientèle privée gagnent très bien.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.growing,
        description: 'Urbanisation rapide et projets fonciers = forte demande constante.',
        topEmployers: ['Ministère de l\'Urbanisme', 'Bureaux d\'études', 'Mairies', 'Entreprises BTP'],
        entrepreneurshipPotential: true,
      ),
    ),

    CareerModel(
      id: 'technicien_mecanique',
      name: 'Technicien en Génie Mécanique / Maintenance',
      description:
          'Le technicien assure la maintenance préventive et corrective des équipements '
          'industriels, véhicules et machines de production.',
      sector: 'Ingénierie & BTP',
      requiredSkills: [
        'Mécanique générale et industrielle',
        'Lecture de plans techniques',
        'Diagnostic et réparation',
        'Hydraulique et pneumatique',
        'Sécurité industrielle',
      ],
      relatedTraits: ['Réaliste', 'Conventionnel', 'Investigateur'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC',
        recommendedFormations: [
          'CAP Mécanique',
          'BTS Maintenance Industrielle',
          'Licence Génie Mécanique',
        ],
        schoolsInTogo: [
          'CFPT (Centre de Formation Professionnelle et Technique)',
          'IUT - Université de Lomé',
          'Centres professionnels privés',
        ],
        durationYears: 2,
        certifications: 'Habilitations sécurité, certifications constructeurs',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 100000,
        maxMonthlyFCFA: 500000,
        averageMonthlyFCFA: 220000,
        experienceNote: 'Industries, entreprises minières et BTP offrent les meilleurs salaires.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.stable,
        description: 'Industrie, transport et BTP ont besoin en permanence de techniciens qualifiés.',
        topEmployers: ['Ciments du Togo', 'Phosphates du Togo (OTP)', 'Garages industriels', 'BTP', 'CEET'],
        entrepreneurshipPotential: true,
      ),
    ),

    // ============================================
    // SECTEUR: AGRICULTURE & ENVIRONNEMENT (suite)
    // ============================================
    CareerModel(
      id: 'veterinaire',
      name: 'Vétérinaire',
      description:
          'Le vétérinaire soigne les animaux, assure la surveillance sanitaire '
          'et contribue à la sécurité alimentaire (bétail, volaille, aquaculture).',
      sector: 'Agriculture & Environnement',
      requiredSkills: [
        'Médecine vétérinaire',
        'Chirurgie animale',
        'Épidémiologie animale',
        'Inspection vétérinaire',
        'Santé publique vétérinaire',
      ],
      relatedTraits: ['Social', 'Investigateur', 'Réaliste'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+5',
        recommendedFormations: [
          'Doctorat en Médecine Vétérinaire',
        ],
        schoolsInTogo: [
          'École de Médecine Vétérinaire au Bénin (ENSTA)',
          'Universités au Maroc, Sénégal, Côte d\'Ivoire',
        ],
        durationYears: 5,
        certifications: 'Inscription à l\'Ordre des Vétérinaires du Togo',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 200000,
        maxMonthlyFCFA: 800000,
        averageMonthlyFCFA: 400000,
        experienceNote: 'Clinique privée et travail international très rémunérateurs.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.growing,
        description: 'Élevage intensif et aquaculture en développement. Manque de vétérinaires qualifiés.',
        topEmployers: ['Ministère de l\'Agriculture', 'FAO', 'Cliniques vétérinaires', 'Industries agro'],
        entrepreneurshipPotential: true,
      ),
    ),

    CareerModel(
      id: 'ingenieur_environnement',
      name: 'Ingénieur en Environnement / Développement Durable',
      description:
          'L\'ingénieur en environnement évalue les impacts environnementaux, '
          'gère les ressources naturelles et accompagne la transition vers le développement durable.',
      sector: 'Agriculture & Environnement',
      requiredSkills: [
        'Évaluation d\'impact environnemental',
        'Gestion des ressources en eau et en sol',
        'Réglementation environnementale',
        'SIG et cartographie',
        'Plaidoyer et sensibilisation',
      ],
      relatedTraits: ['Investigateur', 'Réaliste', 'Social'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+5',
        recommendedFormations: [
          'Licence en Sciences de l\'Environnement',
          'Master Environnement et Développement Durable',
          'Master Gestion des Ressources Naturelles',
        ],
        schoolsInTogo: [
          'Université de Lomé - Sciences',
          'INFA de Tové',
          'Universités au Maroc (Mohamed VI)',
        ],
        durationYears: 5,
        certifications: 'Certifications ISO 14001, Lead Auditor Environnement',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 200000,
        maxMonthlyFCFA: 900000,
        averageMonthlyFCFA: 420000,
        experienceNote: 'Les ONG internationales et bailleurs de fonds paient très bien.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.growing,
        description: 'Changement climatique et projets de développement = forte demande en experts environnement.',
        topEmployers: ['PNUD', 'PNUE', 'GIZ', 'Ministère de l\'Environnement', 'Bureaux d\'études'],
        entrepreneurshipPotential: true,
      ),
    ),

    CareerModel(
      id: 'technicien_agroalimentaire',
      name: 'Technicien Agroalimentaire',
      description:
          'Le technicien agroalimentaire contrôle la qualité des produits alimentaires, '
          'gère la transformation et veille au respect des normes sanitaires.',
      sector: 'Agriculture & Environnement',
      requiredSkills: [
        'Biochimie alimentaire',
        'Contrôle qualité (HACCP)',
        'Procédés de transformation',
        'Microbiologie alimentaire',
        'Gestion de production',
      ],
      relatedTraits: ['Réaliste', 'Conventionnel', 'Investigateur'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+2',
        recommendedFormations: [
          'BTS Industries Agroalimentaires',
          'Licence en Sciences des Aliments',
          'Master Agroalimentaire et Nutrition',
        ],
        schoolsInTogo: [
          'Université de Lomé - Sciences',
          'INFA de Tové',
          'ITRA (Institut Togolais de Recherche Agronomique)',
        ],
        durationYears: 2,
        certifications: 'HACCP, ISO 22000 (sécurité alimentaire)',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 120000,
        maxMonthlyFCFA: 450000,
        averageMonthlyFCFA: 240000,
        experienceNote: 'L\'agro-industrie locale et les exportations (café, cacao) offrent de bonnes perspectives.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.growing,
        description: 'Transformation locale des produits agricoles = priorité nationale. Secteur porteur.',
        topEmployers: ['NIOTO', 'Entreprises agro-industrielles', 'ONG (FAO)', 'ITRA', 'Supermarchés'],
        entrepreneurshipPotential: true,
      ),
    ),

    // ============================================
    // SECTEUR: CRÉATION & MÉDIAS (suite)
    // ============================================
    CareerModel(
      id: 'designer_graphique',
      name: 'Designer Graphique',
      description: 
          'Le designer graphique crée des visuels pour la communication: logos, '
          'affiches, interfaces web. Métier créatif en forte demande avec la digitalisation.',
      sector: 'Création & Médias',
      requiredSkills: [
        'Créativité visuelle',
        'Maîtrise Adobe (Photoshop, Illustrator)',
        'Sens artistique',
        'Tendances design',
        'Communication client',
      ],
      relatedTraits: ['Artistique', 'Entrepreneur', 'Spatiale'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+2',
        recommendedFormations: [
          'BTS Design Graphique',
          'Licence en Arts Graphiques',
          'Formations professionnelles (3-6 mois)',
        ],
        schoolsInTogo: [
          'IBTC',
          'Formations privées diverses',
          'Apprentissage autodidacte + portfolio',
        ],
        durationYears: 2,
        certifications: 'Adobe Certified, expérience et portfolio clés',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 80000,
        maxMonthlyFCFA: 450000,
        averageMonthlyFCFA: 200000,
        experienceNote: 'Le freelance pour clients internationaux '
            'peut rapporter bien plus. Portfolio = clé du succès.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.growing,
        description: 'Tout business a besoin de visuels. Forte demande '
            'locale et opportunités internationales en freelance.',
        topEmployers: [
          'Agences de communication',
          'Entreprises diverses',
          'Freelance',
          'Startups',
        ],
        entrepreneurshipPotential: true,
      ),
    ),

    CareerModel(
      id: 'journaliste',
      name: 'Journaliste',
      description: 
          'Le journaliste collecte, vérifie et diffuse l\'information. Au Togo, '
          'les médias se diversifient avec le digital, créant de nouvelles opportunités.',
      sector: 'Création & Médias',
      requiredSkills: [
        'Rédaction et style',
        'Curiosité et investigation',
        'Éthique journalistique',
        'Outils multimédia',
        'Réseaux sociaux',
      ],
      relatedTraits: ['Artistique', 'Social', 'Linguistique'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+3',
        recommendedFormations: [
          'Licence en Journalisme',
          'Licence en Communication',
          'Master Journalisme',
        ],
        schoolsInTogo: [
          'ISICA',
          'Université de Lomé - Communication',
          'ESTACOM',
        ],
        durationYears: 3,
        certifications: 'Carte de presse',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 80000,
        maxMonthlyFCFA: 400000,
        averageMonthlyFCFA: 180000,
        experienceNote: 'Les médias internationaux et correspondants '
            'étrangers sont mieux payés. Piges complémentaires possibles.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.medium,
        trend: GrowthTrend.stable,
        description: 'Médias traditionnels en difficulté mais '
            'le digital ouvre de nouvelles voies (podcasts, YouTube).',
        topEmployers: [
          'Togovi TV',
          'TVT',
          'Médias en ligne',
          'Correspondants presse étrangère',
        ],
        entrepreneurshipPotential: true,
      ),
    ),

    CareerModel(
      id: 'photographe_videaste',
      name: 'Photographe / Vidéaste',
      description:
          'Le photographe-vidéaste capture des images et vidéos pour les événements, '
          'la publicité, les médias et les réseaux sociaux.',
      sector: 'Création & Médias',
      requiredSkills: [
        'Maîtrise des équipements photo/vidéo',
        'Montage vidéo (Premiere, Final Cut)',
        'Retouche photo (Lightroom, Photoshop)',
        'Sens artistique et de la composition',
        'Marketing personnel',
      ],
      relatedTraits: ['Artistique', 'Entrepreneur', 'Réaliste'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC',
        recommendedFormations: [
          'Formations privées en photographie',
          'BTS Audiovisuel',
          'Apprentissage autodidacte + portfolio',
        ],
        schoolsInTogo: [
          'Centres de formation privés à Lomé',
          'Apprentissage en studio',
          'Formations en ligne (YouTube, Skillshare)',
        ],
        durationYears: 1,
        certifications: 'Portfolio professionnel = meilleure carte de visite',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 80000,
        maxMonthlyFCFA: 600000,
        averageMonthlyFCFA: 200000,
        experienceNote: 'Les événements (mariages, entreprises) et les clients internationaux en freelance rapportent bien.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.growing,
        description: 'La demande en contenu visuel pour réseaux sociaux, publicité et événements explose.',
        topEmployers: ['Médias', 'Agences de communication', 'Événementiel', 'Freelance'],
        entrepreneurshipPotential: true,
      ),
    ),

    CareerModel(
      id: 'createur_contenu',
      name: 'Créateur de Contenu Digital / Community Manager',
      description:
          'Le créateur de contenu produit des posts, vidéos, podcasts et stories pour '
          'les marques et médias. Le community manager gère les communautés en ligne.',
      sector: 'Création & Médias',
      requiredSkills: [
        'Rédaction web et copywriting',
        'Réseaux sociaux (Instagram, TikTok, LinkedIn)',
        'Production vidéo courte',
        'Stratégie de contenu',
        'Analyse des statistiques',
      ],
      relatedTraits: ['Artistique', 'Social', 'Entrepreneur'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC',
        recommendedFormations: [
          'BTS Communication',
          'Licence Marketing Digital',
          'Formations certifiantes en ligne (Meta, Google)',
        ],
        schoolsInTogo: [
          'ISICA',
          'Formations privées de communication',
          'Apprentissage autodidacte',
        ],
        durationYears: 1,
        certifications: 'Meta Blueprint, Google Digital Garage',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 80000,
        maxMonthlyFCFA: 500000,
        averageMonthlyFCFA: 180000,
        experienceNote: 'Les créateurs avec audience peuvent monétiser via sponsoring et formations.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.growing,
        description: 'Chaque entreprise a besoin de présence digitale. Marché en forte croissance.',
        topEmployers: ['Agences digitales', 'Startups', 'Médias', 'Freelance', 'Propre audience'],
        entrepreneurshipPotential: true,
      ),
    ),

    CareerModel(
      id: 'graphiste_ux',
      name: 'Designer UX/UI',
      description:
          'Le designer UX/UI conçoit des interfaces numériques intuitives et esthétiques '
          'pour les applications mobiles et sites web.',
      sector: 'Création & Médias',
      requiredSkills: [
        'Figma, Sketch, Adobe XD',
        'Principes d\'ergonomie',
        'Prototypage et wireframing',
        'Recherche utilisateur',
        'Collaboration avec développeurs',
      ],
      relatedTraits: ['Artistique', 'Investigateur', 'Conventionnel'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+2',
        recommendedFormations: [
          'BTS Design Graphique + formations UX',
          'Bootcamp UX/UI (3-6 mois)',
          'Licence en Design Numérique',
        ],
        schoolsInTogo: [
          'Formations en ligne (Google UX Design, Coursera)',
          'IBTC',
          'Apprentissage autodidacte + portfolio',
        ],
        durationYears: 2,
        certifications: 'Google UX Design Certificate',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 150000,
        maxMonthlyFCFA: 700000,
        averageMonthlyFCFA: 320000,
        experienceNote: 'Freelance international très accessible depuis Lomé via plateformes comme Toptal.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.growing,
        description: 'Tout produit digital a besoin d\'un UX designer. Marché en pleine croissance.',
        topEmployers: ['Startups Tech', 'Agences digitales', 'Gozem', 'Banques digitales', 'Freelance'],
        entrepreneurshipPotential: true,
      ),
    ),

    // ============================================
    // SECTEUR: DROIT & ADMINISTRATION (suite)
    // ============================================
    CareerModel(
      id: 'avocat',
      name: 'Avocat',
      description: 
          'L\'avocat défend et conseille ses clients en matière juridique. Profession '
          'prestigieuse nécessitant rigueur et éloquence.',
      sector: 'Droit & Administration',
      requiredSkills: [
        'Droit et jurisprudence',
        'Éloquence et argumentation',
        'Analyse et synthèse',
        'Éthique professionnelle',
        'Négociation',
      ],
      relatedTraits: ['Entrepreneur', 'Social', 'Linguistique'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+5',
        recommendedFormations: [
          'Maîtrise en Droit',
          'CAPA (Certificat d\'Aptitude à la Profession d\'Avocat)',
        ],
        schoolsInTogo: [
          'Faculté de Droit - Université de Lomé',
          'Stage au Barreau de Lomé',
        ],
        durationYears: 5,
        certifications: 'Inscription au Barreau',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 200000,
        maxMonthlyFCFA: 2000000,
        averageMonthlyFCFA: 500000,
        experienceNote: 'Les avocats d\'affaires et cabinets internationaux '
            'gagnent beaucoup plus. Réputation = revenus.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.medium,
        trend: GrowthTrend.stable,
        description: 'Besoin constant de juristes. Le droit des affaires '
            'et international sont porteurs.',
        topEmployers: [
          'Cabinets d\'avocats',
          'Entreprises (direction juridique)',
          'Organisations internationales',
          'Indépendant',
        ],
        entrepreneurshipPotential: true,
      ),
    ),

    CareerModel(
      id: 'rh',
      name: 'Responsable Ressources Humaines',
      description: 
          'Le RH gère le recrutement, la formation, les carrières et les relations sociales. '
          'Fonction stratégique dans les organisations modernes.',
      sector: 'Droit & Administration',
      requiredSkills: [
        'Gestion des talents',
        'Droit du travail',
        'Communication',
        'Psychologie',
        'Organisation',
      ],
      relatedTraits: ['Social', 'Conventionnel', 'Interpersonnelle'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+3',
        recommendedFormations: [
          'Licence en GRH',
          'Master RH',
          'Master en Psychologie du travail',
        ],
        schoolsInTogo: [
          'FASEG - Université de Lomé',
          'ESAG-NDE',
          'UCAO',
        ],
        durationYears: 3,
        certifications: 'Certifications SHRM, formations continues',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 150000,
        maxMonthlyFCFA: 700000,
        averageMonthlyFCFA: 300000,
        experienceNote: 'Les DRH de grandes entreprises et multinationales '
            'dépassent 1M FCFA avec avantages.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.medium,
        trend: GrowthTrend.growing,
        description: 'La gestion des talents devient stratégique. '
            'Compétences en digital RH recherchées.',
        topEmployers: [
          'Grandes entreprises',
          'Multinationales',
          'ONG',
          'Cabinets de recrutement',
        ],
        entrepreneurshipPotential: true,
      ),
    ),
    CareerModel(
      id: 'notaire',
      name: 'Notaire',
      description:
          'Le notaire authentifie les actes juridiques (contrats, successions, ventes immobilières), '
          'conseille ses clients et sécurise leurs transactions.',
      sector: 'Droit & Administration',
      requiredSkills: [
        'Droit civil et notarial',
        'Gestion patrimoniale',
        'Rigueur documentaire',
        'Relation clientèle',
        'Informatique juridique',
      ],
      relatedTraits: ['Conventionnel', 'Social', 'Entrepreneur'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+6',
        recommendedFormations: [
          'Master en Droit Notarial',
          'Diplôme Supérieur de Notariat',
        ],
        schoolsInTogo: [
          'Faculté de Droit - Université de Lomé',
          'Stage en étude notariale',
        ],
        durationYears: 6,
        certifications: 'Nomination par le Ministre de la Justice',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 400000,
        maxMonthlyFCFA: 3000000,
        averageMonthlyFCFA: 900000,
        experienceNote: 'Les notaires avec leur propre étude ont des revenus très élevés et stables.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.medium,
        trend: GrowthTrend.stable,
        description: 'Profession réglementée à nombre limité. Très bonnes perspectives pour ceux qui y accèdent.',
        topEmployers: ['Étude notariale', 'Tribunaux', 'Administrations foncières'],
        entrepreneurshipPotential: true,
      ),
    ),

    CareerModel(
      id: 'administrateur_civil',
      name: 'Administrateur Civil / Fonctionnaire',
      description:
          'L\'administrateur civil gère les affaires publiques, met en œuvre les politiques '
          'gouvernementales et assure le service aux citoyens.',
      sector: 'Droit & Administration',
      requiredSkills: [
        'Droit public et administratif',
        'Gestion publique',
        'Rédaction administrative',
        'Coordination interministérielle',
        'Éthique du service public',
      ],
      relatedTraits: ['Conventionnel', 'Social', 'Entrepreneur'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+3',
        recommendedFormations: [
          'Licence en Droit',
          'Licence en Administration Publique',
          'ENAP (École Nationale d\'Administration)',
        ],
        schoolsInTogo: [
          'ENAM (École Nationale d\'Administration et de Magistrature)',
          'Université de Lomé - Droit',
        ],
        durationYears: 3,
        certifications: 'Concours de la Fonction Publique',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 150000,
        maxMonthlyFCFA: 600000,
        averageMonthlyFCFA: 280000,
        experienceNote: 'Sécurité d\'emploi et avancement à l\'ancienneté. Retraite garantie.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.medium,
        trend: GrowthTrend.stable,
        description: 'L\'administration publique reste un employeur majeur au Togo.',
        topEmployers: ['Ministères', 'Collectivités locales', 'Préfectures', 'Ambassades'],
        entrepreneurshipPotential: false,
      ),
    ),

    CareerModel(
      id: 'juriste_entreprise',
      name: 'Juriste d\'Entreprise / Conseiller Juridique',
      description:
          'Le juriste d\'entreprise assure la conformité légale des opérations, '
          'rédige les contrats et protège les intérêts juridiques de l\'organisation.',
      sector: 'Droit & Administration',
      requiredSkills: [
        'Droit des affaires (OHADA)',
        'Rédaction de contrats',
        'Droit social et fiscal',
        'Veille réglementaire',
        'Négociation juridique',
      ],
      relatedTraits: ['Conventionnel', 'Entrepreneur', 'Investigateur'],
      educationPath: EducationPathModel(
        minimumLevel: 'BAC+4',
        recommendedFormations: [
          'Master Droit des Affaires',
          'Master Droit OHADA',
          'Master Juriste d\'Entreprise',
        ],
        schoolsInTogo: [
          'Faculté de Droit - Université de Lomé',
          'ESGIS (option juridique)',
        ],
        durationYears: 4,
        certifications: 'Certification OHADA, formations en droit des affaires',
      ),
      salaryInfo: SalaryInfoModel(
        minMonthlyFCFA: 250000,
        maxMonthlyFCFA: 1000000,
        averageMonthlyFCFA: 480000,
        experienceNote: 'Les juristes OHADA sont très recherchés dans toute l\'Afrique de l\'Ouest.',
      ),
      outlook: JobOutlookModel(
        demand: JobDemand.high,
        trend: GrowthTrend.growing,
        description: 'Développement des affaires en Afrique = besoin croissant en juristes spécialisés OHADA.',
        topEmployers: ['Multinationales', 'Banques', 'Cabinets juridiques', 'Organisations internationales'],
        entrepreneurshipPotential: false,
      ),
    ),
  ];

  /// Recherche des métiers par traits dominants
  static List<Career> getCareersForTraits(List<String> traits) {
    return allCareers.where((career) {
      return career.relatedTraits.any((trait) => 
        traits.any((t) => trait.toLowerCase().contains(t.toLowerCase()) ||
                         t.toLowerCase().contains(trait.toLowerCase())));
    }).toList();
  }

  /// Recherche un métier par son ID
  static Career? getCareerById(String id) {
    try {
      return allCareers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Recherche par nom de métier recommandé
  static Career? getCareerByName(String name) {
    try {
      return allCareers.firstWhere((c) => 
        c.name.toLowerCase().contains(name.toLowerCase()) ||
        name.toLowerCase().contains(c.name.toLowerCase()));
    } catch (_) {
      return null;
    }
  }

  /// Tous les métiers d'un secteur
  static List<Career> getCareersBySector(String sector) {
    return allCareers.where((c) => c.sector == sector).toList();
  }

  /// Liste des secteurs uniques
  static List<String> get allSectors {
    return allCareers.map((c) => c.sector).toSet().toList();
  }
}
