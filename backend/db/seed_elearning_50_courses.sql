-- =============================================================================
-- SEED E-LEARNING — 50+ Cours pour l'Afrique de l'Ouest
-- À exécuter dans Supabase SQL Editor
-- =============================================================================

-- =============================================================================
-- CATÉGORIE: INFORMATIQUE & TECHNOLOGIES (15 cours)
-- =============================================================================

INSERT INTO elearning_courses (id, title, description, category, difficulty, duration_minutes, points_reward, is_published, display_order)
VALUES
('c1000000-0000-0000-0000-000000000101', 'HTML & CSS : Les bases du web', 'Apprends à créer tes premières pages web avec HTML et CSS. Pas de prérequis.', 'Informatique', 'debutant', 60, 120, TRUE, 101),
('c1000000-0000-0000-0000-000000000102', 'JavaScript pour débutants', 'Découvre le langage le plus utilisé du web. Crée des interactions dynamiques.', 'Informatique', 'debutant', 90, 180, TRUE, 102),
('c1000000-0000-0000-0000-000000000103', 'Python : Ton premier langage', 'Initiation à Python avec des projets pratiques. Idéal pour les débutants.', 'Informatique', 'debutant', 120, 200, TRUE, 103),
('c1000000-0000-0000-0000-000000000104', 'Dart & Flutter : Crée ton app mobile', 'Construis des applications mobiles natives pour iOS et Android.', 'Informatique', 'intermediaire', 150, 300, TRUE, 104),
('c1000000-0000-0000-0000-000000000105', 'Introduction à la Data Science', 'Découvre comment analyser des données et en extraire des insights.', 'Informatique', 'intermediaire', 90, 180, TRUE, 105),
('c1000000-0000-0000-0000-000000000106', 'Initiation à l''Intelligence Artificielle', 'Comprendre l''IA, le machine learning et leurs applications.', 'Informatique', 'debutant', 60, 120, TRUE, 106),
('c1000000-0000-0000-0000-000000000107', 'Excel pour la analyse de données', 'Maîtrise les tableurs pour analyser des données et créer des rapports.', 'Informatique', 'debutant', 45, 100, TRUE, 107),
('c1000000-0000-0000-0000-000000000108', 'Cybersécurité : Protégez-vous en ligne', 'Apprends à protéger tes données et ta vie privée sur internet.', 'Informatique', 'debutant', 45, 100, TRUE, 108),
('c1000000-0000-0000-0000-000000000109', 'Git & GitHub : Gérer vos projets', 'Versionner ton code et collaborer avec d''autres développeurs.', 'Informatique', 'intermediaire', 60, 120, TRUE, 109),
('c1000000-0000-0000-0000-000000000110', 'Introduction aux bases de données', 'Comprendre SQL et la gestion des données relationnelles.', 'Informatique', 'intermediaire', 75, 150, TRUE, 110),
('c1000000-0000-0000-0000-000000000111', 'Développement Web Full Stack', 'Deviens développeur web complet : front-end et back-end.', 'Informatique', 'avance', 180, 400, TRUE, 111),
('c1000000-0000-0000-0000-000000000112', 'UI/UX Design : Créer des interfaces', 'Apprends les principes du design d''interfaces utilisateur.', 'Informatique', 'debutant', 60, 120, TRUE, 112),
('c1000000-0000-0000-0000-000000000113', 'Figma pour débutants', 'Maîtrise l''outil de design le plus populaire.', 'Informatique', 'debutant', 45, 100, TRUE, 113),
('c1000000-0000-0000-0000-000000000114', 'Photoshop basics', 'Apprends les fondamentaux de la retouche d''images.', 'Informatique', 'debutant', 60, 120, TRUE, 114),
('c1000000-0000-0000-0000-000000000115', 'Notion pour organiser ton travail', 'Optimise ta productivité avec cet outil tout-en-un.', 'Informatique', 'debutant', 30, 60, TRUE, 115)
ON CONFLICT (id) DO NOTHING;

-- =============================================================================
-- CATÉGORIE: BUSINESS & ENTREPRENEURIAT (10 cours)
-- =============================================================================

