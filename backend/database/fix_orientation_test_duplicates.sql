-- ============================================================================
-- Fix orientation test duplicates (2026-07-30)
-- ============================================================================
-- Symptom: page /orientation/test/<id> affiche chaque question 2x et chaque
-- option Likert 2x ("Pas du tout d'accord" x2, "Peu d'accord" x2, etc.).
-- Root cause: seed_tests.sql a ete rejoue sur la base live. Les INSERT
-- utilisent uuid_generate_v4() (toujours nouveaux UUIDs) sans ON CONFLICT
-- ni index unique, donc chaque re-seed cree de nouvelles lignes semantiquement
-- identiques. Resultat: les scores Likert sont doubles.
--
-- Test deja corrige in-situ: 223e4567-e89b-12d3-a456-426614174001
-- (Intelligences Multiples, 19 questions / 5 options).
--
-- Usage: coller dans Supabase Dashboard -> SQL Editor -> New query -> Run,
-- bloc par bloc, dans l'ordre. Verifier le resultat du bloc 3 avant
-- de considerer le fix termine.
-- ============================================================================


-- ============================================================================
-- BLOC 1 - Purge des doublons
-- ============================================================================
-- Strategie: ROW_NUMBER() partitionne par (test_id, question_text) pour les
-- questions et (question_id, option_text) pour les options; on garde rn=1
-- (id le plus petit = ligne la plus anciennement creee) et on supprime rn>1.
-- Note: les FK des tables enfants (test_results, etc.) pointent vers
-- test_id (pas question_id), donc la suppression est sure.
-- ============================================================================

-- Purge questions dupliquees pour les 8 tests impactes
WITH ranked AS (
    SELECT id,
           ROW_NUMBER() OVER (
               PARTITION BY test_id, question_text
               ORDER BY id
           ) AS rn
    FROM test_questions
    WHERE test_id IN (
        '323e4567-e89b-12d3-a456-426614174002',
        '423e4567-e89b-12d3-a456-426614174003',
        '523e4567-e89b-12d3-a456-426614174004',
        '623e4567-e89b-12d3-a456-426614174005',
        '723e4567-e89b-12d3-a456-426614174006',
        '823e4567-e89b-12d3-a456-426614174007',
        '923e4567-e89b-12d3-a456-426614174008',
        'a23e4567-e89b-12d3-a456-426614174009'
    )
)
DELETE FROM test_questions
WHERE id IN (SELECT id FROM ranked WHERE rn > 1);

-- Purge options dupliquees pour les memes 8 tests
WITH ranked AS (
    SELECT po.id,
           ROW_NUMBER() OVER (
               PARTITION BY tq.id, po.option_text
               ORDER BY po.id
           ) AS rn
    FROM question_options po
    JOIN test_questions tq ON tq.id = po.question_id
    WHERE tq.test_id IN (
        '323e4567-e89b-12d3-a456-426614174002',
        '423e4567-e89b-12d3-a456-426614174003',
        '523e4567-e89b-12d3-a456-426614174004',
        '623e4567-e89b-12d3-a456-426614174005',
        '723e4567-e89b-12d3-a456-426614174006',
        '823e4567-e89b-12d3-a456-426614174007',
        '923e4567-e89b-12d3-a456-426614174008',
        'a23e4567-e89b-12d3-a456-426614174009'
    )
)
DELETE FROM question_options
WHERE id IN (SELECT id FROM ranked WHERE rn > 1);


-- ============================================================================
-- BLOC 2 - Index uniques pour empecher la recidive
-- ============================================================================
-- Une fois les doublons purged, poser un index unique composite garantit
-- qu'un futur re-seed ne pourra plus creer de doublons (un INSERT en
-- conflit declenchera une erreur, qu'on attrape avec ON CONFLICT dans le
-- seed patche - voir schema.sql et seed_tests.sql apres ce fix).
-- ============================================================================

CREATE UNIQUE INDEX IF NOT EXISTS uq_test_questions_test_text
    ON test_questions (test_id, question_text);

CREATE UNIQUE INDEX IF NOT EXISTS uq_question_options_question_text
    ON question_options (question_id, option_text);


-- ============================================================================
-- BLOC 3 - Verification
-- ============================================================================
-- Attendu apres purge:
--   123 RIASEC           -> 18 questions
--   223 Intelligences    -> 19 questions
--   323 Valeurs          -> 10 questions
--   423 MBTI             ->  8 questions
--   523 Aptitudes        -> 10 questions
--   623 Potentiel        ->  8 questions
--   723 Ancres           -> 16 questions
--   823 VARK             -> 12 questions
--   923 Environnement    -> 12 questions
--   a23 Maturite         -> 12 questions
-- Chaque question doit avoir exactement 5 options (Pas du tout d'accord,
-- Peu d'accord, Moyennement d'accord, D'accord, Tout a fait d'accord).
-- ============================================================================

SELECT t.id,
       t.name,
       COUNT(q.id) AS questions,
       (
           SELECT COUNT(*)
           FROM question_options po
           WHERE po.question_id IN (
               SELECT id FROM test_questions WHERE test_id = t.id
           )
       ) AS total_options,
       (
           SELECT COUNT(DISTINCT po.option_text)
           FROM question_options po
           WHERE po.question_id IN (
               SELECT id FROM test_questions WHERE test_id = t.id
           )
       ) AS distinct_option_texts
FROM orientation_tests t
LEFT JOIN test_questions q ON q.test_id = t.id
WHERE t.id IN (
    '123e4567-e89b-12d3-a456-426614174000',
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
GROUP BY t.id, t.name, t.display_order
ORDER BY t.display_order;
