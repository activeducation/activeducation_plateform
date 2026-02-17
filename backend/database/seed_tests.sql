-- =============================================================================
-- Seed: Tests d'orientation complets
-- Source: donnees hardcodees dans orientation_remote_data_source.dart
-- 10 tests: RIASEC + 9 tests complets (personnalite, valeurs, aptitudes, environnement)
-- =============================================================================

-- Note: Le test RIASEC de base est deja dans schema.sql.
-- Ici on ajoute les 9 tests supplementaires.

-- Test 2: Intelligences Multiples
INSERT INTO orientation_tests (id, name, description, type, duration_minutes, display_order, is_active) VALUES
    ('223e4567-e89b-12d3-a456-426614174001',
     'Test des Intelligences Multiples',
     'Identifie tes formes d''intelligence dominantes selon la theorie de Howard Gardner. Chacun possede un mix unique de 8 intelligences.',
     'personality',
     12,
     2,
     TRUE)
ON CONFLICT (id) DO NOTHING;

-- Test 3: Valeurs Professionnelles
INSERT INTO orientation_tests (id, name, description, type, duration_minutes, display_order, is_active) VALUES
    ('323e4567-e89b-12d3-a456-426614174002',
     'Test des Valeurs Professionnelles',
     'Decouvre ce qui te motive vraiment dans le travail. Tes valeurs professionnelles guident tes choix de carriere et ta satisfaction au travail.',
     'interests',
     8,
     3,
     TRUE)
ON CONFLICT (id) DO NOTHING;

-- Test 4: MBTI Simplifie
INSERT INTO orientation_tests (id, name, description, type, duration_minutes, display_order, is_active) VALUES
    ('423e4567-e89b-12d3-a456-426614174003',
     'Test de Personnalite (MBTI Simplifie)',
     'Decouvre ton type de personnalite parmi 16 profils possibles. Ce test simplifie t''aide a comprendre comment tu percois le monde et prends des decisions.',
     'personality',
     10,
     4,
     TRUE)
ON CONFLICT (id) DO NOTHING;

-- Test 5: Aptitudes Naturelles
INSERT INTO orientation_tests (id, name, description, type, duration_minutes, display_order, is_active) VALUES
    ('523e4567-e89b-12d3-a456-426614174004',
     'Test d''Aptitudes Naturelles',
     'Identifie tes talents naturels et tes forces. Ce test mesure tes aptitudes dans differents domaines pour t''orienter vers les metiers ou tu excelleras.',
     'aptitude',
     10,
     5,
     TRUE)
ON CONFLICT (id) DO NOTHING;

-- Test 6: Potentiel Entrepreneurial
INSERT INTO orientation_tests (id, name, description, type, duration_minutes, display_order, is_active) VALUES
    ('623e4567-e89b-12d3-a456-426614174005',
     'Test de Potentiel Entrepreneurial',
     'Es-tu fait pour entreprendre ? Ce test evalue tes competences et ta mentalite entrepreneuriales pour t''aider a savoir si la creation d''entreprise est faite pour toi.',
     'skills',
     8,
     6,
     TRUE)
ON CONFLICT (id) DO NOTHING;

-- Test 7: Ancres de Carriere (inspire de Schein)
INSERT INTO orientation_tests (id, name, description, type, duration_minutes, display_order, is_active) VALUES
    ('723e4567-e89b-12d3-a456-426614174006',
     'Test des Ancres de Carriere',
     'Identifie les motivations profondes qui orientent tes choix professionnels: expertise, autonomie, management, securite, service, defi, style de vie et entrepreneuriat.',
     'interests',
     12,
     7,
     TRUE)
ON CONFLICT (id) DO NOTHING;

-- Test 8: Styles d'Apprentissage (VARK)
INSERT INTO orientation_tests (id, name, description, type, duration_minutes, display_order, is_active) VALUES
    ('823e4567-e89b-12d3-a456-426614174007',
     'Test des Styles d''Apprentissage (VARK)',
     'Decouvre comment tu apprends le plus efficacement: visuel, auditif, lecture/ecriture ou kinesthesique.',
     'aptitude',
     8,
     8,
     TRUE)
ON CONFLICT (id) DO NOTHING;

-- Test 9: Environnement de Travail Ideal
INSERT INTO orientation_tests (id, name, description, type, duration_minutes, display_order, is_active) VALUES
    ('923e4567-e89b-12d3-a456-426614174008',
     'Test d''Environnement de Travail Ideal',
     'Determine les conditions de travail dans lesquelles tu performes le mieux: collaboration, autonomie, structure, innovation, terrain ou analyse.',
     'skills',
     9,
     9,
     TRUE)