INSERT INTO elearning_courses (id, title, description, category, difficulty, duration_minutes, points_reward, is_published, display_order)
VALUES
('c2000000-0000-0000-0000-000000000201', 'Marketing digital pour débutants', 'Apprends les bases du marketing en ligne : SEO, réseaux sociaux, publicité.', 'Business', 'debutant', 60, 120, TRUE, 201),
('c2000000-0000-0000-0000-000000000202', 'Gestion de projet agile', 'Méthodes modernes pour gérer vos projets efficacement.', 'Business', 'intermediaire', 60, 120, TRUE, 202),
('c2000000-0000-0000-0000-000000000203', 'Comptabilité pour non-comptables', 'Comprendre les bases de la comptabilité pour gérer une activité.', 'Business', 'debutant', 45, 100, TRUE, 203),
('c2000000-0000-0000-0000-000000000204', 'Créer son entreprise au Togo', 'Guide pratique pour démarrer votre activité au Togo.', 'Business', 'debutant', 90, 180, TRUE, 204),
('c2000000-0000-0000-0000-000000000205', 'Business Model Canvas', 'Outil stratégique pour valider votre idée de business.', 'Business', 'debutant', 30, 60, TRUE, 205),
('c2000000-0000-0000-0000-000000000206', 'Négociation commerciale', 'Techniques pour négocier efficacement avec vos clients.', 'Business', 'intermediaire', 45, 100, TRUE, 206),
('c2000000-0000-0000-0000-000000000207', 'Gestion de la trésorerie', 'Optimisez la gestion financière de votre activité.', 'Business', 'intermediaire', 45, 100, TRUE, 207),
('c2000000-0000-0000-0000-000000000208', 'Télétravail et remote work', 'Travailler efficacement à distance.', 'Business', 'debutant', 30, 60, TRUE, 208),
('c2000000-0000-0000-0000-000000000209', 'E-commerce : Vendre en ligne', 'Créer et gérer une boutique en ligne performante.', 'Business', 'intermediaire', 75, 150, TRUE, 209),
('c2000000-0000-0000-0000-000000000210', 'Leadership et management d''équipe', 'Développer vos compétences de leader.', 'Business', 'intermediaire', 60, 120, TRUE, 210)
ON CONFLICT (id) DO NOTHING;

-- =============================================================================
-- CATÉGORIE: SCIENCES & INGÉNIERIE (8 cours)
-- =============================================================================

INSERT INTO elearning_courses (id, title, description, category, difficulty, duration_minutes, points_reward, is_published, display_order)
VALUES
('c3000000-0000-0000-0000-000000000301', 'Mathématiques Terminale S', 'Révision complète du programme de Terminale S.', 'Sciences', 'avance', 120, 250, TRUE, 301),
('c3000000-0000-0000-0000-000000000302', 'Physique-Chimie Terminale', 'Cours et exercices pour le BAC scientifique.', 'Sciences', 'avance', 90, 200, TRUE, 302),
('c3000000-0000-0000-0000-000000000303', 'Introduction à l''électronique', 'Bases de l''électronique pour les débutants.', 'Sciences', 'intermediaire', 60, 120, TRUE, 303),
('c3000000-0000-0000-0000-000000000304', 'Biologie cellulaire', 'Comprendre la cellule, unité de vie.', 'Sciences', 'intermediaire', 60, 120, TRUE, 304),
('c3000000-0000-0000-0000-000000000305', 'Statistiques appliquées', 'Maîtriser les statistiques pour les sciences sociales.', 'Sciences', 'intermediaire', 60, 120, TRUE, 305),
('c3000000-0000-0000-0000-000000000306', 'Introduction à la météorologie', 'Comprendre les phénomènes climatiques.', 'Sciences', 'debutant', 45, 100, TRUE, 306),
('c3000000-0000-0000-0000-000000000307', 'Énergies renouvelables', 'Panorama des énergies vertes et de leurs applications.', 'Sciences', 'debutant', 45, 100, TRUE, 307),
('c3000000-0000-0000-0000-000000000308', 'Agriculture durable', 'Techniques agricoles respectueuses de l''environnement.', 'Sciences', 'debutant', 60, 120, TRUE, 308)
ON CONFLICT (id) DO NOTHING;

-- =============================================================================
-- CATÉGORIE: SANTÉ & MÉDECINE (5 cours)
-- =============================================================================

INSERT INTO elearning_courses (id, title, description, category, difficulty, duration_minutes, points_reward, is_published, display_order)
VALUES
('c4000000-0000-0000-0000-000000000401', 'Premiers secours', 'Apprends les gestes qui sauvent.', 'Santé', 'debutant', 45, 100, TRUE, 401),
('c4000000-0000-0000-0000-000000000402', 'Hygiène et assainissement', 'Bonnes pratiques d''hygiène pour la santé.', 'Santé', 'debutant', 30, 60, TRUE, 402),
('c4000000-0000-0000-0000-000000000403', 'Nutrition et alimentation équilibrée', 'Comprendre une alimentation saine.', 'Santé', 'debutant', 45, 100, TRUE, 403),
('c4000000-0000-0000-0000-000000000404', 'Santé mentale et bien-être', 'Prendre soin de sa santé psychique.', 'Santé', 'debutant', 45, 100, TRUE, 404),
('c4000000-0000-0000-0000-000000000405', 'Introduction au nursing', 'Bases des soins infirmiers.', 'Santé', 'intermediaire', 60, 120, TRUE, 405)
ON CONFLICT (id) DO NOTHING;

-- =============================================================================
-- CATÉGORIE: LANGUES (6 cours)
-- =============================================================================

