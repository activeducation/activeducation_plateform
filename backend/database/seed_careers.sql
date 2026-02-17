-- =============================================================================
-- Seed: Carrieres/Metiers du Togo
-- Source: donnees hardcodees dans careers_database.dart (14 carrieres)
-- =============================================================================

-- Assurer que les secteurs existent
INSERT INTO career_sectors (name, description, icon, display_order) VALUES
    ('Technologie & IT', 'Informatique, developpement, reseaux', 'computer', 1),
    ('Sante', 'Medecine, pharmacie, soins infirmiers', 'health', 2),
    ('Education', 'Enseignement, formation, recherche', 'school', 3),
    ('Finance & Banque', 'Comptabilite, banque, assurance', 'bank', 4),
    ('Commerce & Entrepreneuriat', 'Vente, marketing, gestion', 'store', 5),
    ('Ingenierie & BTP', 'Genie civil, architecture, BTP', 'construction', 6),
    ('Agriculture & Environnement', 'Agronomie, environnement, ressources naturelles', 'agriculture', 7),
    ('Creation & Medias', 'Communication, design, audiovisuel', 'media', 8),
    ('Droit & Administration', 'Juridique, administration publique', 'law', 9)
ON CONFLICT (name) DO NOTHING;

-- Carrieres
INSERT INTO careers (name, description, sector_name, required_skills, related_traits, education_path, salary_min_fcfa, salary_max_fcfa, salary_avg_fcfa, salary_note, job_demand, growth_trend, outlook_description, top_employers, entrepreneurship_potential) VALUES

-- 1. Developpeur Web/Mobile
(
    'Developpeur Web/Mobile',
    'Le developpeur web/mobile concoit et cree des applications et sites web. Au Togo, ce metier est en plein essor avec la transformation numerique des entreprises et l''emergence de startups tech a Lome.',
    'Technologie & IT',
    ARRAY['Programmation (Python, JavaScript, Dart)', 'Frameworks (React, Flutter, Django)', 'Bases de donnees', 'Git & DevOps', 'Resolution de problemes'],
    ARRAY['Investigateur', 'Realiste', 'Logico-Mathematique'],
    '{"minimum_level": "BAC+2", "recommended_formations": ["Licence Informatique", "BTS Developpement", "Formations en ligne (Udemy, Coursera)", "Bootcamps coding"], "schools_in_togo": ["Universite de Lome - ENSI", "ESAG-NDE", "IPNET Institute", "ESGIS"], "duration_years": 2, "certifications": "AWS, Google Developer, Meta Developer"}',
    150000, 800000, 350000,
    'Les seniors et freelancers pour clients internationaux peuvent depasser 1M FCFA. Le remote work ouvre des opportunites.',
    'high', 'growing',
    'Tres forte demande au Togo et en Afrique de l''Ouest. Le digital se developpe rapidement.',
    ARRAY['GIM-UEMOA', 'Togocom', 'Startups (Semoa, Gozem)', 'Freelance international', 'ONG'],
    TRUE
),

-- 2. Data Analyst
(
    'Data Analyst / Scientifique des Donnees',
    'Le data analyst collecte, nettoie et analyse des donnees pour aider les entreprises a prendre de meilleures decisions. Metier emergent au Togo avec de belles perspectives.',
    'Technologie & IT',
    ARRAY['Statistiques et mathematiques', 'Python / R', 'SQL et bases de donnees', 'Visualisation (Tableau, Power BI)', 'Machine Learning (bases)'],
    ARRAY['Investigateur', 'Conventionnel', 'Logico-Mathematique'],
    '{"minimum_level": "BAC+3", "recommended_formations": ["Licence/Master en Statistiques", "Licence Informatique + specialisation", "Certifications Google Data Analytics", "Formations en ligne specialisees"], "schools_in_togo": ["Universite de Lome - Maths/Info", "ENSI", "CERSA"], "duration_years": 3, "certifications": "Google Data Analytics, IBM Data Science, AWS"}',
    200000, 900000, 400000,
    'Les data scientists experimentes et les consultants peuvent depasser 1.5M FCFA, surtout pour des clients internationaux.',
    'high', 'growing',
    'Demande croissante partout. Peu de professionnels formes au Togo = opportunite.',
    ARRAY['Banques', 'Telecoms', 'ONG (donnees de developpement)', 'Startups', 'Consulting'],
    TRUE
),

