'use client';
import { createContext, useContext, useState, useEffect, useCallback, type ReactNode } from 'react';
import { api } from './api';
import type { User } from './types';

interface AuthContextType {
  user: User | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (data: { email: string; password: string; firstName?: string; lastName?: string }) => Promise<void>;
  logout: () => void;
  refreshUser: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  const refreshUser = useCallback(async () => {
    const token = localStorage.getItem('access_token');
    if (!token) { setLoading(false); return; }
    try {
      const u = await api.get<User>('/auth/me');
      setUser(u);
    } catch {
      localStorage.removeItem('access_token');
      localStorage.removeItem('refresh_token');
      setUser(null);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { refreshUser(); }, [refreshUser]);

  // Précharge les données lourdes de la home en arrière-plan
  useEffect(() => {
    if (typeof window === 'undefined') return;
    if (!localStorage.getItem('access_token')) return;
    const timer = setTimeout(() => {
      Promise.allSettled([
        api.get('/gamification/profile').catch(() => null),
        api.get('/orientation/tests').catch(() => []),
        api.get('/elearning/my-courses').catch(() => ({ courses: [] })),
      ]);
    }, 100);
    return () => clearTimeout(timer);
  }, []);

  const login = async (email: string, password: string) => {
    const data = await api.post<{ user: User; tokens: { access_token: string; refresh_token: string } }>('/auth/login', { email, password });
    localStorage.setItem('access_token', data.tokens.access_token);
    localStorage.setItem('refresh_token', data.tokens.refresh_token);
    api.invalidate();
    setUser(data.user);
  };

  const register = async (d: { email: string; password: string; firstName?: string; lastName?: string }) => {
    const data = await api.post<{ user: User; tokens: { access_token: string; refresh_token: string } }>('/auth/register', {
      email: d.email,
      password: d.password,
      first_name: d.firstName,
      last_name: d.lastName,
    });
    localStorage.setItem('access_token', data.tokens.access_token);
    localStorage.setItem('refresh_token', data.tokens.refresh_token);
    api.invalidate();
    setUser(data.user);
  };

  const logout = () => {
    api.post('/auth/logout').catch(() => {});
    localStorage.removeItem('access_token');
    localStorage.removeItem('refresh_token');
    api.invalidate();
    setUser(null);
    window.location.href = '/login';
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, register, logout, refreshUser }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}

export function useLogout() {
  const { logout } = useAuth();
  return logout;
}
