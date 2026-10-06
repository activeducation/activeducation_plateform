export type CourseCategory = 'Informatique' | 'Orientation' | 'Business' | 'Sciences';

export type CourseDifficulty = 'Débutant' | 'Intermédiaire' | 'Avancé';

export interface Course {
  id: string;
  title: string;
  description: string;
  category: CourseCategory;
  difficulty: CourseDifficulty;
  duration: string;
  durationMinutes: number;
  lessonsCount: number;
  xpReward: number;
  partner?: string;
}

export interface StudentProfile {
  fullName: string;
  schoolLevel: string;
  location: string;
}

export interface Achievement {
  id: string;
  title: string;
  description: string;
  isUnlocked: boolean;
  unlockedAt?: string;
  iconName: 'trophy' | 'flame' | 'award' | 'zap' | 'sparkles';
}

export interface CompletedLesson {
  id: string;
  title: string;
  courseTitle: string;
  category: CourseCategory;
  xpEarned: number;
  completedAgo: string;
}

export interface StudentProgression {
  student: StudentProfile;
  currentLevel: number;
  levelTitle: string;
  currentXp: number;
  nextLevelXp: number;
  completedLessonsCount: number;
  totalLessonsCount: number;
  dailyStreak: number;
  longestStreak: number;
  isActiveToday: boolean;
  leaderboardRank: number;
  achievements: Achievement[];
  recentCompletedLessons: CompletedLesson[];
}