-- 3. Medecin
(
    'Medecin',
    'Le medecin diagnostique et traite les maladies. Au Togo, le ratio medecin/habitant est faible, ce qui en fait un metier tres demande avec un impact social important.',
    'Sante',
    ARRAY['Sciences medicales', 'Diagnostic clinique', 'Empathie et communication', 'Resistance au stress', 'Formation continue'],
    ARRAY['Investigateur', 'Social', 'Naturaliste'],
    '{"minimum_level": "BAC+7", "recommended_formations": ["Doctorat en Medecine", "Specialisation (3-5 ans supplementaires)"], "schools_in_togo": ["Faculte des Sciences de la Sante - UL", "Ecoles de medecine au Benin, Senegal, Maroc"], "duration_years": 7, "certifications": "These de doctorat + Inscription Ordre des Medecins"}',
    250000, 1500000, 600000,
    'Les specialistes et medecins en clinique privee gagnent significativement plus. Possibilite d''exercice a l''international.',
    'high', 'growing',
    'Le Togo a un deficit important de medecins. Les specialistes sont particulierement recherches.',
    ARRAY['CHU Sylvanus Olympio', 'Cliniques privees', 'ONG medicales (MSF, etc.)', 'Hopitaux de district'],
    TRUE
),

-- 4. Pharmacien
(
    'Pharmacien',
    'Le pharmacien delivre les medicaments, conseille les patients et peut gerer sa propre officine. Profession reglementee avec de bonnes perspectives au Togo.',
    'Sante',
    ARRAY['Sciences pharmaceutiques', 'Chimie et biologie', 'Conseil patient', 'Gestion d''officine', 'Reglementation pharmaceutique'],
    ARRAY['Investigateur', 'Conventionnel', 'Naturaliste'],
    '{"minimum_level": "BAC+6", "recommended_formations": ["Doctorat en Pharmacie"], "schools_in_togo": ["FSS - Universite de Lome", "Facultes de pharmacie (Benin, Senegal)"], "duration_years": 6, "certifications": "These + Inscription Ordre des Pharmaciens"}',
    300000, 1200000, 500000,
    'Les proprietaires de pharmacies peuvent gagner beaucoup plus. L''industrie pharmaceutique offre aussi des opportunites.',
    'medium', 'stable',
    'Nombre de pharmaciens reglemente. Marche stable avec bonnes opportunites pour les pharmacies en zone rurale.',
    ARRAY['Pharmacies officinales', 'Hopitaux', 'Industrie pharmaceutique', 'Grossistes (SOTOMED, etc.)'],
    TRUE
),

-- 5. Enseignant
(
    'Enseignant',
    'L''enseignant transmet des connaissances et forme les futures generations. Metier noble et crucial pour le developpement du Togo. Options variees: primaire, secondaire, superieur.',
    'Education',
    ARRAY['Maitrise de la matiere', 'Pedagogie', 'Patience', 'Communication', 'Gestion de classe'],
    ARRAY['Social', 'Artistique', 'Linguistique'],
    '{"minimum_level": "BAC+3", "recommended_formations": ["CAPES (Certificat d''Aptitude au Professorat)", "Licence dans la discipline + formation pedagogique", "ENS (Ecole Normale Superieure)"], "schools_in_togo": ["ENS Atakpame", "Universite de Lome", "ENI (Enseignement Primaire)"], "duration_years": 3, "certifications": "CAPES, CAEN selon le niveau"}',
    100000, 350000, 180000,
    'Salaires dans le public selon l''echelon. Ecoles privees internationales paient mieux (300K+).',
    'high', 'stable',
    'Besoin constant d''enseignants qualifies. Les matieres scientifiques et l''anglais sont tres demandes.',
    ARRAY['Education Nationale', 'Ecoles privees', 'Etablissements internationaux', 'Cours particuliers'],
    TRUE
),