ON CONFLICT (id) DO NOTHING;

-- Test 10: Maturite du Projet Professionnel
INSERT INTO orientation_tests (id, name, description, type, duration_minutes, display_order, is_active) VALUES
    ('a23e4567-e89b-12d3-a456-426614174009',
     'Test de Maturite du Projet Professionnel',
     'Mesure ton niveau de clarte sur ton avenir: connaissance de soi, exploration des metiers, prise de decision et plan d''action.',
     'interests',
     10,
     10,
     TRUE)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- Questions pour le test Intelligences Multiples
-- ============================================================================

-- Linguistique
INSERT INTO test_questions (test_id, question_text, question_type, category, display_order) VALUES
    ('223e4567-e89b-12d3-a456-426614174001', 'J''aime lire des livres et ecrire des histoires.', 'likert', 'Linguistique', 1),
    ('223e4567-e89b-12d3-a456-426614174001', 'Je m''exprime facilement a l''oral et a l''ecrit.', 'likert', 'Linguistique', 2),
    ('223e4567-e89b-12d3-a456-426614174001', 'J''apprends mieux en lisant ou en ecoutant des explications.', 'likert', 'Linguistique', 3);

-- Logico-Mathematique
INSERT INTO test_questions (test_id, question_text, question_type, category, display_order) VALUES
    ('223e4567-e89b-12d3-a456-426614174001', 'J''aime resoudre des enigmes et des problemes logiques.', 'likert', 'Logico-Mathematique', 4),
    ('223e4567-e89b-12d3-a456-426614174001', 'Je suis a l''aise avec les chiffres et les calculs.', 'likert', 'Logico-Mathematique', 5),
    ('223e4567-e89b-12d3-a456-426614174001', 'Je cherche toujours a comprendre le "pourquoi" des choses.', 'likert', 'Logico-Mathematique', 6);

-- Spatiale
INSERT INTO test_questions (test_id, question_text, question_type, category, display_order) VALUES
    ('223e4567-e89b-12d3-a456-426614174001', 'Je visualise facilement des objets en 3D dans ma tete.', 'likert', 'Spatiale', 7),
    ('223e4567-e89b-12d3-a456-426614174001', 'J''ai un bon sens de l''orientation.', 'likert', 'Spatiale', 8),
    ('223e4567-e89b-12d3-a456-426614174001', 'J''aime dessiner, creer des schemas ou des cartes.', 'likert', 'Spatiale', 9);

-- Musicale
INSERT INTO test_questions (test_id, question_text, question_type, category, display_order) VALUES
    ('223e4567-e89b-12d3-a456-426614174001', 'Je retiens facilement les melodies et les rythmes.', 'likert', 'Musicale', 10),
    ('223e4567-e89b-12d3-a456-426614174001', 'J''aime chanter, jouer d''un instrument ou ecouter de la musique.', 'likert', 'Musicale', 11);

-- Kinesthesique
INSERT INTO test_questions (test_id, question_text, question_type, category, display_order) VALUES
    ('223e4567-e89b-12d3-a456-426614174001', 'J''apprends mieux en faisant les choses moi-meme.', 'likert', 'Kinesthesique', 12),
    ('223e4567-e89b-12d3-a456-426614174001', 'Je suis habile de mes mains et j''aime le sport.', 'likert', 'Kinesthesique', 13);

-- Interpersonnelle
INSERT INTO test_questions (test_id, question_text, question_type, category, display_order) VALUES
    ('223e4567-e89b-12d3-a456-426614174001', 'Je comprends facilement les emotions des autres.', 'likert', 'Interpersonnelle', 14),
    ('223e4567-e89b-12d3-a456-426614174001', 'J''aime travailler en equipe et aider les autres.', 'likert', 'Interpersonnelle', 15);

-- Intrapersonnelle
INSERT INTO test_questions (test_id, question_text, question_type, category, display_order) VALUES
    ('223e4567-e89b-12d3-a456-426614174001', 'Je me connais bien et je sais identifier mes forces et faiblesses.', 'likert', 'Intrapersonnelle', 16),
    ('223e4567-e89b-12d3-a456-426614174001', 'J''aime reflechir seul et planifier mes objectifs.', 'likert', 'Intrapersonnelle', 17);

