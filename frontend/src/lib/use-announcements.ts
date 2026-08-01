'use client';
import { useEffect, useState } from 'react';
import { useAuth } from '@/lib/auth';
import { api } from '@/lib/api';

interface AnnouncementSummary {
  id: string;
  created_at: string;
}

const STORAGE_KEY = 'read_announcements';

export function getReadAnnouncementIds(): Set<string> {
  if (typeof window === 'undefined') return new Set();
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return new Set(raw ? JSON.parse(raw) : []);
  } catch {
    return new Set();
  }
}

export function markAnnouncementRead(id: string) {
  const set = getReadAnnouncementIds();
  set.add(id);
  const arr = Array.from(set).slice(-200);
  localStorage.setItem(STORAGE_KEY, JSON.stringify(arr));
  if (typeof window !== 'undefined') {
    window.dispatchEvent(new Event('announcements-read'));
  }
}

export function useUnreadAnnouncementsCount() {
  const { user } = useAuth();
  const [count, setCount] = useState(0);

  useEffect(() => {
    if (!user) {
      setCount(0);
      return;
    }
    let cancelled = false;
    const update = () => {
      api.get<AnnouncementSummary[]>('/announcements?audience=students&limit=50')
        .then(items => {
          if (cancelled) return;
          const read = getReadAnnouncementIds();
          setCount(items.filter(a => !read.has(a.id)).length);
        })
        .catch(() => { if (!cancelled) setCount(0); });
    };
    update();
    const onRead = () => update();
    window.addEventListener('announcements-read', onRead);
    return () => {
      cancelled = true;
      window.removeEventListener('announcements-read', onRead);
    };
  }, [user]);

  return count;
}