-- 6. Comptable
(
    'Comptable',
    'Le comptable gere les comptes, etablit les bilans et assure la conformite financiere des entreprises. Profession essentielle pour toute organisation.',
    'Finance & Banque',
    ARRAY['Comptabilite generale et analytique', 'Maitrise des logiciels comptables', 'Fiscalite', 'Rigueur et precision', 'Organisation'],
    ARRAY['Conventionnel', 'Investigateur', 'Logico-Mathematique'],
    '{"minimum_level": "BAC+2", "recommended_formations": ["BTS Comptabilite", "Licence en Comptabilite", "DCG (Diplome de Comptabilite et Gestion)", "DSCG, Expert-Comptable"], "schools_in_togo": ["ESAG-NDE", "UCAO", "Universite de Lome - FASEG", "ESGIS"], "duration_years": 2, "certifications": "Inscription OECT pour Expert-Comptable"}',
    120000, 600000, 250000,
    'Les experts-comptables et directeurs financiers peuvent depasser 800K FCFA. Cabinet propre tres lucratif.',
    'high', 'stable',
    'Toute entreprise a besoin d''un comptable. Demande stable et opportunites d''evolution.',
    ARRAY['Cabinets comptables', 'Banques', 'Entreprises diverses', 'ONG'],
    TRUE
),

-- 7. Agent Bancaire
(
    'Agent Bancaire',
    'L''agent bancaire gere les operations bancaires, conseille les clients sur les produits financiers et participe au developpement commercial de la banque.',
    'Finance & Banque',
    ARRAY['Connaissances bancaires', 'Relation client', 'Commercial', 'Analyse financiere', 'Discretion'],
    ARRAY['Entrepreneur', 'Conventionnel', 'Social'],
    '{"minimum_level": "BAC+3", "recommended_formations": ["Licence en Banque-Finance", "Master en Finance", "BTS Banque"], "schools_in_togo": ["FASEG - Universite de Lome", "ESAG-NDE", "UCAO", "ESGIS"], "duration_years": 3, "certifications": "Certifications bancaires internes"}',
    200000, 800000, 350000,
    'Primes et avantages importants dans les grandes banques. Les directeurs d''agence depassent 1M FCFA.',
    'medium', 'stable',
    'Secteur bancaire mature mais en evolution digitale. Nouvelles competences tech recherchees.',
    ARRAY['Ecobank', 'ORABANK', 'BTCI', 'UTB', 'Coris Bank'],
    FALSE
),

-- 8. Commercial / Chef des Ventes
(
    'Commercial / Chef des Ventes',
    'Le commercial developpe le portefeuille clients, negocie les contrats et atteint les objectifs de vente. Role cle pour la croissance des entreprises.',
    'Commerce & Entrepreneuriat',
    ARRAY['Negociation', 'Persuasion', 'Relation client', 'Atteinte d''objectifs', 'Resistance au stress'],
    ARRAY['Entrepreneur', 'Social', 'Interpersonnelle'],
    '{"minimum_level": "BAC+2", "recommended_formations": ["BTS Commerce", "Licence Marketing", "Master Commerce International"], "schools_in_togo": ["ESAG-NDE", "ESGIS", "UCAO", "Universite de Lome"], "duration_years": 2, "certifications": "Formations commerciales certifiantes"}',
    100000, 700000, 250000,
    'Commissions et primes peuvent doubler le salaire fixe. Les top performers gagnent tres bien.',
    'high', 'growing',
    'Toujours besoin de bons commerciaux. Secteurs FMCG, telecom et tech tres actifs.',
    ARRAY['Nestle', 'Unilever', 'Telecoms', 'Banques', 'Distribution'],
    TRUE
),

-- 9. Entrepreneur / Chef d'Entreprise
(
    'Entrepreneur / Chef d''Entreprise',
    'L''entrepreneur cree et developpe sa propre entreprise. Au Togo, l''ecosysteme entrepreneurial se developpe avec de nombreuses opportunites dans le digital, l''agribusiness et les services.',
    'Commerce & Entrepreneuriat',
    ARRAY['Vision strategique', 'Leadership', 'Gestion financiere', 'Resilience', 'Networking'],
    ARRAY['Entrepreneur', 'Artistique', 'Intrapersonnelle'],
    '{"minimum_level": "Variable", "recommended_formations": ["Tout diplome pertinent au secteur", "Formations en entrepreneuriat", "MBA (optionnel)"], "schools_in_togo": ["Incubateurs: Woelab, CUBE", "FAIEJ", "Formations GIZ, AFD"], "duration_years": 0, "certifications": "Pas obligatoire, formations en gestion recommandees"}',
    0, 5000000, 300000,
    'Revenus tres variables. Premiers mois/annees difficiles. Potentiel de gains illimite avec le succes.',
    'high', 'growing',
    'Le Togo encourage l''entrepreneuriat (FAIEJ, fonds). Opportunites dans le digital, l''agro et les services.',
    ARRAY['Votre propre entreprise'],
    TRUE
),

