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
    // SECTEUR: CRÉATION & MÉDIAS
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

    // ============================================
    // SECTEUR: DROIT & ADMINISTRATION
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
