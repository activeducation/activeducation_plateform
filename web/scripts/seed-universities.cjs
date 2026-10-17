const postgres = require('postgres');
require('dotenv').config({ path: '.env.local' });

if (!process.env.DATABASE_URL) {
  console.error("DATABASE_URL is missing in .env.local");
  process.exit(1);
}

const sql = postgres(process.env.DATABASE_URL);

async function main() {
  console.log("Starting seed for universities and domains...");

  // 1. Domains
  const domains = [
    {
      slug: 'tech-numerique',
      title: 'Tech & Numérique',
      bannerImage: 'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=1200&q=80',
      description: 'Génie logiciel, cybersécurité, intelligence artificielle, data science, systèmes et réseaux.',
      growth: '+22% / an',
      employability: 'Très forte',
      salary: '450 000 - 1 200 000 FCFA',
      why: 'Le secteur technologique est en pleine explosion en Afrique de l’Ouest avec une demande continue en développeurs et experts de la sécurité.',
      isPublished: true,
    },
    {
      slug: 'sciences-sante',
      title: 'Santé & Sciences Médicales',
      bannerImage: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=1200&q=80',
      description: 'Médecine générale, pharmacie, odontostomatologie, santé publique et soins infirmiers.',
      growth: '+14% / an',
      employability: 'Maximale',
      salary: '400 000 - 1 500 000 FCFA',
      why: 'Un besoin critique en personnel soignant qualifié et en spécialistes pour moderniser le système de santé.',
      isPublished: true,
    },
    {
      slug: 'gestion-management',
      title: 'Gestion, Finance & Audit',
      bannerImage: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1200&q=80',
      description: 'Comptabilité, contrôle de gestion, finance d’entreprise, marketing, logistique et commerce international.',
      growth: '+12% / an',
      employability: 'Forte',
      salary: '350 000 - 900 000 FCFA',
      why: 'Le cœur battant des entreprises, banques et multinationales basées à Lomé et dans l’espace UEMOA.',
      isPublished: true,
    },
    {
      slug: 'ingenierie-btp',
      title: 'Ingénierie, BTP & Industrie',
      bannerImage: 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&w=1200&q=80',
      description: 'Génie civil, ouvrages d’art, électromécanique, énergies renouvelables et génie industriel.',
      growth: '+16% / an',
      employability: 'Très forte',
      salary: '450 000 - 1 100 000 FCFA',
      why: 'Grands chantiers d’infrastructures routières, portuaires et énergétiques en cours au Togo.',
      isPublished: true,
    },
    {
      slug: 'architecture-urbanisme',
      title: 'Architecture & Aménagement Urbain',
      bannerImage: 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?auto=format&fit=crop&w=1200&q=80',
      description: 'Architecture durable, urbanisme, design d’espace, géomatique et aménagement du territoire.',
      growth: '+15% / an',
      employability: 'Forte',
      salary: '500 000 - 1 400 000 FCFA',
      why: 'L’urbanisation accélérée des capitales africaines exige des concepteurs d’espaces modernes et écologiques.',
      isPublished: true,
    },
    {
      slug: 'droit-sciences-politiques',
      title: 'Droit & Sciences Politiques',
      bannerImage: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=1200&q=80',
      description: 'Droit des affaires OHADA, contentieux, relations internationales, magistrature et carrières publiques.',
      growth: '+10% / an',
      employability: 'Moyenne à forte',
      salary: '350 000 - 1 000 000 FCFA',
      why: 'Sécurisation juridique des investissements et encadrement des institutions étatiques.',
      isPublished: true,
    }
  ];

  const domainMap = new Map();

  for (const d of domains) {
    const rows = await sql`
      INSERT INTO explorer_domains (slug, title, banner_image, description, growth, employability, salary, why, is_published)
      VALUES (${d.slug}, ${d.title}, ${d.bannerImage}, ${d.description}, ${d.growth}, ${d.employability}, ${d.salary}, ${d.why}, ${d.isPublished})
      ON CONFLICT (slug) DO UPDATE SET
        title = EXCLUDED.title,
        banner_image = EXCLUDED.banner_image,
        description = EXCLUDED.description,
        growth = EXCLUDED.growth,
        employability = EXCLUDED.employability,
        salary = EXCLUDED.salary,
        why = EXCLUDED.why,
        is_published = EXCLUDED.is_published
      RETURNING id, slug;
    `;
    domainMap.set(rows[0].slug, rows[0].id);
  }
  console.log(`Inserted/Updated ${domains.length} domains.`);

  // 2. Universities & Schools
  const schools = [
    {
      slug: 'ul',
      name: 'Université de Lomé (UL)',
      type: 'Public',
      city: 'Lomé, Togo',
      bannerImage: 'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?auto=format&fit=crop&w=1200&q=80',
      description: 'Fondée en 1970, l’Université de Lomé est la plus grande institution publique d’enseignement supérieur et de recherche du Togo. Elle accueille plus de 60 000 étudiants à travers ses facultés de sciences, de médecine, de droit, d’économie, de lettres et ses grandes écoles d’ingénieurs et technologiques.',
      insertionRate: '86%',
      rating: '4.7',
      reviewsCount: 320,
      facilities: ['Campus de 250 hectares', 'Bibliothèque Universitaire Centrale', 'Laboratoires de recherche agréés', 'Centre Médico-Social', 'Amphithéâtres modernes', 'Terrains omnisports & Gymnase', 'Wi-Fi haut débit'],
      isPublished: true,
    },
    {
      slug: 'universite-de-kara',
      name: 'Université de Kara (UK)',
      type: 'Public',
      city: 'Kara, Togo',
      bannerImage: 'https://images.unsplash.com/photo-1562774053-701939374585?auto=format&fit=crop&w=1200&q=80',
      description: 'Créée en 2004, l’Université de Kara est le grand pôle universitaire du nord du Togo. Reconnue pour son dynamisme pédagogique et ses innovations dans la recherche appliquée, elle forme des cadres hautement qualifiés en sciences de la santé, sciences et techniques, droit et sciences économiques.',
      insertionRate: '85%',
      rating: '4.6',
      reviewsCount: 195,
      facilities: ['Campus universitaire moderne', 'Laboratoires scientifiques équipés', 'Bibliothèque connectée', 'Cités universitaires', 'Restaurant universitaire', 'Centre d’employabilité'],
      isPublished: true,
    },
    {
      slug: 'iai',
      name: 'Institut Africain d’Informatique (IAI - Togo)',
      type: 'Public (Inter-États)',
      city: 'Lomé, Togo',
      bannerImage: 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&w=1200&q=80',
      description: 'Institution intergouvernementale africaine d’excellence créée en 1971 par 11 chefs d’État. L’IAI forme les ingénieurs concepteurs et techniciens supérieurs en informatique, génie logiciel, cybersécurité et intelligence artificielle.',
      insertionRate: '93%',
      rating: '4.8',
      reviewsCount: 160,
      facilities: ['Salles serveurs et machines', 'Laboratoires de développement', 'Centre de certification professionnelle', 'Médiathèque informatique', 'Fibre optique dédiée'],
      isPublished: true,
    },
    {
      slug: 'eamau',
      name: 'École Africaine des Métiers de l’Architecture et de l’Urbanisme (EAMAU)',
      type: 'Public (Inter-États)',
      city: 'Lomé, Togo',
      bannerImage: 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?auto=format&fit=crop&w=1200&q=80',
      description: 'Institution d’élite créée par les chefs d’État de 14 pays d’Afrique francophone, l’EAMAU forme les architectes, urbanistes et gestionnaires urbains de haut niveau façonnant les métropoles africaines durables de demain.',
      insertionRate: '95%',
      rating: '4.9',
      reviewsCount: 140,
      facilities: ['Ateliers d’architecture et de maquettes', 'Laboratoire de modélisation 3D et SIG', 'Médiathèque d’urbanisme', 'Galerie d’expositions', 'Campus international'],
      isPublished: true,
    },
    {
      slug: 'ensi-lome',
      name: 'École Nationale Supérieure d’Ingénieurs (ENSI - UL)',
      type: 'Public',
      city: 'Lomé, Togo',
      bannerImage: 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?auto=format&fit=crop&w=1200&q=80',
      description: 'Grande école d’ingénieurs de l’Université de Lomé, l’ENSI forme les ingénieurs de conception en génie civil, génie électrique, génie mécanique et génie industriel, avec des taux d’embauche remarquables.',
      insertionRate: '92%',
      rating: '4.8',
      reviewsCount: 180,
      facilities: ['Laboratoires de mécanique & thermique', 'Plateforme électrotechnique', 'Laboratoire d’essais géotechniques et BTP', 'Salles CAO/DAO', 'Incubateur technologique'],
      isPublished: true,
    },
    {
      slug: 'ucao-uut',
      name: 'Université Catholique de l’Afrique de l’Ouest (UCAO-UUT)',
      type: 'Confessionnel',
      city: 'Lomé, Togo',
      bannerImage: 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?auto=format&fit=crop&w=1200&q=80',
      description: 'L’Unité Universitaire au Togo de l’UCAO dispense un enseignement supérieur de réputation internationale alliant rigueur scientifique et valeurs éthiques. Elle excelle en droit des affaires, sciences de gestion et technologies numériques.',
      insertionRate: '89%',
      rating: '4.7',
      reviewsCount: 210,
      facilities: ['Campus verdoyant et sécurisé', 'Amphithéâtres climatisés', 'Bibliothèque moderne connectée', 'Centre culturel et spirituel', 'Complexe sportif'],
      isPublished: true,
    },
    {
      slug: 'esa-lome',
      name: 'École Supérieure des Affaires (ESA)',
      type: 'Privé',
      city: 'Lomé, Togo',
      bannerImage: 'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=1200&q=80',
      description: 'Établissement privé d’enseignement supérieur d’élite certifié ISO 9001 version 2015 et accrédité par le CAMES. L’ESA est reconnue pour ses filières en finance, audit, marketing, droit des affaires et transport-logistique.',
      insertionRate: '91%',
      rating: '4.7',
      reviewsCount: 230,
      facilities: ['Campus ultra-moderne', 'Incubateur de startups ESA-Lab', 'Studio audiovisuel', 'Laboratoires informatiques', 'Partenariats entreprises actifs'],
      isPublished: true,
    },
    {
      slug: 'esgis-togo',
      name: 'École Supérieure de Gestion, d’Informatique et des Sciences (ESGIS)',
      type: 'Privé',
      city: 'Lomé, Togo',
      bannerImage: 'https://images.unsplash.com/photo-1531482615713-2afd69097998?auto=format&fit=crop&w=1200&q=80',
      description: 'Pionnière dans la formation aux métiers de l’informatique, des télécoms et du management en Afrique de l’Ouest. ESGIS propose des diplômes reconnus CAMES en génie logiciel, réseaux, cybersécurité et administration des systèmes.',
      insertionRate: '88%',
      rating: '4.6',
      reviewsCount: 175,
      facilities: ['Laboratoires réseaux Cisco', 'Datacenter pédagogique', 'Espaces coworking connectés', 'Centre de certifications', 'Fibre optique haut débit'],
      isPublished: true,
    },
    {
      slug: 'formatec',
      name: 'FORMATEC - Institut Supérieur Polytechnique',
      type: 'Privé',
      city: 'Lomé, Togo',
      bannerImage: 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&w=1200&q=80',
      description: 'Institut polytechnique agréé et reconnu par le CAMES. FORMATEC est une référence au Togo pour la formation d’ingénieurs et techniciens supérieurs en génie civil, architecture, électromécanique et géomatique.',
      insertionRate: '87%',
      rating: '4.5',
      reviewsCount: 145,
      facilities: ['Laboratoire d’essais géotechniques', 'Station d’essais béton et matériaux', 'Équipements topographiques numériques', 'Ateliers mécaniques'],
      isPublished: true,
    },
    {
      slug: 'defitech',
      name: 'DEFITECH - Institut Supérieur de Technologies',
      type: 'Privé',
      city: 'Lomé, Togo',
      bannerImage: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?auto=format&fit=crop&w=1200&q=80',
      description: 'Institut supérieur de technologies spécialisé dans les sciences informatiques, les télécommunications et les systèmes d’information, préparant aux carrières d’administrateurs systèmes et développeurs.',
      insertionRate: '86%',
      rating: '4.5',
      reviewsCount: 130,
      facilities: ['Salles de cours multimédias', 'Laboratoire hardware et réseaux', 'Plateforme e-learning interactive', 'Accès Wi-Fi permanent'],
      isPublished: true,
    },
    {
      slug: 'ipnet-technology',
      name: 'IPNET Institute of Technology',
      type: 'Privé',
      city: 'Lomé, Togo',
      bannerImage: 'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?auto=format&fit=crop&w=1200&q=80',
      description: 'Centre d’excellence technologique certifié Cisco Networking Academy, Microsoft, AWS et Red Hat. IPNET forme les spécialistes des infrastructures cloud, de la cybersécurité offensive et de l’ingénierie réseau.',
      insertionRate: '94%',
      rating: '4.8',
      reviewsCount: 165,
      facilities: ['Laboratoire de Cyber-défense', 'Baies de serveurs et routeurs Cisco', 'Centre d’examen officiel Pearson VUE', 'Postes informatiques haute performance'],
      isPublished: true,
    },
    {
      slug: 'fss-lome',
      name: 'Faculté des Sciences de la Santé (FSS - UL)',
      type: 'Public',
      city: 'Lomé, Togo',
      bannerImage: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=1200&q=80',
      description: 'Composante médicale d’excellence de l’Université de Lomé, formant les futurs médecins, pharmaciens et odontologistes du Togo. Étroitement associée au CHU Sylvanus Olympio et au CHU Campus.',
      insertionRate: '97%',
      rating: '4.9',
      reviewsCount: 280,
      facilities: ['Centres hospitaliers universitaires d’application', 'Salles de dissection anatomique', 'Laboratoire de simulation clinique', 'Bibliothèque médicale spécialisée'],
      isPublished: true,
    },
    {
      slug: 'esam-lome',
      name: 'École Supérieure d’Administration et de Management (ESAM)',
      type: 'Privé',
      city: 'Lomé, Togo',
      bannerImage: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1200&q=80',
      description: 'Grande école de management proposant des cursus reconnus en audit comptable, gestion des ressources humaines, marketing digital et négociation commerciale.',
      insertionRate: '85%',
      rating: '4.4',
      reviewsCount: 110,
      facilities: ['Amphithéâtres modernes', 'Salle des marchés pédagogique', 'Bibliothèque de gestion', 'Connexion internet haut débit'],
      isPublished: true,
    },
    {
      slug: 'cesag',
      name: 'Centre Africain d’Études Supérieures en Gestion (CESAG)',
      type: 'Régional (UEMOA)',
      city: 'Dakar (Zone UEMOA)',
      bannerImage: 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?auto=format&fit=crop&w=1200&q=80',
      description: 'Établissement public international spécialisé dans la formation, la recherche et le conseil en management et finance pour l’ensemble des 8 pays de l’UEMOA. Très prisé par les étudiants togolais.',
      insertionRate: '96%',
      rating: '4.9',
      reviewsCount: 310,
      facilities: ['Campus international d’excellence', 'Salle de marché Bloomberg', 'Bibliothèque centrale africaine', 'Résidences étudiantes standing'],
      isPublished: true,
    },
    {
      slug: '2ie-institut',
      name: 'Institut International d’Ingénierie de l’Eau et de l’Environnement (2iE)',
      type: 'Régional (Afrique)',
      city: 'Ouagadougou (Partenaire Togo)',
      bannerImage: 'https://images.unsplash.com/photo-1497440001374-f26997328c1b?auto=format&fit=crop&w=1200&q=80',
      description: 'Institut d’ingénieurs panafricain de premier plan dans les domaines de l’eau, de l’assainissement, des énergies renouvelables et du génie civil.',
      insertionRate: '93%',
      rating: '4.8',
      reviewsCount: 220,
      facilities: ['Laboratoire d’écotechnologies et biomasse', 'Centrale solaire expérimentale', 'Incubateur d’entrepreneuriat vert', 'Campus écologique'],
      isPublished: true,
    }
  ];

  const schoolMap = new Map();

  for (const s of schools) {
    const rows = await sql`
      INSERT INTO explorer_schools (slug, name, type, city, banner_image, description, insertion_rate, rating, reviews_count, facilities, is_published)
      VALUES (${s.slug}, ${s.name}, ${s.type}, ${s.city}, ${s.bannerImage}, ${s.description}, ${s.insertionRate}, ${s.rating}, ${s.reviewsCount}, ${JSON.stringify(s.facilities)}, ${s.isPublished})
      ON CONFLICT (slug) DO UPDATE SET
        name = EXCLUDED.name,
        type = EXCLUDED.type,
        city = EXCLUDED.city,
        banner_image = EXCLUDED.banner_image,
        description = EXCLUDED.description,
        insertion_rate = EXCLUDED.insertion_rate,
        rating = EXCLUDED.rating,
        reviews_count = EXCLUDED.reviews_count,
        facilities = EXCLUDED.facilities,
        is_published = EXCLUDED.is_published
      RETURNING id, slug;
    `;
    schoolMap.set(rows[0].slug, rows[0].id);
  }
  console.log(`Inserted/Updated ${schools.length} universities & schools.`);

  // 3. Key Programs (Formations) linked to these universities
  const programs = [
    {
      slug: 'ul-genie-logiciel',
      title: 'Licence Professionnelle en Génie Logiciel',
      schoolSlug: 'ul',
      domainSlug: 'tech-numerique',
      bannerImage: 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?auto=format&fit=crop&w=1200&q=80',
      description: 'Formation approfondie en conception logicielle, architectures microservices, développement web fullstack et gestion agile de projets tech.',
      level: 'Licence (Bac+3)',
      duration: '3 ans',
      admission: 'Baccalauréat C, D ou E avec mention, sélection sur dossier et test.',
      status: 'Reconnu CAMES & État togolais',
      programCourses: ['Algorithmique avancée', 'Architecture Web & Mobile', 'Bases de données SQL/NoSQL', 'DevOps & CI/CD', 'Sécurité logicielle'],
      isPublished: true,
    },
    {
      slug: 'iai-ingenieur-systemes',
      title: 'Ingénieur de Conception en Systèmes d’Information',
      schoolSlug: 'iai',
      domainSlug: 'tech-numerique',
      bannerImage: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?auto=format&fit=crop&w=1200&q=80',
      description: 'Cursus d’ingénierie complet formant les architectes logiciels, directeurs de systèmes d’information et spécialistes de la donnée en Afrique.',
      level: 'Master / Ingénieur (Bac+5)',
      duration: '5 ans',
      admission: 'Concours d’entrée sous-régional après Bac scientifique.',
      status: 'Diplôme d’Ingénieur Inter-États CAMES',
      programCourses: ['Intelligence Artificielle', 'Cloud Computing', 'Big Data & Analytics', 'Management des SI', 'Gouvernance IT'],
      isPublished: true,
    },
    {
      slug: 'eamau-diplome-architecte',
      title: 'Diplôme d’Architecte DEIA (Grade Master)',
      schoolSlug: 'eamau',
      domainSlug: 'architecture-urbanisme',
      bannerImage: 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?auto=format&fit=crop&w=1200&q=80',
      description: 'Programme phare formant les architectes africains aux défis bioclimatiques, à la conception moderne et aux matériaux locaux innovants.',
      level: 'Master (Bac+5)',
      duration: '5 ans',
      admission: 'Concours international annuel d’entrée à l’EAMAU (Bacs C, D, E, F).',
      status: 'Diplôme intergouvernemental reconnu CAMES',
      programCourses: ['Théorie du projet architectural', 'Architecture bioclimatique', 'Urbanisme tropical', 'Résistance des matériaux', 'BIM & CAO 3D'],
      isPublished: true,
    },
    {
      slug: 'uk-sciences-economiques',
      title: 'Licence en Sciences Économiques et Gestion',
      schoolSlug: 'universite-de-kara',
      domainSlug: 'gestion-management',
      bannerImage: 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?auto=format&fit=crop&w=1200&q=80',
      description: 'Formation fondamentale et appliquée aux mécanismes économiques, à la gestion financière et à l’analyse des politiques de développement.',
      level: 'Licence (Bac+3)',
      duration: '3 ans',
      admission: 'Baccalauréat A4, C, D ou G2.',
      status: 'Diplôme national reconnu CAMES',
      programCourses: ['Microéconomie & Macroéconomie', 'Comptabilité générale et analytique', 'Statistiques et économétrie', 'Finance d’entreprise'],
      isPublished: true,
    },
    {
      slug: 'ensi-genie-civil',
      title: 'Ingénieur en Génie Civil & BTP',
      schoolSlug: 'ensi-lome',
      domainSlug: 'ingenierie-btp',
      bannerImage: 'https://images.unsplash.com/photo-1541888946425-d0fbb18086f6?auto=format&fit=crop&w=1200&q=80',
      description: 'Conception, calcul de structures, dimensionnement d’ouvrages d’art, routes, ponts et gestion de grands chantiers de construction.',
      level: 'Diplôme d’Ingénieur (Bac+5)',
      duration: '3 ans (après Classes Prépa)',
      admission: 'Concours national d’entrée après Maths Sup/Maths Spé ou Licence scientifique.',
      status: 'Habilité par l’État togolais & CAMES',
      programCourses: ['Béton armé & précontraint', 'Mécanique des sols', 'Calcul des structures', 'Hydraulique appliquée', 'Management de chantiers'],
      isPublished: true,
    },
    {
      slug: 'ucao-droit-affaires',
      title: 'Master en Droit des Affaires & Fiscalité OHADA',
      schoolSlug: 'ucao-uut',
      domainSlug: 'droit-sciences-politiques',
      bannerImage: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=1200&q=80',
      description: 'Spécialisation juridique de référence pour le conseil d’entreprise, la fiscalité sous-régionale, les contrats internationaux et le contentieux commercial.',
      level: 'Master (Bac+5)',
      duration: '2 ans',
      admission: 'Licence en Droit public ou privé avec avis favorable de la commission.',
      status: 'Reconnu CAMES',
      programCourses: ['Droit des sociétés OHADA', 'Droit bancaire et financier', 'Fiscalité des entreprises', 'Arbitrage international', 'Droit du travail'],
      isPublished: true,
    },
    {
      slug: 'esa-finance-banque',
      title: 'Licence Pro Banque, Finance & Assurance',
      schoolSlug: 'esa-lome',
      domainSlug: 'gestion-management',
      bannerImage: 'https://images.unsplash.com/photo-1559526324-4b87b5e36e44?auto=format&fit=crop&w=1200&q=80',
      description: 'Préparation intensive aux métiers opérationnels de la banque commerciale, de la gestion de patrimoine et des compagnies d’assurance.',
      level: 'Licence (Bac+3)',
      duration: '3 ans',
      admission: 'Baccalauréat toutes séries, étude de dossier.',
      status: 'Certifié ISO 9001 & CAMES',
      programCourses: ['Techniques bancaires', 'Analyse financière', 'Gestion des risques de crédit', 'Marchés de capitaux', 'Droit des assurances'],
      isPublished: true,
    },
    {
      slug: 'fss-doctorat-medecine',
      title: 'Doctorat d’État en Médecine Générale',
      schoolSlug: 'fss-lome',
      domainSlug: 'sciences-sante',
      bannerImage: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=1200&q=80',
      description: 'Formation médicale complète combinant cours magistraux théoriques, stages hospitaliers intensifs et internat en milieu clinique.',
      level: 'Doctorat d’État (Bac+8)',
      duration: '8 ans',
      admission: 'Bac C ou D avec excellente moyenne, sélection très rigoureuse.',
      status: 'Reconnu par l’Ordre National des Médecins du Togo & CAMES',
      programCourses: ['Anatomie humaine', 'Pharmacologie clinique', 'Sémiologie médicale', 'Chirurgie générale', 'Pédiatrie & Santé publique'],
      isPublished: true,
    },
    {
      slug: 'ipnet-cybersecurite',
      title: 'Expert en Cybersécurité & Cloud Computing',
      schoolSlug: 'ipnet-technology',
      domainSlug: 'tech-numerique',
      bannerImage: 'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?auto=format&fit=crop&w=1200&q=80',
      description: 'Parcours certifiant de pointe pour auditer la sécurité des systèmes d’information, concevoir des architectures cloud résilientes et parer aux cyberattaques.',
      level: 'Bachelor / Master Pro',
      duration: '3 ans',
      admission: 'Bac scientifique ou technique, test d’aptitude logique et informatique.',
      status: 'Certifications professionnelles internationales Cisco/AWS/CEH incluses',
      programCourses: ['Ethical Hacking & Pentest', 'Sécurité réseau Cisco CCNP', 'Architecture AWS Cloud', 'Cryptographie appliquée', 'Gestion des incidents (SOC)'],
      isPublished: true,
    }
  ];

  for (const p of programs) {
    const schoolId = schoolMap.get(p.schoolSlug);
    const domainId = domainMap.get(p.domainSlug);

    if (!schoolId || !domainId) {
      console.warn(`Skipping program ${p.slug}: missing school or domain ID`);
      continue;
    }

    await sql`
      INSERT INTO explorer_programs (slug, title, school_id, domain_id, banner_image, description, level, duration, admission, status, program_courses, is_published)
      VALUES (${p.slug}, ${p.title}, ${schoolId}, ${domainId}, ${p.bannerImage}, ${p.description}, ${p.level}, ${p.duration}, ${p.admission}, ${p.status}, ${JSON.stringify(p.programCourses)}, ${p.isPublished})
      ON CONFLICT (slug) DO UPDATE SET
        title = EXCLUDED.title,
        school_id = EXCLUDED.school_id,
        domain_id = EXCLUDED.domain_id,
        banner_image = EXCLUDED.banner_image,
        description = EXCLUDED.description,
        level = EXCLUDED.level,
        duration = EXCLUDED.duration,
        admission = EXCLUDED.admission,
        status = EXCLUDED.status,
        program_courses = EXCLUDED.program_courses,
        is_published = EXCLUDED.is_published;
    `;
  }
  console.log(`Inserted/Updated ${programs.length} accredited programs.`);

  console.log("Seeding completed successfully!");
  await sql.end();
}

main().catch(err => {
  console.error("Seeding error:", err);
  process.exit(1);
});
