-- =============================================================================
-- Seed: Ecoles et Universites du Togo (donnees enrichies)
-- Executez la migration 004_enrich_schools.sql AVANT ce seed.
-- =============================================================================

-- Nettoyer les anciennes donnees de seed
DELETE FROM school_programs WHERE school_id IN (SELECT id FROM schools);
DELETE FROM school_images WHERE school_id IN (SELECT id FROM schools);
DELETE FROM schools;

-- =============================================================================
-- 1. Universite de Lome (publique)
-- =============================================================================
INSERT INTO schools (
    name, type, city, address, phone, email, website, description,
    programs_offered, is_public, is_verified, is_active, logo_url,
    tuition_range, admission_requirements, accreditations,
    founding_year, student_count
) VALUES (
    'Universite de Lome',
    'university',
    'Lome',
    'BP 1515, Lome, Togo',
    '+228 22 25 50 94',
    'info@univ-lome.tg',
    'https://www.univ-lome.tg',
    'L''Universite de Lome (UL) est le principal centre d''enseignement superieur du Togo. Fondee en 1970, elle propose une gamme diversifiee de formations d''excellence reparties dans des facultes et ecoles specialisees, favorisant l''innovation et l''insertion professionnelle des jeunes. Elle accueille des etudiants de toute l''Afrique de l''Ouest et dispose de laboratoires de recherche reconnus.',
    ARRAY['Sciences', 'Medecine', 'Droit', 'Lettres', 'Economie', 'Genie Civil', 'Informatique'],
    TRUE, TRUE, TRUE, NULL,
    '50 000 - 150 000 FCFA/an',
    'Baccalaureat requis. Admission sur etude de dossier selon les series. Concours d''entree pour certaines filieres (medecine, ingenierie). Frais d''inscription : 25 000 FCFA pour les nationaux.',
    ARRAY['CAMES', 'REESAO'],
    1970,
    65000
);

-- =============================================================================
-- 2. Universite de Kara (publique)
-- =============================================================================
INSERT INTO schools (
    name, type, city, address, phone, email, website, description,
    programs_offered, is_public, is_verified, is_active, logo_url,
    tuition_range, admission_requirements, accreditations,
    founding_year, student_count
) VALUES (
    'Universite de Kara',
    'university',
    'Kara',
    'BP 404, Kara, Togo',
    '+228 26 60 02 42',
    'info@univ-kara.tg',
    'https://www.univ-kara.tg',
    'L''Universite de Kara (UK) est la deuxieme universite publique du Togo, situee dans la region septentrionale. Creee en 2004, elle vise a decentraliser l''enseignement superieur et a former des cadres pour le developpement du nord du pays. Elle offre des formations en sciences, lettres, droit et agronomie.',
    ARRAY['Agronomie', 'Droit', 'Lettres', 'Sciences', 'Economie'],
    TRUE, TRUE, TRUE, NULL,
    '50 000 - 120 000 FCFA/an',
    'Baccalaureat requis. Admission sur etude de dossier. Priorite aux bacheliers de la region septentrionale pour certaines filieres.',
    ARRAY['CAMES', 'REESAO'],
    2004,
    15000
);

-- =============================================================================
-- 3. UCAO-UUT (Universite Catholique de l''Afrique de l''Ouest)
-- =============================================================================
INSERT INTO schools (
    name, type, city, address, phone, email, website, description,
    programs_offered, is_public, is_verified, is_active, logo_url,
    tuition_range, admission_requirements, accreditations,
    founding_year, student_count
) VALUES (
    'UCAO-UUT',
    'university',
    'Lome',
    'Avenue Mama N''Danida, BP 11065, Lome, Togo',
    '+228 22 21 45 68',
    'info@ucao-uut.tg',
    'https://www.ucao-uut.tg',
    'L''Unite Universitaire du Togo (UUT) de l''Universite Catholique de l''Afrique de l''Ouest (UCAO) est une institution privee d''excellence fondee par la Conference Episcopale du Togo. Elle propose des formations en droit, economie, informatique et sciences de gestion dans un cadre academique rigoureux inspire des valeurs chretiennes.',
    ARRAY['Droit', 'Economie', 'Gestion', 'Informatique', 'Communication'],
    FALSE, TRUE, TRUE, NULL,
    '500 000 - 1 200 000 FCFA/an',
    'Baccalaureat requis (toutes series selon la filiere). Dossier de candidature complet. Entretien de motivation. Test de niveau en francais et culture generale.',
    ARRAY['CAMES', 'HCERES'],
    1999,
    4500
);

