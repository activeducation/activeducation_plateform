-- ============================================================
-- SEED E-LEARNING — Données de démonstration
-- À exécuter dans Supabase SQL Editor après la migration 005
-- ============================================================

-- ── COURS ───────────────────────────────────────────────────

INSERT INTO elearning_courses (id, title, description, thumbnail_url, category, difficulty, duration_minutes, points_reward, is_published, display_order)
VALUES
  (
    'a1000000-0000-0000-0000-000000000001',
    'Introduction aux Métiers du Numérique',
    'Découvre les métiers du numérique : développeur, designer, data scientist... Explore leurs réalités, compétences requises et perspectives en Afrique.',
    NULL,
    'Informatique',
    'debutant',
    45,
    100,
    TRUE,
    1
  ),
  (
    'a1000000-0000-0000-0000-000000000002',
    'Préparer son Orientation Post-Bac',
    'Un guide complet pour choisir ta filière après le bac : comment s''auto-évaluer, comparer les formations et construire ton projet d''études.',
    NULL,
    'Orientation',
    'debutant',
    30,
    80,
    TRUE,
    2
  ),
  (
    'a1000000-0000-0000-0000-000000000003',
    'Hackathon : Résoudre un Problème Local',
    'Participe à un vrai défi créatif : identifie un problème dans ta communauté et propose une solution innovante avec ton équipe.',
    NULL,
    'Hackathons',
    'intermediaire',
    120,
    200,
    TRUE,
    3
  )
ON CONFLICT (id) DO NOTHING;


-- ── MODULES ─────────────────────────────────────────────────