-- Naturaliste
INSERT INTO test_questions (test_id, question_text, question_type, category, display_order) VALUES
    ('223e4567-e89b-12d3-a456-426614174001', 'J''aime observer et classer les elements de la nature.', 'likert', 'Naturaliste', 18),
    ('223e4567-e89b-12d3-a456-426614174001', 'Je suis sensible a l''environnement et a la protection de la nature.', 'likert', 'Naturaliste', 19);

-- ============================================================================
-- Questions pour le test Valeurs Professionnelles
-- ============================================================================

INSERT INTO test_questions (test_id, question_text, question_type, category, display_order) VALUES
    ('323e4567-e89b-12d3-a456-426614174002', 'Gagner un bon salaire est tres important pour moi.', 'likert', 'Remuneration', 1),
    ('323e4567-e89b-12d3-a456-426614174002', 'Je veux un travail qui me permette d''aider les autres.', 'likert', 'Altruisme', 2),
    ('323e4567-e89b-12d3-a456-426614174002', 'La securite de l''emploi est prioritaire dans mon choix de carriere.', 'likert', 'Securite', 3),
    ('323e4567-e89b-12d3-a456-426614174002', 'Je veux etre libre et autonome dans mon travail.', 'likert', 'Autonomie', 4),
    ('323e4567-e89b-12d3-a456-426614174002', 'Je souhaite etre reconnu et respecte pour mon travail.', 'likert', 'Reconnaissance', 5),
    ('323e4567-e89b-12d3-a456-426614174002', 'Avoir un bon equilibre vie professionnelle/vie personnelle est essentiel.', 'likert', 'Equilibre', 6),
    ('323e4567-e89b-12d3-a456-426614174002', 'Je veux un travail creatif ou je peux innover.', 'likert', 'Creativite', 7),
    ('323e4567-e89b-12d3-a456-426614174002', 'Diriger une equipe et avoir du pouvoir m''attire.', 'likert', 'Leadership', 8),
    ('323e4567-e89b-12d3-a456-426614174002', 'Je veux un metier qui a un impact positif sur la societe.', 'likert', 'Impact', 9),
    ('323e4567-e89b-12d3-a456-426614174002', 'Apprendre continuellement de nouvelles choses est important pour moi.', 'likert', 'Apprentissage', 10);

-- ============================================================================
-- Questions pour le test MBTI Simplifie
-- ============================================================================

INSERT INTO test_questions (test_id, question_text, question_type, category, display_order) VALUES
    ('423e4567-e89b-12d3-a456-426614174003', 'Dans un groupe, je suis plutot celui qui prend la parole en premier.', 'likert', 'E-I', 1),
    ('423e4567-e89b-12d3-a456-426614174003', 'Je prefere les faits concrets aux idees abstraites.', 'likert', 'S-N', 2),
    ('423e4567-e89b-12d3-a456-426614174003', 'Je prends mes decisions avec la logique plutot qu''avec les emotions.', 'likert', 'T-F', 3),
    ('423e4567-e89b-12d3-a456-426614174003', 'Je prefere planifier a l''avance plutot qu''improviser.', 'likert', 'J-P', 4),
    ('423e4567-e89b-12d3-a456-426614174003', 'Les fetes et les grands rassemblements me donnent de l''energie.', 'likert', 'E-I', 5),
    ('423e4567-e89b-12d3-a456-426614174003', 'Je fais confiance a mon experience plutot qu''a mon intuition.', 'likert', 'S-N', 6),
    ('423e4567-e89b-12d3-a456-426614174003', 'L''harmonie dans le groupe est plus importante que la verite.', 'likert', 'T-F', 7),
    ('423e4567-e89b-12d3-a456-426614174003', 'J''aime avoir mes affaires bien rangees et organisees.', 'likert', 'J-P', 8);

-- ============================================================================
-- Questions pour le test Aptitudes Naturelles
-- ============================================================================

