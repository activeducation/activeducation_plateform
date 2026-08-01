export interface User {
  id: string;
  email: string;
  first_name?: string;
  last_name?: string;
  display_name?: string;
  avatar_url?: string;
  role: string;
}

export interface AuthTokens {
  access_token: string;
  refresh_token: string;
}

export interface Course {
  id: string;
  title: string;
  description: string;
  thumbnail_url?: string;
  category: string;
  difficulty: 'debutant' | 'intermediaire' | 'avance';
  duration_minutes: number;
  points_reward: number;
  progress_pct?: number;
  is_enrolled?: boolean;
}

export interface CourseDetail extends Course {
  modules: CourseModule[];
}

export interface CourseModule {
  id: string;
  course_id: string;
  title: string;
  description?: string;
  display_order: number;
  is_locked: boolean;
  progress_pct?: number;
  lessons: LessonSummary[];
}

export interface LessonSummary {
  id: string;
  module_id: string;
  title: string;
  lesson_type: 'video' | 'article' | 'quiz' | 'pdf' | 'challenge';
  duration_minutes: number;
  points_reward: number;
  is_free: boolean;
  status?: 'not_started' | 'in_progress' | 'completed';
}

export interface LessonDetail extends LessonSummary {
  content?: LessonContent;
}

export interface LessonContent {
  type: string;
  data: Record<string, unknown>;
}

export interface GamificationProfile {
  stats: GamificationStats;
  achievements: Achievement[];
  active_challenges: Challenge[];
  next_level_xp: number;
  xp_to_next_level: number;
}

export interface GamificationStats {
  total_xp: number;
  current_level: number;
  current_streak: number;
  longest_streak: number;
  total_achievements: number;
  completed_challenges: number;
  leaderboard_rank?: number;
}

export interface Achievement {
  id: string;
  achievement_type: string;
  achievement_data: Record<string, unknown>;
  earned_at: string;
  display_name?: string;
}

export interface Challenge {
  id: string;
  challenge_id: string;
  title: string;
  description?: string;
  points: number;
  status: string;
  score?: number;
  completed_at?: string;
}

export interface LeaderboardEntry {
  user_id: string;
  display_name: string;
  avatar_url?: string;
  total_xp: number;
  current_level: number;
}

export interface OrientationTest {
  id: string;
  name: string;
  description: string;
  type: string;
  questions: Question[];
  duration_minutes?: number;
  image_url?: string | null;
}

export interface Question {
  id: string;
  text: string;
  type: string;
  options: Option[];
  section_title?: string;
  slider_left_label?: string;
  slider_right_label?: string;
}

export interface Option {
  id: string;
  text: string;
  value: number | string;
  emoji?: string;
}

export interface Career {
  id: string;
  title: string;
  description: string;
  sector: string;
  required_skills: string[];
}

export interface School {
  id: string;
  name: string;
  city: string;
  type: string;
  description?: string;
  logo_url?: string;
  country?: string;
  student_count?: number;
  rating?: number;
  is_public?: boolean;
  tuition_range?: string;
  accreditations?: string[];
}

export interface UserProfile {
  id: string;
  email: string;
  display_name?: string;
  avatar_url?: string;
  role: string;
  user_metadata?: {
    level?: number;
    xp?: number;
  };
  stats?: {
    streak: number;
    badges: number;
    totalXp: number;
    completedCourses: number;
    completedQuizzes: number;
  };
}

export interface AIDAMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  created_at?: string;
}
