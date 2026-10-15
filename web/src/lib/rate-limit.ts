import { sql } from 'drizzle-orm';
import { db } from '@/db';
import { apiRateLimits } from '@/db/schema';
import { ApiError } from './api';

// Atomic shared limiter: never falls back to an unbounded per-process counter.
export async function consumeQuota(userId: string, action: string, limit: number, seconds: number) {
  const key = `${action}:${userId}`;
  const [row] = await db.insert(apiRateLimits).values({ key, count: 1, resetAt: new Date(Date.now() + seconds * 1000) })
    .onConflictDoUpdate({ target: apiRateLimits.key, set: {
      count: sql`case when ${apiRateLimits.resetAt} <= now() then 1 else least(${apiRateLimits.count} + 1, ${limit + 1}) end`,
      resetAt: sql`case when ${apiRateLimits.resetAt} <= now() then now() + ${seconds} * interval '1 second' else ${apiRateLimits.resetAt} end`,
    } }).returning();
  if (row.count > limit) throw new ApiError(429, 'Limite de requêtes atteinte. Réessayez plus tard.');
}