INSERT INTO test_questions (test_id, question_text, question_type, category, display_order) VALUES
    ('523e4567-e89b-12d3-a456-426614174004', 'J''arrive facilement a expliquer des choses complexes aux autres.', 'likert', 'Communication', 1),
    ('523e4567-e89b-12d3-a456-426614174004', 'Je suis bon en calcul mental et en mathematiques.', 'likert', 'Analytique', 2),
    ('523e4567-e89b-12d3-a456-426614174004', 'Je suis a l''aise pour organiser des evenements ou des projets.', 'likert', 'Organisation', 3),
    ('523e4567-e89b-12d3-a456-426614174004', 'J''ai une bonne memoire visuelle.', 'likert', 'Visuelle', 4),
    ('523e4567-e89b-12d3-a456-426614174004', 'Je suis doue pour resoudre des conflits entre personnes.', 'likert', 'Mediation', 5),
    ('523e4567-e89b-12d3-a456-426614174004', 'Je suis creatif et j''ai souvent des idees originales.', 'likert', 'Creativite', 6),
    ('523e4567-e89b-12d3-a456-426614174004', 'Je suis patient et methodique dans mon travail.', 'likert', 'Methode', 7),
    ('523e4567-e89b-12d3-a456-426614174004', 'Je m''adapte facilement aux nouvelles situations.', 'likert', 'Adaptabilite', 8),
    ('523e4567-e89b-12d3-a456-426614174004', 'Je suis bon pour convaincre et negocier.', 'likert', 'Persuasion', 9),
    ('523e4567-e89b-12d3-a456-426614174004', 'Je gere bien mon temps et mes priorites.', 'likert', 'Gestion du temps', 10);

-- ============================================================================
-- Questions pour le test Potentiel Entrepreneurial
-- ============================================================================

INSERT INTO test_questions (test_id, question_text, question_type, category, display_order) VALUES
    ('623e4567-e89b-12d3-a456-426614174005', 'Je prefere creer mon propre chemin plutot que suivre celui des autres.', 'likert', 'Initiative', 1),
    ('623e4567-e89b-12d3-a456-426614174005', 'L''echec ne me decourage pas, il me motive a essayer autrement.', 'likert', 'Resilience', 2),
    ('623e4567-e89b-12d3-a456-426614174005', 'Je vois des opportunites business la ou les autres voient des problemes.', 'likert', 'Vision', 3),
    ('623e4567-e89b-12d3-a456-426614174005', 'Je suis pret a prendre des risques calcules pour atteindre mes objectifs.', 'likert', 'Prise de risque', 4),
    ('623e4567-e89b-12d3-a456-426614174005', 'J''ai deja vendu quelque chose ou eu une petite activite generant des revenus.', 'likert', 'Experience', 5),
    ('623e4567-e89b-12d3-a456-426614174005', 'Je suis capable de motiver et entrainer les autres dans mes projets.', 'likert', 'Leadership', 6),
    ('623e4567-e89b-12d3-a456-426614174005', 'Je gere bien mon argent et je comprends les bases de la finance.', 'likert', 'Finance', 7),
    ('623e4567-e89b-12d3-a456-426614174005', 'Je suis passionne et pret a travailler dur pour realiser mes reves.', 'likert', 'Passion', 8);

-- ============================================================================
-- Questions pour le test Ancres de Carriere
-- ============================================================================

INSERT INTO test_questions (test_id, question_text, question_type, category, display_order) VALUES
    ('723e4567-e89b-12d3-a456-426614174006', 'Je veux devenir excellent dans un domaine technique precis.', 'likert', 'Technique', 1),
    ('723e4567-e89b-12d3-a456-426614174006', 'Je prefere etre reconnu pour mon expertise plutot que pour mon poste.', 'likert', 'Technique', 2),
    ('723e4567-e89b-12d3-a456-426614174006', 'Diriger des equipes et prendre des decisions me motive.', 'likert', 'Management', 3),
    ('723e4567-e89b-12d3-a456-426614174006', 'Je me vois evoluer vers des responsabilites de coordination.', 'likert', 'Management', 4),
    ('723e4567-e89b-12d3-a456-426614174006', 'Je veux garder ma liberte dans ma facon de travailler.', 'likert', 'Autonomie', 5),
    ('723e4567-e89b-12d3-a456-426614174006', 'Je prefere les missions ou je peux choisir mes methodes.', 'likert', 'Autonomie', 6),
    ('723e4567-e89b-12d3-a456-426614174006', 'La stabilite de l''emploi est une priorite pour moi.', 'likert', 'Securite', 7),
    ('723e4567-e89b-12d3-a456-426614174006', 'Je privilegie les environnements professionnels previsibles.', 'likert', 'Securite', 8),
    ('723e4567-e89b-12d3-a456-426614174006', 'Avoir un impact positif sur les autres est essentiel.', 'likert', 'Service', 9),
    ('723e4567-e89b-12d3-a456-426614174006', 'Je veux contribuer a une mission utile a la societe.', 'likert', 'Service', 10),
    ('723e4567-e89b-12d3-a456-426614174006', 'Je suis attire par les situations difficiles a relever.', 'likert', 'Defi', 11),
    ('723e4567-e89b-12d3-a456-426614174006', 'Resoudre des problemes complexes m''enthousiasme.', 'likert', 'Defi', 12),
    ('723e4567-e89b-12d3-a456-426614174006', 'Je veux un metier compatible avec ma vie personnelle.', 'likert', 'StyleDeVie', 13),
    ('723e4567-e89b-12d3-a456-426614174006', 'L''equilibre global compte plus que le statut.', 'likert', 'StyleDeVie', 14),
    ('723e4567-e89b-12d3-a456-426614174006', 'J''aime creer des projets a partir de zero.', 'likert', 'Entrepreneuriat', 15),
    ('723e4567-e89b-12d3-a456-426614174006', 'Prendre des risques calcules ne me fait pas peur.', 'likert', 'Entrepreneuriat', 16);