-- =============================================================================
-- 4. ESA (Ecole Superieure des Affaires)
-- =============================================================================
INSERT INTO schools (
    name, type, city, address, phone, email, website, description,
    programs_offered, is_public, is_verified, is_active, logo_url,
    tuition_range, admission_requirements, accreditations,
    founding_year, student_count
) VALUES (
    'ESA - Ecole Superieure des Affaires',
    'grande_ecole',
    'Lome',
    'Boulevard du 13 Janvier, Lome, Togo',
    '+228 22 26 13 00',
    'contact@esa-togo.com',
    'https://www.esa-togo.com',
    'L''Ecole Superieure des Affaires (ESA) est une grande ecole de commerce et de management basee a Lome. Elle forme des cadres superieurs en gestion, finance, marketing et entrepreneuriat. Reconnue pour la qualite de son corps professoral international et ses partenariats avec des entreprises de la sous-region.',
    ARRAY['Management', 'Finance', 'Marketing', 'Comptabilite', 'Entrepreneuriat'],
    FALSE, TRUE, TRUE, NULL,
    '600 000 - 1 500 000 FCFA/an',
    'Baccalaureat requis (series G, C, D privilegiees). Concours d''entree (mathematiques, culture generale, anglais). Etude de dossier pour les admissions paralleles en Master.',
    ARRAY['CAMES'],
    2002,
    2000
);

-- =============================================================================
-- 5. ESIBA Business School
-- =============================================================================
INSERT INTO schools (
    name, type, city, address, phone, email, website, description,
    programs_offered, is_public, is_verified, is_active, logo_url,
    tuition_range, admission_requirements, accreditations,
    founding_year, student_count
) VALUES (
    'ESIBA Business School',
    'grande_ecole',
    'Lome',
    'Boulevard du 13 Janvier, Lome, Togo',
    '+228 90 05 12 34',
    'info@esiba.tg',
    'https://www.esiba.tg',
    'ESIBA Business School est une ecole de commerce de reference au Togo, specialisee dans la formation en management, marketing digital et gestion d''entreprise internationale. Elle mise sur l''innovation pedagogique et les stages en entreprise pour assurer l''employabilite de ses diplomes.',
    ARRAY['Marketing Digital', 'Commerce International', 'Management', 'Ressources Humaines'],
    FALSE, FALSE, TRUE, NULL,
    '450 000 - 900 000 FCFA/an',
    'Baccalaureat requis. Etude de dossier. Entretien de motivation. Tests d''aptitude en logique et communication.',
    ARRAY['CAMES'],
    2010,
    1200
);

-- =============================================================================
-- 6. IPNET Institute
-- =============================================================================
INSERT INTO schools (
    name, type, city, address, phone, email, website, description,
    programs_offered, is_public, is_verified, is_active, logo_url,
    tuition_range, admission_requirements, accreditations,
    founding_year, student_count
) VALUES (
    'IPNET Institute',
    'institut',
    'Lome',
    'Hedzranawoe, Lome, Togo',
    '+228 22 26 88 90',
    'info@ipnet-institute.com',
    'https://www.ipnet-institute.com',
    'IPNET Institute est le leader togolais en formation aux technologies de l''information et certifications internationales. Partenaire officiel de Cisco, Microsoft et AWS, l''institut prepare les etudiants aux metiers du numerique avec des laboratoires equipes et des formateurs certifies.',
    ARRAY['Reseaux', 'Cybersecurite', 'Cloud Computing', 'Developpement Web', 'CISCO'],
    FALSE, TRUE, TRUE, NULL,
    '300 000 - 800 000 FCFA/an',
    'Niveau Bac minimum. Admission sur dossier et test technique. Possibilite d''admission en cours de cycle pour les professionnels avec experience.',
    ARRAY['Cisco Academy', 'Microsoft Partner'],
    2008,
    800
);

-- =============================================================================
-- 7. IAEC Togo
-- =============================================================================
INSERT INTO schools (
    name, type, city, address, phone, email, website, description,
    programs_offered, is_public, is_verified, is_active, logo_url,
    tuition_range, admission_requirements, accreditations,
    founding_year, student_count
) VALUES (
    'IAEC Togo',
    'institut',
    'Lome',
    'Quartier Administratif, Lome, Togo',
    '+228 22 20 55 10',
    'contact@iaec-togo.com',
    'https://www.iaec-togo.com',
    'L''Institut Africain d''Etudes Commerciales (IAEC) est un etablissement d''enseignement superieur prive specialise dans les sciences de gestion, la comptabilite et le commerce international. Il forme des techniciens superieurs et des cadres operationnels pour les entreprises togolaises et de la sous-region.',
    ARRAY['Comptabilite', 'Gestion Commerciale', 'Banque Finance', 'Transit Douane'],
    FALSE, FALSE, TRUE, NULL,
    '350 000 - 700 000 FCFA/an',
    'Baccalaureat requis (series G1, G2, G3 privilegiees). Etude de dossier. Possibilite d''admission sur titre pour les titulaires de BTS.',
    ARRAY['CAMES'],
    1995,
    1500
);