-- Cours 1 : Introduction aux Métiers du Numérique
INSERT INTO elearning_modules (id, course_id, title, description, display_order, is_locked)
VALUES
  ('b1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 'Module 1 — Le paysage numérique', 'Vue d''ensemble du secteur tech en Afrique', 1, FALSE),
  ('b1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001', 'Module 2 — Choisir sa spécialité', 'Front-end, back-end, data, design... lequel te correspond ?', 2, TRUE)
ON CONFLICT (id) DO NOTHING;

-- Cours 2 : Préparer son Orientation Post-Bac
INSERT INTO elearning_modules (id, course_id, title, description, display_order, is_locked)
VALUES
  ('b1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000002', 'Module 1 — Connais-toi toi-même', 'Auto-évaluation et identification de tes forces', 1, FALSE),
  ('b1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000002', 'Module 2 — Explorer les filières', 'Comparatif des filières disponibles au Togo et en Afrique', 2, TRUE)
ON CONFLICT (id) DO NOTHING;

-- Cours 3 : Hackathon
INSERT INTO elearning_modules (id, course_id, title, description, display_order, is_locked)
VALUES
  ('b1000000-0000-0000-0000-000000000005', 'a1000000-0000-0000-0000-000000000003', 'Module 1 — Comprendre le défi', 'Présentation du problème et règles du hackathon', 1, FALSE),
  ('b1000000-0000-0000-0000-000000000006', 'a1000000-0000-0000-0000-000000000003', 'Module 2 — Soumettre ta solution', 'Guide pour préparer et soumettre ta proposition', 2, TRUE)
ON CONFLICT (id) DO NOTHING;


-- ── LEÇONS ──────────────────────────────────────────────────

-- Module 1 du Cours 1
INSERT INTO elearning_lessons (id, module_id, title, lesson_type, duration_minutes, points_reward, display_order, is_free)
VALUES
  ('c1000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 'Le numérique en Afrique aujourd''hui', 'article', 8, 10, 1, TRUE),
  ('c1000000-0000-0000-0000-000000000002', 'b1000000-0000-0000-0000-000000000001', 'Présentation des métiers tech', 'video', 12, 15, 2, FALSE),
  ('c1000000-0000-0000-0000-000000000003', 'b1000000-0000-0000-0000-000000000002', 'Quiz : Quel profil tech es-tu ?', 'quiz', 10, 20, 1, FALSE),
  ('c1000000-0000-0000-0000-000000000004', 'b1000000-0000-0000-0000-000000000002', 'Ressources métiers (PDF)', 'pdf', 5, 10, 2, FALSE)
ON CONFLICT (id) DO NOTHING;

-- Module 1 du Cours 2
INSERT INTO elearning_lessons (id, module_id, title, lesson_type, duration_minutes, points_reward, display_order, is_free)
VALUES
  ('c1000000-0000-0000-0000-000000000005', 'b1000000-0000-0000-0000-000000000003', 'Évaluer tes points forts', 'article', 6, 10, 1, TRUE),
  ('c1000000-0000-0000-0000-000000000006', 'b1000000-0000-0000-0000-000000000003', 'Guide d''orientation (PDF)', 'pdf', 5, 10, 2, FALSE),
  ('c1000000-0000-0000-0000-000000000007', 'b1000000-0000-0000-0000-000000000004', 'Quiz : Quelle filière te correspond ?', 'quiz', 8, 20, 1, FALSE)
ON CONFLICT (id) DO NOTHING;

-- Cours 3 : Hackathon
INSERT INTO elearning_lessons (id, module_id, title, lesson_type, duration_minutes, points_reward, display_order, is_free)
VALUES
  ('c1000000-0000-0000-0000-000000000008', 'b1000000-0000-0000-0000-000000000005', 'Comprendre le brief du hackathon', 'article', 10, 15, 1, TRUE),
  ('c1000000-0000-0000-0000-000000000009', 'b1000000-0000-0000-0000-000000000006', 'Soumettre ta solution', 'challenge', 60, 50, 1, FALSE)
ON CONFLICT (id) DO NOTHING;


-- ── CONTENUS ────────────────────────────────────────────────

INSERT INTO elearning_lesson_content (id, lesson_id, content_data)
VALUES

  -- Article : Le numérique en Afrique
  ('d1000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000001', '{
    "html_content": "<h2>Le numérique en Afrique</h2><p>L''Afrique est l''un des continents qui connaît la croissance numérique la plus rapide au monde. Le nombre d''internautes africains a doublé en 5 ans.</p><h3>Les opportunités</h3><ul><li>Startups technologiques en plein essor</li><li>Demande croissante en développeurs et designers</li><li>Programmes de formation accessibles</li></ul><p>Au Togo, des hubs comme <strong>Digital Africa</strong> et <strong>Lomé Tech Hub</strong> accompagnent les jeunes talents.</p>",
    "read_time_minutes": 8
  }'),

  -- Vidéo : Présentation des métiers tech
  ('d1000000-0000-0000-0000-000000000002', 'c1000000-0000-0000-0000-000000000002', '{
    "youtube_id": "dQw4w9WgXcQ",
    "video_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
    "transcript": "Dans cette vidéo, nous explorons les principaux métiers du numérique..."
  }'),

  -- Quiz : Quel profil tech es-tu ?
  ('d1000000-0000-0000-0000-000000000003', 'c1000000-0000-0000-0000-000000000003', '{
    "pass_score_pct": 50,
    "questions": [
      {
        "id": "q1",
        "text": "Tu préfères créer des interfaces visuelles attrayantes ou résoudre des problèmes logiques complexes ?",
        "options": [
          {"id": "q1a", "text": "Créer des interfaces visuelles"},
          {"id": "q1b", "text": "Résoudre des problèmes logiques"},
          {"id": "q1c", "text": "Un peu des deux"}
        ],
        "correct_option_id": "q1c"
      },
      {
        "id": "q2",
        "text": "Quelle technologie t''attire le plus ?",
        "options": [
          {"id": "q2a", "text": "Intelligence Artificielle"},
          {"id": "q2b", "text": "Développement web/mobile"},
          {"id": "q2c", "text": "Cybersécurité"}
        ],
        "correct_option_id": "q2a"
      },
      {
        "id": "q3",
        "text": "Tu aimes travailler avec des données et des statistiques ?",
        "options": [
          {"id": "q3a", "text": "Oui, c''est passionnant"},
          {"id": "q3b", "text": "Non, je préfère le code pur"},
          {"id": "q3c", "text": "Ça dépend du contexte"}
        ],
        "correct_option_id": "q3a"
      }
    ]
  }'),

  -- PDF : Ressources métiers
  ('d1000000-0000-0000-0000-000000000004', 'c1000000-0000-0000-0000-000000000004', '{
    "pdf_url": "https://www.africau.edu/images/default/sample.pdf",
    "filename": "guide_metiers_numeriques_togo.pdf",
    "page_count": 12
  }'),

  -- Article : Évaluer tes points forts
  ('d1000000-0000-0000-0000-000000000005', 'c1000000-0000-0000-0000-000000000005', '{
    "html_content": "<h2>Évalue tes points forts</h2><p>Avant de choisir une filière, il est essentiel de bien te connaître. Quelles sont tes matières favorites ? Tes activités extrascolaires ? Tes rêves ?</p><h3>3 questions à te poser</h3><ol><li>Dans quelles matières obtiens-tu les meilleures notes ?</li><li>Qu''est-ce qui t''anime quand tu n''es pas en cours ?</li><li>Quel problème dans le monde voudrais-tu résoudre ?</li></ol>",
    "read_time_minutes": 6
  }'),

  -- PDF : Guide orientation
  ('d1000000-0000-0000-0000-000000000006', 'c1000000-0000-0000-0000-000000000006', '{
    "pdf_url": "https://www.africau.edu/images/default/sample.pdf",
    "filename": "guide_orientation_postbac.pdf",
    "page_count": 20
  }'),

  -- Quiz : Quelle filière ?
  ('d1000000-0000-0000-0000-000000000007', 'c1000000-0000-0000-0000-000000000007', '{
    "pass_score_pct": 60,
    "questions": [
      {
        "id": "q1",
        "text": "Quelle matière préfères-tu ?",
        "options": [
          {"id": "q1a", "text": "Mathématiques"},
          {"id": "q1b", "text": "Sciences naturelles"},
          {"id": "q1c", "text": "Lettres et langues"},
          {"id": "q1d", "text": "Sciences économiques"}
        ],
        "correct_option_id": "q1a"
      },
      {
        "id": "q2",
        "text": "Dans quel environnement de travail te vois-tu ?",
        "options": [
          {"id": "q2a", "text": "Bureau / open space"},
          {"id": "q2b", "text": "Terrain / extérieur"},
          {"id": "q2c", "text": "Hôpital / clinique"},
          {"id": "q2d", "text": "Salle de classe / formation"}
        ],
        "correct_option_id": "q2a"
      }
    ]
  }'),

  -- Article : Brief hackathon
  ('d1000000-0000-0000-0000-000000000008', 'c1000000-0000-0000-0000-000000000008', '{
    "html_content": "<h2>Le Brief du Hackathon</h2><p>Ce hackathon te demande d''identifier <strong>un problème concret dans ta communauté</strong> et de proposer une solution innovante, réaliste et impactante.</p><h3>Règles</h3><ul><li>Équipes de 2 à 5 personnes</li><li>Durée : 48h</li><li>La solution doit être présentable sous forme de prototype ou pitch deck</li></ul><h3>Thématiques possibles</h3><ul><li>Agriculture et alimentation</li><li>Éducation et accès au savoir</li><li>Santé communautaire</li><li>Mobilité et transport</li></ul>",
    "read_time_minutes": 10
  }'),

  -- Challenge : Soumettre ta solution
  ('d1000000-0000-0000-0000-000000000009', 'c1000000-0000-0000-0000-000000000009', '{
    "description": "Tu as lu le brief, tu as une idée ? C''est le moment de la développer et de la soumettre !",
    "objectives": [
      "Identifier un problème précis dans ta communauté",
      "Décrire ta solution en 300 mots maximum",
      "Expliquer comment tu mesureras l''impact",
      "Présenter les ressources nécessaires"
    ],
    "submission_form_url": "https://forms.google.com",
    "deadline": "2026-04-30T23:59:00+00:00",
    "difficulty": "intermediaire"
  }')

ON CONFLICT (id) DO NOTHING;