-- ============================================================================
-- Questions pour le test Styles d'Apprentissage (VARK)
-- ============================================================================

INSERT INTO test_questions (test_id, question_text, question_type, category, display_order) VALUES
    ('823e4567-e89b-12d3-a456-426614174007', 'Je comprends mieux avec des schemas ou des graphiques.', 'likert', 'Visuel', 1),
    ('823e4567-e89b-12d3-a456-426614174007', 'Les cartes mentales m''aident a retenir les informations.', 'likert', 'Visuel', 2),
    ('823e4567-e89b-12d3-a456-426614174007', 'Je prefere regarder une demonstration plutot que lire un texte.', 'likert', 'Visuel', 3),
    ('823e4567-e89b-12d3-a456-426614174007', 'J''apprends facilement quand on m''explique oralement.', 'likert', 'Auditif', 4),
    ('823e4567-e89b-12d3-a456-426614174007', 'Discuter d''un sujet m''aide a mieux le maitriser.', 'likert', 'Auditif', 5),
    ('823e4567-e89b-12d3-a456-426614174007', 'Je retiens bien les cours ecoutes ou en podcast.', 'likert', 'Auditif', 6),
    ('823e4567-e89b-12d3-a456-426614174007', 'Lire des notes detaillees est mon meilleur moyen d''apprendre.', 'likert', 'LectureEcriture', 7),
    ('823e4567-e89b-12d3-a456-426614174007', 'Ecrire des resumes m''aide a memoriser.', 'likert', 'LectureEcriture', 8),
    ('823e4567-e89b-12d3-a456-426614174007', 'Je prefere les supports textes aux videos.', 'likert', 'LectureEcriture', 9),
    ('823e4567-e89b-12d3-a456-426614174007', 'Je retiens mieux en pratiquant directement.', 'likert', 'Kinesthesique', 10),
    ('823e4567-e89b-12d3-a456-426614174007', 'Les exercices concrets me font progresser rapidement.', 'likert', 'Kinesthesique', 11),
    ('823e4567-e89b-12d3-a456-426614174007', 'Je prefere apprendre via des projets plutot que par theorie seule.', 'likert', 'Kinesthesique', 12);

-- ============================================================================
-- Questions pour le test Environnement de Travail Ideal
-- ============================================================================

INSERT INTO test_questions (test_id, question_text, question_type, category, display_order) VALUES
    ('923e4567-e89b-12d3-a456-426614174008', 'Je donne le meilleur de moi en travaillant avec une equipe.', 'likert', 'Collaboration', 1),
    ('923e4567-e89b-12d3-a456-426614174008', 'Les projets collectifs me motivent davantage que les missions solo.', 'likert', 'Collaboration', 2),
    ('923e4567-e89b-12d3-a456-426614174008', 'Je prefere organiser mon travail sans supervision constante.', 'likert', 'Autonomie', 3),
    ('923e4567-e89b-12d3-a456-426614174008', 'Je suis plus efficace quand je decide seul de mes priorites.', 'likert', 'Autonomie', 4),
    ('923e4567-e89b-12d3-a456-426614174008', 'Les regles claires et les procedures m''aident a performer.', 'likert', 'Structure', 5),
    ('923e4567-e89b-12d3-a456-426614174008', 'Je prefere des objectifs et un cadre bien definis.', 'likert', 'Structure', 6),
    ('923e4567-e89b-12d3-a456-426614174008', 'J''aime les environnements ou l''on teste de nouvelles idees.', 'likert', 'Innovation', 7),
    ('923e4567-e89b-12d3-a456-426614174008', 'Je m''epanouis dans des organisations qui changent vite.', 'likert', 'Innovation', 8),
    ('923e4567-e89b-12d3-a456-426614174008', 'Je prefere les activites de terrain aux taches de bureau.', 'likert', 'Terrain', 9),
    ('923e4567-e89b-12d3-a456-426614174008', 'Bouger et voir des situations reelles me motive.', 'likert', 'Terrain', 10),
    ('923e4567-e89b-12d3-a456-426614174008', 'J''aime analyser des donnees avant de prendre une decision.', 'likert', 'Analyse', 11),
    ('923e4567-e89b-12d3-a456-426614174008', 'Les missions qui demandent de la rigueur intellectuelle me plaisent.', 'likert', 'Analyse', 12);

