import { NextResponse } from 'next/server';
import { z } from 'zod';

export class ApiError extends Error {
  constructor(public status: number, message: string) { super(message); }
}

export async function readJson(request: Request, maxBytes = 64_000): Promise<unknown> {
  if (Number(request.headers.get('content-length')) > maxBytes) throw new ApiError(413, 'Requête trop volumineuse.');
  const reader = request.body?.getReader();
  if (!reader) throw new ApiError(400, 'Corps JSON requis.');
  const chunks: Uint8Array[] = [];
  let length = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      length += value.byteLength;
      if (length > maxBytes) { await reader.cancel(); throw new ApiError(413, 'Requête trop volumineuse.'); }
      chunks.push(value);
    }
  } finally { reader.releaseLock(); }
  const bytes = new Uint8Array(length);
  let offset = 0;
  for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
  try { return JSON.parse(new TextDecoder().decode(bytes)); }
  catch { throw new ApiError(400, 'JSON invalide.'); }
}

export function apiError(error: unknown) {
  if (error instanceof ApiError) return NextResponse.json({ error: error.message }, { status: error.status });
  if (error instanceof z.ZodError) return NextResponse.json({ error: 'Données invalides.', details: error.issues }, { status: 400 });
  console.error('API request failed', error);
  return NextResponse.json({ error: 'Erreur serveur. Veuillez réessayer.' }, { status: 500 });
}
