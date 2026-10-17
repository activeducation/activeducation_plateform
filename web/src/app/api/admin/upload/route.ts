import { NextResponse } from 'next/server';
import { requireAdmin } from '@/utils/auth';
import { createClient } from '@/utils/supabase/server';

export const dynamic = 'force-dynamic';

export async function POST(req: Request) {
  try {
    const { errorResponse } = await requireAdmin();
    if (errorResponse) return errorResponse;

    const formData = await req.formData();
    const file = formData.get('file') as File | null;
    const bucket = (formData.get('bucket') as string) || 'explorer';

    if (!file) {
      return NextResponse.json({ error: "Aucun fichier n'a été fourni." }, { status: 400 });
    }

    // Validate mime type
    const validMimeTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/svg+xml'];
    if (!validMimeTypes.includes(file.type)) {
      return NextResponse.json({ 
        error: "Format de fichier non supporté. Veuillez sélectionner une image (PNG, JPG, WEBP, SVG ou GIF)." 
      }, { status: 400 });
    }

    // Validate size (max 8MB)
    const MAX_SIZE = 8 * 1024 * 1024;
    if (file.size > MAX_SIZE) {
      return NextResponse.json({ 
        error: "L'image est trop volumineuse (maximum 8 Mo)." 
      }, { status: 400 });
    }

    const fileExt = file.name.split('.').pop()?.toLowerCase() || 'jpg';
    const cleanFileName = `${Date.now()}-${crypto.randomUUID()}.${fileExt}`;
    const filePath = `${cleanFileName}`;

    const arrayBuffer = await file.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);

    const supabase = await createClient();
    const { data, error: uploadError } = await supabase.storage
      .from(bucket)
      .upload(filePath, buffer, {
        contentType: file.type,
        upsert: true,
      });

    if (uploadError) {
      console.error("Supabase Storage upload error:", uploadError);
      return NextResponse.json({ 
        error: `Échec du téléversement : ${uploadError.message}` 
      }, { status: 500 });
    }

    const { data: { publicUrl } } = supabase.storage
      .from(bucket)
      .getPublicUrl(filePath);

    return NextResponse.json({
      url: publicUrl,
      path: data.path,
      name: file.name,
      size: file.size,
    });
  } catch (error: any) {
    console.error("Upload API route error:", error);
    return NextResponse.json({ 
      error: error.message || "Erreur interne du serveur lors de l'upload." 
    }, { status: 500 });
  }
}
