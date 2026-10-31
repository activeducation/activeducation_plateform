import { NextResponse } from 'next/server';
import { requireAdmin } from '@/utils/auth';
import { apiError } from '@/lib/api';
import { runScholarshipAgent } from '@/lib/agents/scholarshipAgent';

export async function POST() {
  try {
    const { errorResponse } = await requireAdmin();
    if (errorResponse) return errorResponse;

    const stats = await runScholarshipAgent();
    return NextResponse.json({
      success: true,
      message: `Synchronisation réussie : ${stats.inserted} insérées, ${stats.updated} actualisées.`,
      stats
    });
  } catch (error) {
    return apiError(error);
  }
}
