'use client';
import { createContext, useContext, useState, useEffect, useCallback, type ReactNode } from 'react';

type Lang = 'fr' | 'en';

interface ThemeContextType {
  darkMode: boolean;
  setDarkMode: (v: boolean) => void;
  lang: Lang;
  setLang: (v: Lang) => void;
  t: (key: string) => string;
}

const ThemeContext = createContext<ThemeContextType | null>(null);

const translations: Record<Lang, Record<string, string>> = {
  fr: {},
  en: {
    // Home
    'Découvre ta voie, joue ton avenir': 'Discover your path, play your future',
    'Chargement…': 'Loading...',
    'Prêt à jouer ton avenir ?': 'Ready to shape your future?',
    'Chercher une école, un métier...': 'Search for a school, career...',
    'Nouveau': 'New',
    'Découvre ton profil': 'Discover your profile',
    'Réponds à nos tests d\'orientation pour trouver la voie qui te correspond.': 'Take our orientation tests to find the path that suits you.',
    'Commencer les tests': 'Start the tests',
    'Ta conseillère IA · En ligne': 'Your AI advisor · Online',
    'Discuter →': 'Chat →',
    'Salut ! Je suis là pour t\'aider à trouver ta voie. Pose-moi tes questions': 'Hi! I\'m here to help you find your path. Ask me anything',
    'Quelles filières ?': 'Which fields?',
    'Métiers pour moi': 'Careers for me',
    'Écoles au Togo': 'Schools in Togo',
    'Explore tes talents': 'Explore your talents',
    'Voir tout': 'See all',
    'Stage': 'Internship',
    'Emploi': 'Job',
    'Bénévole': 'Volunteer',
    'Bourse': 'Scholarship',
    'Annonces': 'Announcements',
    'Tests d\'orientation': 'Orientation tests',
    'Explore tes aptitudes': 'Explore your skills',
    'Cours et vidéos': 'Courses and videos',
    'Écoles et universités': 'Schools and universities',
    'Classement': 'Leaderboard',
    'Compare-toi aux autres': 'Compare with others',
    'Apprendre': 'Learn',
    'E-Learning': 'E-Learning',
    'Catalogue': 'Catalog',
    'Commencer l\'apprentissage': 'Start learning',
    'Explore nos cours disponibles': 'Explore our available courses',
    'Établissements': 'Institutions',
    'Opportunités': 'Opportunities',
    'Intérêts professionnels': 'Professional interests',
    'Traits de caractère': 'Personality traits',
    'Points forts': 'Strengths',
    'Tes priorités': 'Your priorities',
    'Aptitudes naturelles': 'Natural abilities',

    // Profile
    'Bonjour': 'Hello',
    'XP TOTAL': 'TOTAL XP',
    'Badges': 'Badges',
    'Jours': 'Days',
    'Défis': 'Challenges',
    'Derniers badges': 'Latest badges',
    'Partager l\'app': 'Share the app',
    'Lien copié !': 'Link copied!',
    'Déconnexion': 'Logout',
    'Se déconnecter ?': 'Log out?',
    'Tu devras te reconnecter ensuite': 'You will need to log in again',
    'Annuler': 'Cancel',
    'Paramètres': 'Settings',
    'Confidentialité': 'Privacy',
    'Découvre ta voie avec ActivEducation !': 'Discover your path with ActivEducation!',

    // Leaderboard
    'Les meilleurs apprenants': 'Top learners',
    'Oups !': 'Oops!',
    'Impossible de charger le classement': 'Unable to load leaderboard',
    'Réessayer': 'Retry',
    'Mon classement': 'My ranking',
    'Classement général': 'General ranking',
    'Participant': 'Participant',
    'Niv.': 'Lvl.',
    'Pas assez de participants': 'Not enough participants',

    // Courses
    'Bibliothèque': 'Library',
    'Rechercher un cours...': 'Search for a course...',
    'Ma Saga': 'My Saga',
    'Succès': 'Success',
    'Tous': 'All',
    'Informatique': 'Computer Science',
    'Mathématiques': 'Mathematics',
    'Sciences': 'Sciences',
    'Orientation': 'Orientation',
    'Hackathons': 'Hackathons',
    'Continuer': 'Continue',
    'Tous les cours': 'All courses',
    'Aucun résultat': 'No results',
    'Essaie avec d\'autres mots-clés': 'Try different keywords',
    'Débutant': 'Beginner',
    'Intermédiaire': 'Intermediate',
    'Avancé': 'Advanced',
    'Facile': 'Easy',
    'Moyen': 'Medium',
    'Difficile': 'Hard',

    // Course detail
    'Inscrit': 'Enrolled',
    'À propos': 'About',
    'Voir moins': 'Show less',
    'Voir plus': 'Show more',
    'Votre progression': 'Your progress',
    'Cours terminé': 'Course completed',
    'Continuez votre apprentissage': 'Continue your learning',
    'Programme': 'Program',
    'Certificat': 'Certificate',
    'S\'inscrire gratuitement': 'Enroll for free',
    'Vidéo': 'Video',
    'Article': 'Article',
    'Quiz': 'Quiz',
    'PDF': 'PDF',
    'Challenge': 'Challenge',
    'Gratuit': 'Free',
    'Obtenez': 'Score',

    // Exam
    'Aucun examen pour ce cours.': 'No exam for this course.',
    'Retour': 'Back',
    'Félicitations !': 'Congratulations!',
    'Pas encore réussi': 'Not passed yet',
    'Correct': 'Correct',
    'Incorrect': 'Incorrect',
    'Terminer': 'Finish',
    'Retour au cours': 'Back to course',
    'Choix unique': 'Single choice',
    'Choix multiples': 'Multiple choice',
    'Réponse libre': 'Free response',
    'Ordonnancement': 'Ordering',
    'Écrivez votre réponse ici...': 'Write your answer here...',
    'Soumettre mes réponses': 'Submit my answers',
    'Répondez à toutes les questions.': 'Answer all questions.',

    // Schools
    'Annuaire des Ecoles': 'School Directory',
    'ACTIV': 'ACTIV',
    'EDUCATION': 'EDUCATION',
    'Rechercher une ecole, un BTS...': 'Search for a school, BTS...',
    'Université': 'University',
    'Grande École': 'Grande École',
    'Institut': 'Institute',
    'Centre de Formation': 'Training Center',
    'Impossible de charger les ecoles.': 'Unable to load schools.',
    'Verifiez votre connexion.': 'Check your connection.',
    'Aucune ecole trouvee': 'No school found',
    'Essaie un autre terme': 'Try another term',
    'Publique': 'Public',
    'Privee': 'Private',
    'Details': 'Details',
    'Voir filieres': 'View programs',
    'Charger plus': 'Load more',

    // School detail
    'Étudiants': 'Students',
    'Fondation': 'Founded',
    'Accréditations': 'Accreditations',
    'Programmes': 'Programs',
    'Admission': 'Admission',
    'Galerie': 'Gallery',
    'Frais de scolarité': 'Tuition fees',
    'Contact': 'Contact',

    // Mentors
    'Mentors': 'Mentors',
    'Rechercher un mentor...': 'Search for a mentor...',
    'Médecine': 'Medicine',
    'Commerce': 'Business',
    'Ingénierie': 'Engineering',
    'Droit': 'Law',
    'Marketing': 'Marketing',
    'Finance': 'Finance',
    'Tu veux devenir mentor et accompagner des élèves ?': 'Want to become a mentor and guide students?',
    'Postuler': 'Apply',
    'Aucun mentor trouvé': 'No mentor found',

    // Mentor apply
    'Candidature envoyée !': 'Application sent!',
    'Nom complet *': 'Full name *',
    'Email *': 'Email *',
    'Téléphone': 'Phone',
    'Années d\'expérience': 'Years of experience',
    'Envoi...': 'Sending...',
    'Envoyer ma candidature': 'Submit my application',

    // Orientation
    'Découvre ta voie': 'Discover your path',
    'Explorer les métiers': 'Explore careers',
    'Aucun test disponible': 'No tests available',
    'Reviens plus tard': 'Come back later',
    'Commencer': 'Start',

    // Career detail
    'Fiche métier introuvable.': 'Career not found.',
    'Retour aux résultats': 'Back to results',
    'Description': 'Description',
    'Compétences Requises': 'Required Skills',
    'Formation Requise': 'Required Education',
    'Salaires au Togo': 'Salaries in Togo',
    'FCFA/mois': 'FCFA/month',
    'Perspectives d\'Emploi': 'Employment Outlook',
    'Forte demande': 'High demand',
    'Demande modérée': 'Moderate demand',
    'Faible demande': 'Low demand',
    'En croissance': 'Growing',
    'Stable': 'Stable',
    'En déclin': 'Declining',

    // Opportunities
    'Toutes les opportunités': 'All opportunities',
    'Impossible de charger les opportunités.': 'Unable to load opportunities.',
    'Aucune opportunité disponible': 'No opportunities available',

    // Lesson
    'Complété': 'Completed',
    'Objectifs': 'Objectives',
    'Relevez le défi et gagnez des points': 'Take the challenge and earn points',
    'Soumettre ma solution': 'Submit my solution',
    'Leçon validée !': 'Lesson completed!',

    // Search
    'École, métier, cours...': 'School, career, course...',
    'Métiers & filières': 'Careers & fields',
    'Cours': 'Courses',
    'Recherche': 'Search',
    'Recherchez une école, un métier ou un cours': 'Search for a school, career or course',

    // AIDA
    'Se connecter': 'Log in',
    'Créer un compte': 'Create an account',
    'Suggestions': 'Suggestions',
    'Pose ta question...': 'Ask your question...',

    // Saga
    'Ma progression': 'My progress',
    'Aucun cours en cours': 'No courses in progress',
    'Explorer les cours': 'Explore courses',
    'Terminé': 'Completed',
    'À commencer': 'Not started',

    // Success
    'Mes Succès': 'My Success',
    'Mes récompenses': 'My rewards',
    'XP Total': 'Total XP',
    'Niveau': 'Level',
    'Aucun badge pour le moment': 'No badges yet',
    'Défis actifs': 'Active challenges',

    // Auth
    'ActivEducation': 'ActivEducation',
    'Connexion': 'Login',
    'Bienvenue ! Connectez-vous pour continuer.': 'Welcome! Log in to continue.',
    'Adresse email': 'Email address',
    'Mot de passe': 'Password',
    'OU': 'OR',
    'Pas encore de compte ?': 'Don\'t have an account?',
    'S\'inscrire': 'Sign up',
    'Inscription': 'Sign up',
    'Crée ton compte pour commencer.': 'Create your account to get started.',
    'Prénom': 'First name',
    'Nom': 'Last name',
    'Email': 'Email',
    'Confirmer le mot de passe': 'Confirm password',
    'Créer mon compte': 'Create my account',
    'Déjà un compte ?': 'Already have an account?',

    // Onboarding
    'Bienvenue sur': 'Welcome to',
    'Ton assistant d\'orientation personnalisé. Découvre les métiers qui te ressemblent.': 'Your personalized orientation assistant. Discover careers that match you.',
    'Écoles & Formations': 'Schools & Training',
    'J\'ai déjà un compte': 'I already have an account',

    // Settings / Privacy
    'Gère ton compte et tes préférences': 'Manage your account and preferences',
    'Comment nous protégeons tes données': 'How we protect your data',
    'Protection des données': 'Data protection',
    'Collecte de données': 'Data collection',
    'Sécurité du compte': 'Account security',
    'Suppression des données': 'Data deletion',
    'Cookies': 'Cookies',
    'Langue': 'Language',
    'Notifications': 'Notifications',
    'Mode sombre': 'Dark Mode',
    'Compte': 'Account',
    'Préférences': 'Preferences',
  },
};

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [darkMode, setDarkModeState] = useState(false);
  const [lang, setLangState] = useState<Lang>('fr');
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setDarkModeState(localStorage.getItem('darkMode') === 'true');
    setLangState((localStorage.getItem('lang') as Lang) || 'fr');
    setMounted(true);
  }, []);

  useEffect(() => {
    if (!mounted) return;
    document.documentElement.classList.toggle('dark', darkMode);
    localStorage.setItem('darkMode', String(darkMode));
  }, [darkMode, mounted]);

  useEffect(() => {
    if (!mounted) return;
    document.documentElement.lang = lang;
    localStorage.setItem('lang', lang);
  }, [lang, mounted]);

  const setDarkMode = useCallback((v: boolean) => setDarkModeState(v), []);
  const setLang = useCallback((v: Lang) => setLangState(v), []);

  const t = useCallback((key: string) => translations[lang]?.[key] || key, [lang]);

  return (
    <ThemeContext.Provider value={{ darkMode, setDarkMode, lang, setLang, t }}>
      {children}
    </ThemeContext.Provider>
  );
}

export function useTheme() {
  const ctx = useContext(ThemeContext);
  if (!ctx) throw new Error('useTheme must be used within ThemeProvider');
  return ctx;
}