-- 10. Ingenieur Civil / BTP
(
    'Ingenieur Civil / BTP',
    'L''ingenieur civil concoit et supervise la construction d''infrastructures: routes, batiments, ponts. Secteur en croissance avec les projets de developpement au Togo.',
    'Ingenierie & BTP',
    ARRAY['Calcul de structures', 'Logiciels CAO (AutoCAD, etc.)', 'Gestion de chantier', 'Connaissances materiaux', 'Travail en equipe'],
    ARRAY['Realiste', 'Investigateur', 'Spatiale'],
    '{"minimum_level": "BAC+5", "recommended_formations": ["Diplome d''Ingenieur Genie Civil", "Master en BTP"], "schools_in_togo": ["ENSI - Universite de Lome", "FORMATEC", "Ecoles d''ingenieurs au Maroc, Senegal"], "duration_years": 5, "certifications": "Inscription Ordre des Ingenieurs"}',
    250000, 1200000, 500000,
    'Les chefs de projet et directeurs techniques depassent 1M FCFA. Expatriation lucrative.',
    'high', 'growing',
    'Nombreux projets d''infrastructure au Togo. Demande forte pour ingenieurs qualifies.',
    ARRAY['Entreprises BTP locales', 'Groupes internationaux', 'Administration (Ministere)', 'Bureaux d''etudes'],
    TRUE
),

-- 11. Architecte
(
    'Architecte',
    'L''architecte concoit des batiments en alliant esthetique, fonctionnalite et normes techniques. Metier creatif tres demande dans un Togo en construction.',
    'Ingenierie & BTP',
    ARRAY['Conception architecturale', 'Logiciels 3D (Revit, SketchUp)', 'Creativite', 'Connaissance des normes', 'Relation client'],
    ARRAY['Artistique', 'Realiste', 'Spatiale'],
    '{"minimum_level": "BAC+5", "recommended_formations": ["Diplome d''Architecte"], "schools_in_togo": ["EAMAU (Ecole Africaine) - Lome", "Ecoles d''architecture au Maroc, Benin"], "duration_years": 5, "certifications": "Inscription Ordre des Architectes"}',
    200000, 1000000, 450000,
    'Les architectes avec leur propre cabinet et des projets prestigieux gagnent bien plus.',
    'medium', 'growing',
    'Croissance urbaine = besoin d''architectes. Marches publics et prives en developpement.',
    ARRAY['Cabinets d''architecture', 'Entreprises BTP', 'Ministere de l''Urbanisme', 'Freelance'],
    TRUE
),

-- 12. Ingenieur Agronome
(
    'Ingenieur Agronome',
    'L''agronome ameliore les techniques agricoles, conseille les agriculteurs et developpe des solutions pour augmenter les rendements. Secteur cle au Togo, pays a vocation agricole.',
    'Agriculture & Environnement',
    ARRAY['Sciences agronomiques', 'Connaissance des cultures locales', 'Conseil agricole', 'Gestion de projet', 'Travail terrain'],
    ARRAY['Realiste', 'Investigateur', 'Naturaliste'],
    '{"minimum_level": "BAC+5", "recommended_formations": ["Diplome d''Ingenieur Agronome", "Master en Agronomie"], "schools_in_togo": ["ESA - Universite de Lome", "INFA de Tove", "Ecoles au Benin, Senegal, Maroc"], "duration_years": 5, "certifications": "Certifications en agriculture durable"}',
    150000, 700000, 350000,
    'ONG et organisations internationales paient bien. L''agribusiness propre peut etre tres lucratif.',
    'high', 'growing',
    'Agriculture = 40% du PIB togolais. Fort potentiel dans l''agribusiness et l''agriculture durable.',
    ARRAY['Ministere de l''Agriculture', 'ONG (GIZ, PNUD)', 'Entreprises agro-alimentaires', 'Agribusiness prive'],
    TRUE
),

