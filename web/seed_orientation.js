const postgres = require('postgres');
require('dotenv').config({ path: '.env.local' });

const sql = postgres(process.env.DATABASE_URL, { max: 1 });

async function seed() {
  try {
    console.log('Seeding domains...');
    const domains = await sql`
      INSERT INTO explorer_domains (slug, title, banner_image, description, growth, employability, salary, why, is_published)
      VALUES (
        'tech-numerique',
        'Tech & Numérique',
        'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=1200&q=80',
        'Le secteur du numérique est le moteur de la transformation au Togo et en Afrique. De la création d''applications à la protection des données, en passant par l''intelligence artificielle, ce secteur offre des opportunités de carrière exceptionnelles, d''innovation et d''entrepreneuriat.',
        '+15% / an',
        'Très forte',
        'Élevé',
        'Le gouvernement togolais a pour ambition de faire du pays un hub technologique sous-régional. Le déploiement de la fibre optique et la digitalisation des services publics créent un besoin massif en talents qualifiés.',
        true
      ) RETURNING id;
    `;
    const techDomainId = domains[0].id;

    console.log('Seeding schools...');
    const schools = await sql`
      INSERT INTO explorer_schools (slug, name, type, city, banner_image, description, insertion_rate, rating, reviews_count, is_published)
      VALUES (
        'ul',
        'Université de Lomé (UL)',
        'Public',
        'Lomé, Togo',
        'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?auto=format&fit=crop&w=1200&q=80',
        'Créée en 1970, l''Université de Lomé est le plus grand pôle d''enseignement supérieur et de recherche du Togo.',
        '72%',
        '4.1',
        1245,
        true
      ),
      (
        'iai',
        'Institut Africain d''Informatique (IAI)',
        'Public (Inter-États)',
        'Lomé, Togo',
        'https://images.unsplash.com/photo-1562774053-701939374585?auto=format&fit=crop&w=1200&q=80',
        'L''IAI est une école inter-États qui forme les meilleurs ingénieurs informaticiens d''Afrique.',
        '95%',
        '4.8',
        850,
        true
      )
      RETURNING id, slug;
    `;
    const ulId = schools.find(s => s.slug === 'ul').id;
    const iaiId = schools.find(s => s.slug === 'iai').id;

    console.log('Seeding programs...');
    await sql`
      INSERT INTO explorer_programs (slug, title, school_id, domain_id, level, duration, is_published)
      VALUES 
      ('ul-cyber', 'Licence Pro Sécurité Informatique', ${ulId}, ${techDomainId}, 'Bac+3', '3 ans', true),
      ('iai-genie', 'Génie Logiciel', ${iaiId}, ${techDomainId}, 'Bac+3 / Bac+5', '3 à 5 ans', true)
    `;

    console.log('Seeding careers...');
    await sql`
      INSERT INTO explorer_careers (slug, title, domain_id, is_published)
      VALUES 
      ('cybersecurite', 'Ingénieur Cybersécurité', ${techDomainId}, true),
      ('data-analyst', 'Data Analyst', ${techDomainId}, true),
      ('dev-mobile', 'Développeur Mobile', ${techDomainId}, true)
    `;

    console.log('Seed completed.');
  } catch (err) {
    console.error(err);
  } finally {
    await sql.end();
  }
}

seed();