-- =============================================================================
-- 8. ISM Adonai
-- =============================================================================
INSERT INTO schools (
    name, type, city, address, phone, email, website, description,
    programs_offered, is_public, is_verified, is_active, logo_url,
    tuition_range, admission_requirements, accreditations,
    founding_year, student_count
) VALUES (
    'ISM Adonai',
    'institut',
    'Lome',
    'Tokoin, Lome, Togo',
    '+228 22 25 70 30',
    'info@ism-adonai.tg',
    'https://www.ism-adonai.tg',
    'L''Institut Superieur de Management Adonai (ISM Adonai) est un etablissement prive d''enseignement superieur offrant des formations en management, informatique et sciences de gestion. Il met l''accent sur la formation pratique et l''accompagnement personnalise des etudiants vers l''insertion professionnelle.',
    ARRAY['Management', 'Informatique de Gestion', 'Communication', 'Logistique'],
    FALSE, FALSE, TRUE, NULL,
    '300 000 - 650 000 FCFA/an',
    'Baccalaureat requis. Dossier de candidature. Entretien d''admission.',
    ARRAY['CAMES'],
    2005,
    900
);

-- =============================================================================
-- 9. ESGIS (Ecole Superieure de Gestion, d''Informatique et des Sciences)
-- =============================================================================
INSERT INTO schools (
    name, type, city, address, phone, email, website, description,
    programs_offered, is_public, is_verified, is_active, logo_url,
    tuition_range, admission_requirements, accreditations,
    founding_year, student_count
) VALUES (
    'ESGIS',
    'grande_ecole',
    'Lome',
    'Avenue de la Liberation, Lome, Togo',
    '+228 22 22 60 50',
    'info@esgis.org',
    'https://www.esgis.org',
    'L''Ecole Superieure de Gestion, d''Informatique et des Sciences (ESGIS) est une institution privee reconnue en Afrique francophone. Presente dans plusieurs pays, elle offre des formations en informatique, gestion, droit et sciences de la sante. L''ESGIS se distingue par son reseau international et ses programmes professionnalisants.',
    ARRAY['Informatique', 'Gestion', 'Droit', 'Sciences de la Sante', 'Genie Civil'],
    FALSE, TRUE, TRUE, NULL,
    '500 000 - 1 100 000 FCFA/an',
    'Baccalaureat requis. Concours d''entree ou etude de dossier selon la filiere. Entretien de selection. Tests de niveau pour les admissions en Master.',
    ARRAY['CAMES', 'HCERES'],
    2002,
    3500
);

-- =============================================================================
-- 10. FORMATEC
-- =============================================================================
INSERT INTO schools (
    name, type, city, address, phone, email, website, description,
    programs_offered, is_public, is_verified, is_active, logo_url,
    tuition_range, admission_requirements, accreditations,
    founding_year, student_count
) VALUES (
    'FORMATEC',
    'centre_formation',
    'Lome',
    'Adidogome, Lome, Togo',
    '+228 22 51 30 20',
    'info@formatec.tg',
    'https://www.formatec.tg',
    'FORMATEC est un centre de formation professionnelle et technique specialise dans les metiers du BTP, de l''electricite et de la mecanique industrielle. Il propose des formations courtes certifiantes et des BTS pour repondre aux besoins du marche togolais en techniciens qualifies.',
    ARRAY['Electricite', 'Mecanique', 'BTP', 'Froid et Climatisation', 'Maintenance Industrielle'],
    FALSE, FALSE, TRUE, NULL,
    '200 000 - 500 000 FCFA/an',
    'Niveau BEPC ou Baccalaureat selon la filiere. Test pratique d''admission. Possibilite de VAE (Validation des Acquis de l''Experience) pour les professionnels.',
    ARRAY['MEPT'],
    2000,
    600
);

-- =============================================================================
-- PROGRAMMES (school_programs) — 3 a 5 filieres par ecole
-- =============================================================================

