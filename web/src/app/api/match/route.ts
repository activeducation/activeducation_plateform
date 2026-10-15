import { NextRequest, NextResponse } from 'next/server';
import { matchOrientation, stripEmojis, sanitizeObject } from '@/lib/orientation';

export async function POST(request: NextRequest) {
  try {
    let body: Record<string, unknown> = {};
    
    try {
      body = await request.json();
    } catch {
      // Body vide ou non JSON
      body = {};
    }

    const answers = (body.answers || body.responses) as Record<string, number | boolean | string> | undefined;
    const scores = (body.scores || body.dimensionScores) as Record<string, number> | undefined;
    const context = (body.context || body.studentContext || {
      schoolLevel: body.studentLevel || body.schoolLevel,
      serieBac: body.serieBac,
      city: body.city,
    }) as { schoolLevel?: string; serieBac?: string; city?: string } | undefined;

    const result = await matchOrientation({
      answers,
      scores,
      context,
    });

    const sanitized = sanitizeObject(result);

    return NextResponse.json(sanitized, {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
      },
    });
  } catch (error) {
    console.error('Error in /api/match route handler:', error);

    return NextResponse.json(
      {
        error: stripEmojis('Une erreur est survenue lors de l’analyse de votre orientation.'),
      },
      { status: 500 }
    );
  }
}
