const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api/v1';

class ApiError extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}

// --- Cache mémoire in-flight + stale-while-revalidate ---
type CacheEntry<T> = { data: T; ts: number };
const memCache = new Map<string, CacheEntry<unknown>>();
const inFlight = new Map<string, Promise<unknown>>();

// TTL par endpoint (ms). Endpoints de référence longs, endpoints user courts.
const TTL_MS: Record<string, number> = {
  '/auth/me': 30_000,
  '/orientation/tests': 5 * 60_000,
  '/orientation/careers': 5 * 60_000,
  '/schools': 2 * 60_000,
  '/elearning/courses': 2 * 60_000,
  '/gamification/leaderboard': 60_000,
  '/opportunities': 60_000,
  '/announcements': 60_000,
};
const DEFAULT_TTL = 30_000; // 30s pour tout le reste

function getTtl(endpoint: string): number {
  for (const key in TTL_MS) {
    if (endpoint.startsWith(key)) return TTL_MS[key];
  }
  return DEFAULT_TTL;
}

function shouldCache(endpoint: string, method: string): boolean {
  if (method !== 'GET') return false;
  // Ne pas cacher les endpoints utilisateur (auth, profile, progress)
  if (endpoint.startsWith('/auth/') && endpoint !== '/auth/me') return false;
  if (endpoint.startsWith('/gamification/profile')) return false;
  if (endpoint.startsWith('/aida/chat')) return false;
  if (endpoint.startsWith('/elearning/my-courses')) return false;
  if (endpoint.startsWith('/notifications')) return false;
  if (endpoint.includes('/progress')) return false;
  // Le détail d'une école est modifiable depuis l'administration : ne pas
  // conserver une ancienne bannière lors d'une nouvelle navigation.
  if (/^\/schools\/[^/?]+/.test(endpoint)) return false;
  return true;
}

async function request<T>(
  endpoint: string,
  options: RequestInit = {},
  _retry = false
): Promise<T> {
  const method = (options.method || 'GET').toUpperCase();
  const cacheable = shouldCache(endpoint, method);
  const cacheKey = `${method} ${endpoint}`;

  // 1. Cache mémoire hit → retour immédiat
  if (cacheable) {
    const hit = memCache.get(cacheKey) as CacheEntry<T> | undefined;
    if (hit && Date.now() - hit.ts < getTtl(endpoint)) {
      return hit.data;
    }
  }

  // 2. Requête déjà en vol → déduplication
  if (cacheable && inFlight.has(cacheKey)) {
    return inFlight.get(cacheKey) as Promise<T>;
  }

  const token = typeof window !== 'undefined' ? localStorage.getItem('access_token') : null;
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const exec = async (): Promise<T> => {
    const res = await fetch(`${API_BASE}${endpoint}`, { ...options, headers });

    if (res.status === 401 && token && !_retry) {
      const refreshed = await refreshToken();
      if (refreshed) {
        headers['Authorization'] = `Bearer ${localStorage.getItem('access_token')}`;
        const retryRes = await fetch(`${API_BASE}${endpoint}`, { ...options, headers });
        if (!retryRes.ok) {
          const err = await retryRes.json().catch(() => ({ detail: 'Request failed' }));
          throw new ApiError(err.detail || 'Request failed', retryRes.status);
        }
        const data = await retryRes.json();
        if (cacheable) memCache.set(cacheKey, { data, ts: Date.now() });
        return data as T;
      }
      localStorage.removeItem('access_token');
      localStorage.removeItem('refresh_token');
      if (typeof window !== 'undefined') window.location.href = '/login';
      throw new ApiError('Unauthorized', 401);
    }

    if (!res.ok) {
      const err = await res.json().catch(() => ({ detail: 'Request failed' }));
      throw new ApiError(err.message || err.detail || 'Request failed', res.status);
    }

    if (res.status === 204) return {} as T;
    const data = await res.json();
    if (cacheable) memCache.set(cacheKey, { data, ts: Date.now() });
    return data as T;
  };

  const promise = exec().finally(() => {
    if (cacheable) inFlight.delete(cacheKey);
  });

  if (cacheable) inFlight.set(cacheKey, promise);
  return promise;
}

async function refreshToken(): Promise<boolean> {
  const refresh = localStorage.getItem('refresh_token');
  if (!refresh) return false;
  try {
    const res = await fetch(`${API_BASE}/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refresh_token: refresh }),
    });
    if (!res.ok) return false;
    const data = await res.json();
    localStorage.setItem('access_token', data.access_token);
    localStorage.setItem('refresh_token', data.refresh_token);
    return true;
  } catch {
    return false;
  }
}

export const api = {
  get: <T>(endpoint: string) => request<T>(endpoint),
  post: <T>(endpoint: string, body?: unknown) =>
    request<T>(endpoint, { method: 'POST', body: body ? JSON.stringify(body) : undefined }),
  patch: <T>(endpoint: string, body: unknown) =>
    request<T>(endpoint, { method: 'PATCH', body: JSON.stringify(body) }),
  put: <T>(endpoint: string, body: unknown) =>
    request<T>(endpoint, { method: 'PUT', body: JSON.stringify(body) }),
  delete: <T>(endpoint: string) => request<T>(endpoint, { method: 'DELETE' }),
  // Invalide le cache (utile après login/logout ou mutations)
  invalidate: (prefix?: string) => {
    if (!prefix) {
      memCache.clear();
      return;
    }
    for (const key of memCache.keys()) {
      if (key.startsWith('GET ') && key.includes(prefix)) memCache.delete(key);
    }
  },
};