-- 13. Designer Graphique
(
    'Designer Graphique',
    'Le designer graphique cree des visuels pour la communication: logos, affiches, interfaces web. Metier creatif en forte demande avec la digitalisation.',
    'Creation & Medias',
    ARRAY['Creativite visuelle', 'Maitrise Adobe (Photoshop, Illustrator)', 'Sens artistique', 'Tendances design', 'Communication client'],
    ARRAY['Artistique', 'Entrepreneur', 'Spatiale'],
    '{"minimum_level": "BAC+2", "recommended_formations": ["BTS Design Graphique", "Licence en Arts Graphiques", "Formations professionnelles (3-6 mois)"], "schools_in_togo": ["IBTC", "Formations privees diverses", "Apprentissage autodidacte + portfolio"], "duration_years": 2, "certifications": "Adobe Certified, experience et portfolio cles"}',
    80000, 450000, 200000,
    'Le freelance pour clients internationaux peut rapporter bien plus. Portfolio = cle du succes.',
    'high', 'growing',
    'Tout business a besoin de visuels. Forte demande locale et opportunites internationales en freelance.',
    ARRAY['Agences de communication', 'Entreprises diverses', 'Freelance', 'Startups'],
    TRUE
),

-- 14. Journaliste
(
    'Journaliste',
    'Le journaliste collecte, verifie et diffuse l''information. Au Togo, les medias se diversifient avec le digital, creant de nouvelles opportunites.',
    'Creation & Medias',
    ARRAY['Redaction et style', 'Curiosite et investigation', 'Ethique journalistique', 'Outils multimedia', 'Reseaux sociaux'],
    ARRAY['Artistique', 'Social', 'Linguistique'],
    '{"minimum_level": "BAC+3", "recommended_formations": ["Licence en Journalisme", "Licence en Communication", "Master Journalisme"], "schools_in_togo": ["ISICA", "Universite de Lome - Communication", "ESTACOM"], "duration_years": 3, "certifications": "Carte de presse"}',
    80000, 400000, 180000,
    'Les medias internationaux et correspondants etrangers sont mieux payes. Piges complementaires possibles.',
    'medium', 'stable',
    'Medias traditionnels en difficulte mais le digital ouvre de nouvelles voies (podcasts, YouTube).',
    ARRAY['Togovi TV', 'TVT', 'Medias en ligne', 'Correspondants presse etrangere'],
    TRUE
),

-- 15. Avocat
(
    'Avocat',
    'L''avocat defend et conseille ses clients en matiere juridique. Profession prestigieuse necessitant rigueur et eloquence.',
    'Droit & Administration',
    ARRAY['Droit et jurisprudence', 'Eloquence et argumentation', 'Analyse et synthese', 'Ethique professionnelle', 'Negociation'],
    ARRAY['Entrepreneur', 'Social', 'Linguistique'],
    '{"minimum_level": "BAC+5", "recommended_formations": ["Maitrise en Droit", "CAPA (Certificat d''Aptitude a la Profession d''Avocat)"], "schools_in_togo": ["Faculte de Droit - Universite de Lome", "Stage au Barreau de Lome"], "duration_years": 5, "certifications": "Inscription au Barreau"}',
    200000, 2000000, 500000,
    'Les avocats d''affaires et cabinets internationaux gagnent beaucoup plus. Reputation = revenus.',
    'medium', 'stable',
    'Besoin constant de juristes. Le droit des affaires et international sont porteurs.',
    ARRAY['Cabinets d''avocats', 'Entreprises (direction juridique)', 'Organisations internationales', 'Independant'],
    TRUE
),

-- 16. Responsable Ressources Humaines
(
    'Responsable Ressources Humaines',
    'Le RH gere le recrutement, la formation, les carrieres et les relations sociales. Fonction strategique dans les organisations modernes.',
    'Droit & Administration',
    ARRAY['Gestion des talents', 'Droit du travail', 'Communication', 'Psychologie', 'Organisation'],
    ARRAY['Social', 'Conventionnel', 'Interpersonnelle'],
    '{"minimum_level": "BAC+3", "recommended_formations": ["Licence en GRH", "Master RH", "Master en Psychologie du travail"], "schools_in_togo": ["FASEG - Universite de Lome", "ESAG-NDE", "UCAO"], "duration_years": 3, "certifications": "Certifications SHRM, formations continues"}',
    150000, 700000, 300000,
    'Les DRH de grandes entreprises et multinationales depassent 1M FCFA avec avantages.',
    'medium', 'growing',
    'La gestion des talents devient strategique. Competences en digital RH recherchees.',
    ARRAY['Grandes entreprises', 'Multinationales', 'ONG', 'Cabinets de recrutement'],
    TRUE
)

ON CONFLICT DO NOTHING;
