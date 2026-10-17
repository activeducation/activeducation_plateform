const postgres = require('postgres');
require('dotenv').config({ path: '.env.local' });

if (!process.env.DATABASE_URL) {
  console.error("DATABASE_URL is missing in .env.local");
  process.exit(1);
}

const sql = postgres(process.env.DATABASE_URL);

async function main() {
  console.log("Starting seed for rich careers (métiers)...");

  // Fetch all existing domains to resolve IDs
  const domains = await sql`SELECT id, slug, title FROM explorer_domains`;
  const domainMap = new Map();
  domains.forEach(d => domainMap.set(d.slug, d.id));

  // Fetch all existing programs to link to careers
  const programs = await sql`SELECT id, slug, title FROM explorer_programs`;
  const programMap = new Map();
  programs.forEach(p => programMap.set(p.slug, p.id));

  const careers = [
    // --- TECH & NUMERIQUE ---
    {
      slug: 'cybersecurite',
      title: 'Ingénieur Cybersécurité',
      domainSlug: 'tech-numerique',
      bannerImage: 'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?auto=format&fit=crop&w=1200&q=80',
      description: 'L’ingénieur en cybersécurité protège les systèmes d’information, les réseaux d’entreprises et les données confidentielles contre les intrusions, le rançongiciel et les cybermenaces sophistiquées.',
      skills: ['Cryptographie & protocoles sécurisés', 'Sécurité des réseaux (Firewalls, VPN, IPS)', 'Tests d’intrusion (Pentest éthique)', 'Gestion des incidents de sécurité (SOC/SIEM)', 'Conformité ISO 27001 & RGPD'],
      opportunities: ['Analyste SOC', 'Consultant Cybersécurité', 'Responsable de la Sécurité des Systèmes d’Information (RSSI)', 'Auditeur sécurité'],
      linkedPrograms: ['ipnet-cybersecurite', 'iai-ingenieur-systemes'],
      isPublished: true,
    },
    {
      slug: 'ingenieur-cloud-devops',
      title: 'Ingénieur Cloud & DevOps',
      domainSlug: 'tech-numerique',
      bannerImage: 'https://images.unsplash.com/photo-1544197150-b99a580bb7a8?auto=format&fit=crop&w=1200&q=80',
      description: 'Concepteur d’infrastructures modernes, il automatise le déploiement applicatif, optimise les conteneurs et garantit la haute disponibilité des services dans les clouds publics et privés.',
      skills: ['Docker & Kubernetes', 'Pipelines CI/CD (GitHub Actions, GitLab CI)', 'Infrastructures Cloud (AWS, Azure, GCP)', 'Linux & Scripting Shell/Python', 'Terraform & Infrastructure-as-Code (IaC)', 'Supervision & Prometheus/Grafana'],
      opportunities: ['Architecte Cloud', 'Site Reliability Engineer (SRE)', 'Lead DevOps Engineer', 'Consultant Transformation Digitale'],
      linkedPrograms: ['ul-genie-logiciel', 'iai-ingenieur-systemes', 'ipnet-cybersecurite'],
      isPublished: true,
    },
    {
      slug: 'developpeur-fullstack',
      title: 'Développeur Fullstack Web & Mobile',
      domainSlug: 'tech-numerique',
      bannerImage: 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&w=1200&q=80',
      description: 'Maîtrisant le front-end et le back-end, il conçoit des applications modernes, réactives et performantes adaptées aux terminaux web et mobiles en Afrique et à l’international.',
      skills: ['JavaScript & TypeScript', 'React.js / Next.js', 'Node.js & Express / NestJS', 'PostgreSQL & Drizzle ORM', 'Développement Mobile (React Native / Flutter)', 'API RESTful & GraphQL'],
      opportunities: ['Tech Lead Développeur', 'Ingénieur Logiciel Fullstack', 'Développeur Mobile Spécialisé', 'Directeur Technique (CTO)'],
      linkedPrograms: ['ul-genie-logiciel', 'iai-ingenieur-systemes'],
      isPublished: true,
    },
    {
      slug: 'data-scientist-ia',
      title: 'Expert IA & Data Scientist',
      domainSlug: 'tech-numerique',
      bannerImage: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?auto=format&fit=crop&w=1200&q=80',
      description: 'Spécialiste de la valorisation des données massives, il crée des modèles prédictifs et intègre des algorithmes d’intelligence artificielle pour optimiser la prise de décision stratégique.',
      skills: ['Python scientifique (Pandas, NumPy, Scikit-learn)', 'Apprentissage automatique (Machine Learning / Deep Learning)', 'Traitement automatique du langage naturel (NLP / LLM)', 'SQL avancé & data pipelines', 'Tableaux de bord (Power BI, Streamlit)'],
      opportunities: ['Data Scientist Senior', 'Machine Learning Engineer', 'Consultant Big Data', 'Chief Data Officer'],
      linkedPrograms: ['iai-ingenieur-systemes'],
      isPublished: true,
    },

    // --- SANTE & SCIENCES MEDICALES ---
    {
      slug: 'medecin-generaliste',
      title: 'Médecin Généraliste',
      domainSlug: 'sciences-sante',
      bannerImage: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&w=1200&q=80',
      description: 'Praticien de premier recours et pivot du système de soins, il assure le diagnostic, le traitement des pathologies courantes et la prévention auprès des populations dans les structures de santé.',
      skills: ['Diagnostic clinique rigoureux', 'Gestes d’urgence médicale', 'Pharmacologie & prescription raisonnée', 'Communication empathique soignant-patient', 'Sensibilisation & santé communautaire'],
      opportunities: ['Médecin en centre hospitalier public', 'Praticien en clinique privée', 'Médecin coordonnateur de programmes humanitaires (ONG)', 'Médecin conseil en entreprise'],
      linkedPrograms: ['fss-doctorat-medecine'],
      isPublished: true,
    },
    {
      slug: 'pharmacien',
      title: 'Pharmacien d’Officine & Industriel',
      domainSlug: 'sciences-sante',
      bannerImage: 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?auto=format&fit=crop&w=1200&q=80',
      description: 'Expert incontournable des médicaments et dispositifs médicaux, il valide les prescriptions, conseille la patientèle et supervise le contrôle qualité des produits de santé.',
      skills: ['Pharmacologie & pharmacocinétique', 'Conseil pharmaceutique & éducation thérapeutique', 'Gestion d’officine & gestion des stocks', 'Contrôle qualité & bonnes pratiques de fabrication', 'Législation pharmaceutique'],
      opportunities: ['Pharmacien titulaire d’officine', 'Pharmacien hospitalier', 'Responsable production en industrie pharmaceutique', 'Délégué médical'],
      linkedPrograms: ['fss-doctorat-medecine'],
      isPublished: true,
    },
    {
      slug: 'ingenieur-biomedical',
      title: 'Ingénieur Biomédical',
      domainSlug: 'sciences-sante',
      bannerImage: 'https://images.unsplash.com/photo-1516549655169-df83a0774514?auto=format&fit=crop&w=1200&q=80',
      description: 'À la croisée de la médecine et de l’ingénierie, il gère l’acquisition, l’installation, l’étalonnage et la maintenance de pointe des équipements hospitaliers (scanners, respirateurs, blocs opératoires).',
      skills: ['Électronique & imagerie médicale', 'Maintenance des dispositifs d’anesthésie-réanimation', 'Sécurité électrique & rayonnements ionisants', 'Management de parc d’équipements biomédicaux', 'Négociation avec les fabricants internationaux'],
      opportunities: ['Ingénieur biomédical hospitalier', 'Ingénieur d’application équipementier', 'Responsable SAV dispositifs médicaux', 'Auditeur qualité en santé'],
      linkedPrograms: ['fss-doctorat-medecine', 'ensi-genie-civil'],
      isPublished: true,
    },

    // --- INGENIERIE, BTP & INDUSTRIE ---
    {
      slug: 'ingenieur-genie-civil',
      title: 'Ingénieur Génie Civil & BTP',
      domainSlug: 'ingenierie-btp',
      bannerImage: 'https://images.unsplash.com/photo-1541888946425-d0fbb18086f6?auto=format&fit=crop&w=1200&q=80',
      description: 'Pilote de grands chantiers d’infrastructures (routes, ponts, échangeurs, édifices commerciaux et logements), il réalise le dimensionnement technique et garantit la conformité et la sécurité des réalisations.',
      skills: ['Calculs de structures (Béton armé, charpente métallique)', 'Mécanique des sols & fondations profondes', 'Logiciels de CAO/DAO (AutoCAD, Robot Structural Analysis)', 'Planification & pilotage de chantiers (MS Project)', 'Gestion des coûts et devis quantitatifs estimatifs'],
      opportunities: ['Directeur de travaux BTP', 'Ingénieur en bureau d’études techniques', 'Chef de projet infrastructures étatiques', 'Contrôleur technique de construction'],
      linkedPrograms: ['ensi-genie-civil'],
      isPublished: true,
    },
    {
      slug: 'ingenieur-energies-renouvelables',
      title: 'Ingénieur Énergies Renouvelables',
      domainSlug: 'ingenierie-btp',
      bannerImage: 'https://images.unsplash.com/photo-1509391365360-2e959784a276?auto=format&fit=crop&w=1200&q=80',
      description: 'Au premier plan de l’autonomie énergétique en Afrique, il conçoit et installe des centrales solaires photovoltaïques, des mini-réseaux ruraux et conduit des audits énergétiques industriels.',
      skills: ['Dimensionnement photovoltaïque (PVSyst, AutoCAD)', 'Réseaux électriques basse & moyenne tension', 'Systèmes de stockage d’énergie par batteries', 'Audits d’efficacité énergétique', 'Études d’impact environnemental'],
      opportunities: ['Chef de projet centrales solaires', 'Ingénieur d’études énergétiques', 'Responsable technique mini-grids ruraux', 'Conseiller en transition écologique'],
      linkedPrograms: ['ensi-genie-civil'],
      isPublished: true,
    },
    {
      slug: 'ingenieur-electromecanicien',
      title: 'Ingénieur Électromécanicien & Automatismes',
      domainSlug: 'ingenierie-btp',
      bannerImage: 'https://images.unsplash.com/photo-1581092335397-9583fe92d232?auto=format&fit=crop&w=1200&q=80',
      description: 'Expert des systèmes industriels automatisés, il assure la conception et la maintenance préventive des machines, moteurs, convoyeurs et installations portuaires hautement sollicitées.',
      skills: ['Programmation d’automates (Siemens, Schneider Electric)', 'Électrotechnique de puissance & variateurs', 'Hydraulique & pneumatique industrielle', 'Maintenance prédictive & GMAO', 'Sécurité industrielle & normes HSE'],
      opportunities: ['Responsable maintenance usine', 'Ingénieur automatismes & robotique', 'Superviseur technique installations portuaires', 'Directeur technique industrie manufacturière'],
      linkedPrograms: ['ensi-genie-civil'],
      isPublished: true,
    },

    // --- ARCHITECTURE & URBANISME ---
    {
      slug: 'architecte-deia',
      title: 'Architecte D.E.I.A.',
      domainSlug: 'architecture-urbanisme',
      bannerImage: 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?auto=format&fit=crop&w=1200&q=80',
      description: 'Concepteur passionné de l’espace habité, il invente des projets architecturaux modernes, bioclimatiques et ancrés dans les réalités africaines, de l’esquisse jusqu’à la livraison du chantier.',
      skills: ['Conception créative du projet architectural', 'Modélisation BIM 3D (ArchiCAD, Revit, SketchUp)', 'Rendu visuel photo-réaliste (Lumion, V-Ray)', 'Architecture bioclimatique & matériaux locaux', 'Coordination de chantier & suivi de conformité'],
      opportunities: ['Architecte libéral fondateur d’agence', 'Architecte en chef dans de grands cabinets internationaux', 'Conseiller technique ministériel', 'Architecte paysagiste ou scénographe'],
      linkedPrograms: ['eamau-diplome-architecte'],
      isPublished: true,
    },
    {
      slug: 'urbaniste',
      title: 'Urbaniste & Aménageur du Territoire',
      domainSlug: 'architecture-urbanisme',
      bannerImage: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1200&q=80',
      description: 'Stratège du développement des villes africaines, il organise l’espace public, planifie l’extension urbaine durable et optimise les réseaux de transports pour désengorger les capitales.',
      skills: ['Systèmes d’Information Géographique (QGIS, ArcGIS)', 'Élaboration de Schémas Directeurs d’Aménagement Urbain (SDAU)', 'Mobilité urbaine durable & voirie', 'Sociologie urbaine & concertation citoyenne', 'Droit de l’urbanisme & gestion foncière'],
      opportunities: ['Directeur des services urbains en municipalité', 'Chargé d’études aménagement du territoire', 'Consultant auprès d’agences de développement (AFD, Banque Mondiale)', 'Expert en politique du logement'],
      linkedPrograms: ['eamau-diplome-architecte'],
      isPublished: true,
    },

    // --- GESTION, FINANCE & AUDIT ---
    {
      slug: 'analyste-financier',
      title: 'Analyste Financier & Gestionnaire de Risques',
      domainSlug: 'gestion-management',
      bannerImage: 'https://images.unsplash.com/photo-1590283603385-17ffb3a7f29f?auto=format&fit=crop&w=1200&q=80',
      description: 'Évalue la rentabilité et les perspectives économiques des entreprises, élabore des modèles de valorisation financière et éclaire les décisions stratégiques d’investissement.',
      skills: ['Modélisation financière avancée (Excel)', 'Analyse des états financiers SYSCOHADA & IFRS', 'Méthodes de valorisation (DCF, multiples)', 'Évaluation du risque de crédit & scoring', 'Connaissance des marchés de la zone UEMOA / BRVM'],
      opportunities: ['Analyste financier en banque d’investissement', 'Gestionnaire de fonds de capital-investissement', 'Responsable du contrôle de gestion', 'Directeur Financier adjoint'],
      linkedPrograms: ['esa-finance-banque', 'uk-sciences-economiques'],
      isPublished: true,
    },
    {
      slug: 'auditeur-comptable',
      title: 'Auditeur Comptable & Financier',
      domainSlug: 'gestion-management',
      bannerImage: 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?auto=format&fit=crop&w=1200&q=80',
      description: 'Garant de la transparence financière, il examine avec rigueur les comptes annuels des sociétés, vérifie la conformité fiscale et formule des recommandations de gouvernance interne.',
      skills: ['Normes d’audit internationales (ISA)', 'Référentiel comptable SYSCOHADA révisé', 'Fiscalité des entreprises au Togo', 'Contrôle interne & cartographie des risques', 'Techniques d’échantillonnage & revue analytique'],
      opportunities: ['Auditeur senior en cabinet international', 'Directeur de l’audit interne d’une banque', 'Expert-comptable libéral', 'Contrôleur de gestion groupe'],
      linkedPrograms: ['esa-finance-banque', 'uk-sciences-economiques'],
      isPublished: true,
    },
    {
      slug: 'manager-supply-chain',
      title: 'Manager Supply Chain & Logistique Portuaire',
      domainSlug: 'gestion-management',
      bannerImage: 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&w=1200&q=80',
      description: 'Poste stratégique au Togo, plateforme maritime régionale avec le Port Autonome de Lomé. Il optimise la chaîne logistique, le transport multimodal de marchandises et le transit international.',
      skills: ['Gestion des opérations de fret & logistique maritime', 'Réglementation douanière & transit (Incoterms 2020)', 'Systèmes d’information logistique (ERP / WMS)', 'Négociation transporteurs & compagnies maritimes', 'Pilotage d’entrepôts & supply chain durable'],
      opportunities: ['Directeur des opérations logistiques', 'Directeur d’agence maritime de consignation', 'Responsable transit & douanes d’une multinationale', 'Consultant Supply Chain'],
      linkedPrograms: ['esa-finance-banque', 'uk-sciences-economiques'],
      isPublished: true,
    },

    // --- DROIT & SCIENCES POLITIQUES ---
    {
      slug: 'juriste-affaires-ohada',
      title: 'Juriste d’Affaires OHADA',
      domainSlug: 'droit-sciences-politiques',
      bannerImage: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=1200&q=80',
      description: 'Conseil stratégique des dirigeants, il sécurise l’ensemble des opérations commerciales, rédige les conventions contractuelles complexes et gère les litiges conformément au droit OHADA.',
      skills: ['Droit des sociétés & des sûretés OHADA', 'Rédaction et négociation de contrats commerciaux', 'Droit du travail & négociation sociale', 'Contentieux d’affaires & arbitrage international', 'Veille juridique & mise en conformité'],
      opportunities: ['Directeur Juridique d’entreprise', 'Avocat d’affaires au Barreau', 'Juriste d’établissement bancaire', 'Conseiller juridique de fonds d’investissement'],
      linkedPrograms: ['ucao-droit-affaires'],
      isPublished: true,
    },
    {
      slug: 'diplomate-relations-internationales',
      title: 'Diplomate & Chargé de Coopération',
      domainSlug: 'droit-sciences-politiques',
      bannerImage: 'https://images.unsplash.com/photo-1541872703-74c5e44368f9?auto=format&fit=crop&w=1200&q=80',
      description: 'Représentant officiel de l’État ou des institutions sous-régionales (CEDEAO, UEMOA, UA), il défend les intérêts diplomatiques et économiques du pays et négocie les conventions de coopération.',
      skills: ['Négociation internationale & traités multilatéraux', 'Droit international public & diplomatique', 'Géopolitique contemporaine & relations bilatérales', 'Communication protocolaire & plaidoyer', 'Maîtrise bilingue approfondie'],
      opportunities: ['Conseiller diplomatique en ambassade', 'Chargé de mission dans une agence onusienne', 'Directeur de la coopération internationale', 'Analyste géopolitique'],
      linkedPrograms: ['ucao-droit-affaires'],
      isPublished: true,
    }
  ];

  for (const c of careers) {
    const domainId = domainMap.get(c.domainSlug);
    if (!domainId) {
      console.warn(`Skipping career ${c.slug}: domain ${c.domainSlug} not found`);
      continue;
    }

    const insertedRows = await sql`
      INSERT INTO explorer_careers (slug, title, domain_id, banner_image, description, skills, opportunities, is_published)
      VALUES (${c.slug}, ${c.title}, ${domainId}, ${c.bannerImage}, ${c.description}, ${JSON.stringify(c.skills)}, ${JSON.stringify(c.opportunities)}, ${c.isPublished})
      ON CONFLICT (slug) DO UPDATE SET
        title = EXCLUDED.title,
        domain_id = EXCLUDED.domain_id,
        banner_image = EXCLUDED.banner_image,
        description = EXCLUDED.description,
        skills = EXCLUDED.skills,
        opportunities = EXCLUDED.opportunities,
        is_published = EXCLUDED.is_published
      RETURNING id, slug;
    `;

    const careerId = insertedRows[0].id;

    // Link to accredited programs
    if (c.linkedPrograms && c.linkedPrograms.length > 0) {
      for (const progSlug of c.linkedPrograms) {
        const progId = programMap.get(progSlug);
        if (progId) {
          await sql`
            INSERT INTO explorer_career_programs (career_id, program_id)
            VALUES (${careerId}, ${progId})
            ON CONFLICT (career_id, program_id) DO NOTHING;
          `;
        }
      }
    }
  }

  console.log(`Inserted/Updated ${careers.length} comprehensive careers (métiers).`);
  await sql.end();
}

main().catch(err => {
  console.error("Career seeding error:", err);
  process.exit(1);
});
