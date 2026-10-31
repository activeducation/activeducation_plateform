const postgres = require('postgres');
require('dotenv').config({ path: 'web/.env.local' });

if (!process.env.DATABASE_URL) {
  console.error("DATABASE_URL is missing in web/.env.local");
  process.exit(1);
}

const sql = postgres(process.env.DATABASE_URL);

async function main() {
  console.log("Adding specialized Togolese programs & links...");

  // Resolve schools
  const schools = await sql`SELECT id, slug FROM explorer_schools`;
  const schoolMap = new Map();
  schools.forEach(s => schoolMap.set(s.slug, s.id));

  // Resolve domains
  const domains = await sql`SELECT id, slug FROM explorer_domains`;
  const domainMap = new Map();
  domains.forEach(d => domainMap.set(d.slug, d.id));

  // Additional programs
  const newPrograms = [
    {
      slug: 'fss-doctorat-pharmacie',
      title: 'Doctorat d’État en Pharmacie',
      schoolSlug: schoolMap.has('fss-ul') ? 'fss-ul' : 'ul',
      domainSlug: 'sciences-sante',
      bannerImage: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=1200&q=80',
      description: 'Formation médicale d’excellence préparant aux métiers de pharmacien d’officine, pharmacien hospitalier, biologiste médical et spécialiste de l’industrie pharmaceutique.',
      level: 'Doctorat d’État (Bac+6)',
      duration: '6 ans',
      admission: 'Bac scientifique C ou D avec mention, sélection très rigoureuse sur dossier et concours.',
      status: 'Diplôme d’État reconnu CAMES & Ordre National des Pharmaciens du Togo',
      programCourses: ['Pharmacologie clinique', 'Chimie thérapeutique', 'Toxicologie & galénique', 'Biochimie médicale', 'Gestion d’officine & législation'],
      isPublished: true,
      careerSlugs: ['pharmacien-officine-industriel']
    },
    {
      slug: 'ul-droit-international-diplomatie',
      title: 'Licence & Master en Droit Public & Relations Internationales',
      schoolSlug: 'ul',
      domainSlug: 'droit-sciences-politiques',
      bannerImage: 'https://images.unsplash.com/photo-1521791136064-7986c2920216?auto=format&fit=crop&w=1200&q=80',
      description: 'Cursus d’excellence en diplomatie, droit international public, gouvernance des organisations régionales (CEDEAO, UEMOA, UA) et négociation internationale.',
      level: 'Master (Bac+5)',
      duration: '5 ans (Licence 3 ans + Master 2 ans)',
      admission: 'Bac A4, C ou D. Sélection sur dossier pour le cycle Master.',
      status: 'Diplôme national reconnu CAMES',
      programCourses: ['Droit international public', 'Relations internationales & géopolitique', 'Droit communautaire UEMOA/CEDEAO', 'Pratique diplomatique & protocole', 'Négociation multilatérale'],
      isPublished: true,
      careerSlugs: ['diplomate-charge-cooperation']
    },
    {
      slug: 'ensi-electromecanique',
      title: 'Ingénieur en Génie Électrique & Électromécanique',
      schoolSlug: schoolMap.has('ensi-lome') ? 'ensi-lome' : 'ul',
      domainSlug: 'ingenierie-btp',
      bannerImage: 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?auto=format&fit=crop&w=1200&q=80',
      description: 'Formation de pointe préparant les ingénieurs aux automatismes industriels, à la maintenance des centrales, à la robotique et aux réseaux de distribution électrique haute tension.',
      level: 'Diplôme d’Ingénieur (Bac+5)',
      duration: '5 ans',
      admission: 'Bac C, D, E ou F sur concours national d’entrée à l’ENSI.',
      status: 'Diplôme d’Ingénieur reconnu CAMES & Ordre des Ingénieurs du Togo (ONIT)',
      programCourses: ['Électrotechnique & machines électriques', 'Automates programmables (PLC/SCADA)', 'Électronique de puissance', 'Régulation industrielle', 'Maintenance prédictive'],
      isPublished: true,
      careerSlugs: ['ingenieur-electromecanicien-automatismes']
    },
    {
      slug: 'ensi-energies-renouvelables',
      title: 'Master & Ingénieur en Énergies Renouvelables & Systèmes Solaires',
      schoolSlug: schoolMap.has('ensi-lome') ? 'ensi-lome' : 'ul',
      domainSlug: 'ingenierie-btp',
      bannerImage: 'https://images.unsplash.com/photo-1509391365360-2e959784a276?auto=format&fit=crop&w=1200&q=80',
      description: 'Programme dédié à la transition énergétique en Afrique de l’Ouest : dimensionnement de parcs photovoltaïques, efficacité énergétique des bâtiments et centrales hybrides.',
      level: 'Master / Ingénieur (Bac+5)',
      duration: '2 ans après Licence scientifique / 5 ans',
      admission: 'Bac scientifique C, D, E ou Licence en Physique/Électrotechnique.',
      status: 'Reconnu CAMES & Partenaires internationaux',
      programCourses: ['Systèmes photovoltaïques & stockage', 'Thermique solaire', 'Audit et efficacité énergétique', 'Réseaux intelligents (Smart Grids)', 'Financement de projets verts'],
      isPublished: true,
      careerSlugs: ['ingenieur-energies-renouvelables']
    },
    {
      slug: 'esa-logistique-portuaire',
      title: 'Licence Professionnelle Logistique, Transport & Transit Portuaire',
      schoolSlug: schoolMap.has('esa-lome') ? 'esa-lome' : 'esa',
      domainSlug: 'gestion-management',
      bannerImage: 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&w=1200&q=80',
      description: 'Formation professionnalisante axée sur les opérations du Port Autonome de Lomé (PAL) : gestion des flux maritimes, dédouanement Sydonia World, fret aérien et chaîne d’approvisionnement.',
      level: 'Licence Pro (Bac+3)',
      duration: '3 ans',
      admission: 'Baccalauréat toutes séries (priorité G2, D, C). Sélection sur dossier.',
      status: 'Diplôme agréé CAMES & Partenariat Port Autonome de Lomé',
      programCourses: ['Gestion portuaire & maritime', 'Procédures douanières & Sydonia', 'Supply Chain Management', 'Droit des transports', 'Anglais logistique & maritime'],
      isPublished: true,
      careerSlugs: ['manager-supply-chain-logistique-portuaire']
    },
    {
      slug: 'fss-maintenance-biomedicale',
      title: 'Licence & Master Professionnel en Génie Biomédical',
      schoolSlug: schoolMap.has('fss-ul') ? 'fss-ul' : 'ul',
      domainSlug: 'sciences-sante',
      bannerImage: 'https://images.unsplash.com/photo-1516549655169-df83a0774514?auto=format&fit=crop&w=1200&q=80',
      description: 'Formation combinant médecine et ingénierie : maintenance des scanners, IRM, respirateurs, monitoring hospitalier et gestion des plateaux techniques des CHU.',
      level: 'Licence Pro (Bac+3)',
      duration: '3 ans',
      admission: 'Bac C, D, E ou F.',
      status: 'Programme universitaire accrédité CAMES',
      programCourses: ['Électronique médicale & capteurs', 'Imagerie médicale (IRM, Scanner, Radio)', 'Normes et sécurité hospitalière', 'Maintenance préventive des dispositifs médicaux', 'Biophysique'],
      isPublished: true,
      careerSlugs: ['ingenieur-biomedical']
    }
  ];

  for (const prog of newPrograms) {
    const schoolId = schoolMap.get(prog.schoolSlug) || schoolMap.get('ul');
    const domainId = domainMap.get(prog.domainSlug);

    if (!schoolId || !domainId) {
      console.warn(`Could not resolve schoolId (${prog.schoolSlug}) or domainId (${prog.domainSlug}) for ${prog.slug}`);
      continue;
    }

    const insertedProg = await sql`
      INSERT INTO explorer_programs (
        slug, title, school_id, domain_id, banner_image, description, 
        level, duration, admission, status, program_courses, is_published
      )
      VALUES (
        ${prog.slug}, ${prog.title}, ${schoolId}, ${domainId}, ${prog.bannerImage}, ${prog.description},
        ${prog.level}, ${prog.duration}, ${prog.admission}, ${prog.status}, ${JSON.stringify(prog.programCourses)}, ${prog.isPublished}
      )
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
        is_published = EXCLUDED.is_published
      RETURNING id, slug;
    `;

    const programId = insertedProg[0].id;
    console.log(`Inserted/Updated program: ${prog.title} (ID: ${programId})`);

    // Link to careers
    for (const cSlug of prog.careerSlugs) {
      const careerRows = await sql`SELECT id, title FROM explorer_careers WHERE slug = ${cSlug}`;
      if (careerRows.length > 0) {
        const careerId = careerRows[0].id;
        await sql`
          INSERT INTO explorer_career_programs (career_id, program_id)
          VALUES (${careerId}, ${programId})
          ON CONFLICT (career_id, program_id) DO NOTHING
        `;
        console.log(` -> Linked "${prog.title}" to career "${careerRows[0].title}"`);
      }
    }
  }

  console.log("Done adding specialized programs & links!");
  await sql.end();
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