-- Universite de Lome
INSERT INTO school_programs (school_id, name, description, level, duration_years, is_active, display_order)
SELECT id, 'Genie Logiciel et Intelligence Artificielle', 'Formation en developpement logiciel, algorithmes, IA et machine learning.', 'licence', 3, TRUE, 1 FROM schools WHERE name = 'Universite de Lome'
UNION ALL
SELECT id, 'Droit des Affaires', 'Formation juridique specialisee en droit commercial, droit des societes et droit fiscal.', 'master', 2, TRUE, 2 FROM schools WHERE name = 'Universite de Lome'
UNION ALL
SELECT id, 'Sciences de la Sante - Medecine', 'Formation medicale complete avec stages hospitaliers et specialisations.', 'doctorat', 7, TRUE, 3 FROM schools WHERE name = 'Universite de Lome'
UNION ALL
SELECT id, 'Economie et Gestion', 'Formation en sciences economiques, gestion d''entreprise et finances publiques.', 'licence', 3, TRUE, 4 FROM schools WHERE name = 'Universite de Lome'
UNION ALL
SELECT id, 'Genie Civil', 'Formation d''ingenieurs en construction, ouvrages d''art et urbanisme.', 'master', 5, TRUE, 5 FROM schools WHERE name = 'Universite de Lome';

-- Universite de Kara
INSERT INTO school_programs (school_id, name, description, level, duration_years, is_active, display_order)
SELECT id, 'Agronomie et Sciences Environnementales', 'Formation en agriculture durable, gestion des sols et environnement.', 'licence', 3, TRUE, 1 FROM schools WHERE name = 'Universite de Kara'
UNION ALL
SELECT id, 'Droit Public', 'Formation en droit constitutionnel, administratif et international public.', 'licence', 3, TRUE, 2 FROM schools WHERE name = 'Universite de Kara'
UNION ALL
SELECT id, 'Lettres Modernes', 'Formation en litterature francaise, africaine et linguistique.', 'licence', 3, TRUE, 3 FROM schools WHERE name = 'Universite de Kara';

-- UCAO-UUT
INSERT INTO school_programs (school_id, name, description, level, duration_years, is_active, display_order)
SELECT id, 'Droit Prive et Sciences Criminelles', 'Formation approfondie en droit civil, penal et criminologie.', 'master', 2, TRUE, 1 FROM schools WHERE name = 'UCAO-UUT'
UNION ALL
SELECT id, 'Sciences Economiques et de Gestion', 'Formation en economie appliquee, comptabilite et gestion des organisations.', 'licence', 3, TRUE, 2 FROM schools WHERE name = 'UCAO-UUT'
UNION ALL
SELECT id, 'Informatique de Gestion', 'Formation en systemes d''information, bases de donnees et developpement.', 'licence', 3, TRUE, 3 FROM schools WHERE name = 'UCAO-UUT'
UNION ALL
SELECT id, 'Communication et Marketing', 'Formation en communication d''entreprise, marketing strategique et digital.', 'master', 2, TRUE, 4 FROM schools WHERE name = 'UCAO-UUT';

-- ESA
INSERT INTO school_programs (school_id, name, description, level, duration_years, is_active, display_order)
SELECT id, 'Management des Organisations', 'Formation en pilotage strategique, leadership et gestion d''equipes.', 'master', 2, TRUE, 1 FROM schools WHERE name = 'ESA - Ecole Superieure des Affaires'
UNION ALL
SELECT id, 'Finance et Comptabilite', 'Formation en analyse financiere, audit et controle de gestion.', 'licence', 3, TRUE, 2 FROM schools WHERE name = 'ESA - Ecole Superieure des Affaires'
UNION ALL
SELECT id, 'Marketing et Strategie Commerciale', 'Formation en marketing digital, etudes de marche et strategie commerciale.', 'master', 2, TRUE, 3 FROM schools WHERE name = 'ESA - Ecole Superieure des Affaires'
UNION ALL
SELECT id, 'Entrepreneuriat et Innovation', 'Formation a la creation d''entreprise, business plan et innovation.', 'licence', 3, TRUE, 4 FROM schools WHERE name = 'ESA - Ecole Superieure des Affaires';

-- ESIBA Business School
INSERT INTO school_programs (school_id, name, description, level, duration_years, is_active, display_order)
SELECT id, 'Marketing Digital', 'Formation en strategie digitale, reseaux sociaux, SEO/SEA et e-commerce.', 'licence', 3, TRUE, 1 FROM schools WHERE name = 'ESIBA Business School'
UNION ALL
SELECT id, 'Commerce International', 'Formation en import-export, logistique internationale et negoce.', 'licence', 3, TRUE, 2 FROM schools WHERE name = 'ESIBA Business School'
UNION ALL
SELECT id, 'Gestion des Ressources Humaines', 'Formation en management RH, droit du travail et recrutement.', 'master', 2, TRUE, 3 FROM schools WHERE name = 'ESIBA Business School';