INSERT INTO elearning_courses (id, title, description, category, difficulty, duration_minutes, points_reward, is_published, display_order)
VALUES
('c5000000-0000-0000-0000-000000000501', 'Anglais intermédiaire B1', 'Perfectionne ton anglais quotidien.', 'Langues', 'intermediaire', 90, 180, TRUE, 501),
('c5000000-0000-0000-0000-000000000502', 'Anglais professionnel', 'Anglais pour le monde du travail.', 'Langues', 'avance', 60, 120, TRUE, 502),
('c5000000-0000-0000-0000-000000000503', 'Anglais des affaires', 'Communication professionnelle en anglais.', 'Langues', 'avance', 60, 120, TRUE, 503),
('c5000000-0000-0000-0000-000000000504', 'Vocabulaire tech en anglais', 'Mots et expressions du secteur technologique.', 'Langues', 'intermediaire', 45, 100, TRUE, 504),
('c5000000-0000-0000-0000-000000000505', 'Espagnol pour débutants', 'Initiation à la langue espagnole.', 'Langues', 'debutant', 60, 120, TRUE, 505),
('c5000000-0000-0000-0000-000000000506', 'Chinois mandarin bases', 'Découverte de la langue chinoise.', 'Langues', 'debutant', 45, 100, TRUE, 506)
ON CONFLICT (id) DO NOTHING;

-- =============================================================================
-- CATÉGORIE: PRÉPARATION EXAMENS (6 cours)
-- =============================================================================

INSERT INTO elearning_courses (id, title, description, category, difficulty, duration_minutes, points_reward, is_published, display_order)
VALUES
('c6000000-0000-0000-0000-000000000601', 'Révision BAC Français', 'Tout le programme de français pour le BAC.', 'Examens', 'avance', 120, 250, TRUE, 601),
('c6000000-0000-0000-0000-000000000602', 'Mathématiques BAC Serie C/D', 'Exercices et annales corrigées.', 'Examens', 'avance', 150, 300, TRUE, 602),
('c6000000-0000-0000-0000-000000000603', 'Histoire-Géographie BAC', 'Cours et cartes pour le BAC.', 'Examens', 'avance', 90, 180, TRUE, 603),
('c6000000-0000-0000-0000-000000000604', 'Physique BAC Serie C', 'Exercices corrigés pour la Terminale C.', 'Examens', 'avance', 90, 200, TRUE, 604),
('c6000000-0000-0000-0000-000000000605', 'Concours d''entrée ENSA', 'Préparation au concours des écoles d''ingénieurs.', 'Examens', 'avance', 120, 250, TRUE, 605),
('c6000000-0000-0000-0000-000000000606', 'Méthodologie des examens', 'Techniques pour réussir tes examens.', 'Examens', 'debutant', 45, 100, TRUE, 606)
ON CONFLICT (id) DO NOTHING;

-- =============================================================================
-- CATÉGORIE: COMPÉTENCES TRANSVERSALES (10 cours)
-- =============================================================================

INSERT INTO elearning_courses (id, title, description, category, difficulty, duration_minutes, points_reward, is_published, display_order)
VALUES
('c7000000-0000-0000-0000-000000000701', 'Communiquer efficacement', 'Améliore tes compétences communicationnelles.', 'Soft Skills', 'debutant', 45, 100, TRUE, 701),
('c7000000-0000-0000-0000-000000000702', 'Gestion du temps', 'Optimise ta productivité.', 'Soft Skills', 'debutant', 30, 60, TRUE, 702),
('c7000000-0000-0000-0000-000000000703', 'Rédaction de CV', 'Créer un CV qui attire les recruteurs.', 'Soft Skills', 'debutant', 30, 60, TRUE, 703),
('c7000000-0000-0000-0000-000000000704', 'Préparer un entretien d''embauche', 'Techniques pour réussir tes entretiens.', 'Soft Skills', 'debutant', 45, 100, TRUE, 704),
('c7000000-0000-0000-0000-000000000705', 'Travail en équipe', 'Collaborer efficacement avec les autres.', 'Soft Skills', 'debutant', 30, 60, TRUE, 705),
('c7000000-0000-0000-0000-000000000706', 'Résolution de problèmes', 'Approches créatives pour résoudre les défis.', 'Soft Skills', 'intermediaire', 45, 100, TRUE, 706),
('c7000000-0000-0000-0000-000000000707', 'Public speaking', 'Prendre la parole en public avec confiance.', 'Soft Skills', 'intermediaire', 45, 100, TRUE, 707),
('c7000000-0000-0000-0000-000000000708', 'Intelligence émotionnelle', 'Comprendre et gérer ses émotions.', 'Soft Skills', 'debutant', 45, 100, TRUE, 708),
('c7000000-0000-0000-0000-000000000709', 'Pensée critique', 'Analyser et évaluer les informations de manière critique.', 'Soft Skills', 'intermediaire', 60, 120, TRUE, 709),
('c7000000-0000-0000-0000-000000000710', 'Créativité et innovation', 'Développer ta pensée créative.', 'Soft Skills', 'debutant', 45, 100, TRUE, 710)
ON CONFLICT (id) DO NOTHING;

-- =============================================================================
-- VUE RÉSUMÉ
-- =============================================================================

SELECT 
    category,
    difficulty,
    COUNT(*) as nombre_cours,
    SUM(duration_minutes) as duree_totale_minutes,
    SUM(points_reward) as points_totaux
FROM elearning_courses
WHERE is_published = TRUE
GROUP BY category, difficulty
ORDER BY category, difficulty;