-- ============================================================================
-- Questions pour le test Maturite du Projet Professionnel
-- ============================================================================

INSERT INTO test_questions (test_id, question_text, question_type, category, display_order) VALUES
    ('a23e4567-e89b-12d3-a456-426614174009', 'Je connais clairement mes points forts et mes limites.', 'likert', 'ConnaissanceDeSoi', 1),
    ('a23e4567-e89b-12d3-a456-426614174009', 'Je sais quelles activites me donnent de l''energie.', 'likert', 'ConnaissanceDeSoi', 2),
    ('a23e4567-e89b-12d3-a456-426614174009', 'Je peux expliquer ce qui compte vraiment pour moi dans un metier.', 'likert', 'ConnaissanceDeSoi', 3),
    ('a23e4567-e89b-12d3-a456-426614174009', 'J''ai explore plusieurs metiers qui m''interessent.', 'likert', 'ExplorationMetiers', 4),
    ('a23e4567-e89b-12d3-a456-426614174009', 'Je connais les formations necessaires pour les metiers que je vise.', 'likert', 'ExplorationMetiers', 5),
    ('a23e4567-e89b-12d3-a456-426614174009', 'Je me renseigne regulierement sur les perspectives d''emploi.', 'likert', 'ExplorationMetiers', 6),
    ('a23e4567-e89b-12d3-a456-426614174009', 'Je me sens capable de comparer plusieurs options de carriere.', 'likert', 'PriseDecision', 7),
    ('a23e4567-e89b-12d3-a456-426614174009', 'Je peux prioriser une voie professionnelle en fonction de criteres clairs.', 'likert', 'PriseDecision', 8),
    ('a23e4567-e89b-12d3-a456-426614174009', 'Je prends des decisions sans rester bloque trop longtemps.', 'likert', 'PriseDecision', 9),
    ('a23e4567-e89b-12d3-a456-426614174009', 'J''ai defini des etapes concretes pour atteindre mon objectif.', 'likert', 'PlanAction', 10),
    ('a23e4567-e89b-12d3-a456-426614174009', 'Je sais quelles competences je dois developper cette annee.', 'likert', 'PlanAction', 11),
    ('a23e4567-e89b-12d3-a456-426614174009', 'Je passe a l''action (stages, projets, rencontres) pour avancer.', 'likert', 'PlanAction', 12);

-- ============================================================================
-- Options Likert pour tous les nouveaux tests
-- ============================================================================

INSERT INTO question_options (question_id, option_text, option_value, display_order)
SELECT
    q.id,
    opt.text,
    opt.value,
    opt.value
FROM test_questions q
CROSS JOIN (
    VALUES
        ('Pas du tout d''accord', 1),
        ('Peu d''accord', 2),
        ('Moyennement d''accord', 3),
        ('D''accord', 4),
        ('Tout a fait d''accord', 5)
) AS opt(text, value)
WHERE q.test_id IN (
    '223e4567-e89b-12d3-a456-426614174001',
    '323e4567-e89b-12d3-a456-426614174002',
    '423e4567-e89b-12d3-a456-426614174003',
    '523e4567-e89b-12d3-a456-426614174004',
    '623e4567-e89b-12d3-a456-426614174005',
    '723e4567-e89b-12d3-a456-426614174006',
    '823e4567-e89b-12d3-a456-426614174007',
    '923e4567-e89b-12d3-a456-426614174008',
    'a23e4567-e89b-12d3-a456-426614174009'
)
AND q.question_type = 'likert';