-- IPNET Institute
INSERT INTO school_programs (school_id, name, description, level, duration_years, is_active, display_order)
SELECT id, 'Administration Reseaux et Systemes', 'Formation CISCO/Microsoft en administration systemes, reseaux LAN/WAN.', 'bts', 2, TRUE, 1 FROM schools WHERE name = 'IPNET Institute'
UNION ALL
SELECT id, 'Cybersecurite', 'Formation en securite informatique, pentesting, audit et conformite.', 'licence', 3, TRUE, 2 FROM schools WHERE name = 'IPNET Institute'
UNION ALL
SELECT id, 'Cloud Computing et DevOps', 'Formation AWS/Azure, virtualisation, CI/CD et infrastructure cloud.', 'licence', 3, TRUE, 3 FROM schools WHERE name = 'IPNET Institute'
UNION ALL
SELECT id, 'Developpement Web et Mobile', 'Formation full-stack : HTML/CSS, JavaScript, React, Node.js, Flutter.', 'bts', 2, TRUE, 4 FROM schools WHERE name = 'IPNET Institute';

-- IAEC Togo
INSERT INTO school_programs (school_id, name, description, level, duration_years, is_active, display_order)
SELECT id, 'Comptabilite et Gestion des Entreprises', 'Formation en comptabilite generale, analytique et controle de gestion.', 'bts', 2, TRUE, 1 FROM schools WHERE name = 'IAEC Togo'
UNION ALL
SELECT id, 'Banque et Finance', 'Formation en operations bancaires, credit, assurance et microfinance.', 'licence', 3, TRUE, 2 FROM schools WHERE name = 'IAEC Togo'
UNION ALL
SELECT id, 'Transit et Logistique', 'Formation en procedures douanieres, transport international et logistique.', 'bts', 2, TRUE, 3 FROM schools WHERE name = 'IAEC Togo';

-- ISM Adonai
INSERT INTO school_programs (school_id, name, description, level, duration_years, is_active, display_order)
SELECT id, 'Management et Administration des Affaires', 'Formation en gestion d''entreprise, strategie et leadership.', 'licence', 3, TRUE, 1 FROM schools WHERE name = 'ISM Adonai'
UNION ALL
SELECT id, 'Informatique de Gestion', 'Formation en systemes d''information, programmation et gestion de projets IT.', 'bts', 2, TRUE, 2 FROM schools WHERE name = 'ISM Adonai'
UNION ALL
SELECT id, 'Logistique et Transport', 'Formation en supply chain, gestion des stocks et transport multimodal.', 'licence', 3, TRUE, 3 FROM schools WHERE name = 'ISM Adonai';

-- ESGIS
INSERT INTO school_programs (school_id, name, description, level, duration_years, is_active, display_order)
SELECT id, 'Genie Informatique', 'Formation en programmation, architecture logicielle et gestion de projets.', 'licence', 3, TRUE, 1 FROM schools WHERE name = 'ESGIS'
UNION ALL
SELECT id, 'Sciences Juridiques et Politiques', 'Formation en droit civil, droit penal et sciences politiques.', 'master', 2, TRUE, 2 FROM schools WHERE name = 'ESGIS'
UNION ALL
SELECT id, 'Gestion et Management', 'Formation en gestion des organisations, marketing et RH.', 'licence', 3, TRUE, 3 FROM schools WHERE name = 'ESGIS'
UNION ALL
SELECT id, 'Genie Civil et Architecture', 'Formation en construction, BTP, topographie et urbanisme.', 'licence', 3, TRUE, 4 FROM schools WHERE name = 'ESGIS';

-- FORMATEC
INSERT INTO school_programs (school_id, name, description, level, duration_years, is_active, display_order)
SELECT id, 'Electricite Industrielle', 'Formation en installation electrique, automatisme et electronique.', 'bts', 2, TRUE, 1 FROM schools WHERE name = 'FORMATEC'
UNION ALL
SELECT id, 'Froid et Climatisation', 'Formation en systemes de refrigeration, climatisation et maintenance.', 'bts', 2, TRUE, 2 FROM schools WHERE name = 'FORMATEC'
UNION ALL
SELECT id, 'Maintenance Industrielle', 'Formation en mecanique, hydraulique et maintenance preventive/corrective.', 'bts', 2, TRUE, 3 FROM schools WHERE name = 'FORMATEC';
