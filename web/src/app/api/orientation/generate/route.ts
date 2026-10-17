import { NextResponse } from 'next/server';
import { requireAuth } from '@/utils/auth';
import { apiError, ApiError, readJson } from '@/lib/api';
import { saveOrientation } from '@/lib/learning-service';
import { consumeQuota } from '@/lib/rate-limit';
import { db } from '@/db';
import { explorerCareers, explorerSchools } from '@/db/schema';
import { eq } from 'drizzle-orm';
import { generateObject } from 'ai';
import { createGroq } from '@ai-sdk/groq';
import { z } from 'zod';
import { sanitizeObject, generateDeterministicOrientationM3 } from '@/lib/orientation';

// Définition de la structure stricte que l'IA doit respecter (Schema Zod)
const OrientationResultSchema = z.object({
  psychologicalProfile: z.object({
    dominantTraits: z.array(z.string()).describe("Les traits dominants de l'étudiant (ex: Réaliste, Entreprenant)"),
    strengths: z.array(z.string()).describe("Points forts de l'étudiant"),
    weaknesses: z.array(z.string()).describe("Points de vigilance"),
    summary: z.string().describe("Un court paragraphe (max 3 phrases) décrivant le profil global de l'étudiant et son potentiel.")
  }),
  recommendedCareers: z.array(
    z.object({
      title: z.string().describe("Nom du métier recommandé"),
      matchPercentage: z.number().describe("Pourcentage de compatibilité (entre 0 et 100)"),
      description: z.string().describe("Pourquoi ce métier lui correspond"),
      salaryRangeCFA: z.string().describe("Fourchette de salaire mensuel estimée au Togo en FCFA (ex: 150 000 - 300 000 FCFA)"),
      demandInTogo: z.enum(['Faible', 'Moyenne', 'Forte']).describe("La demande actuelle pour ce métier au Togo")
    })
  ).length(3).describe("Exactement 3 métiers recommandés"),
  recommendedSchools: z.array(
    z.object({
      name: z.string().describe("Nom de l'Université ou École supérieure (ex: Université de Lomé, ESGIS, IAEC, IAI...)"),
      program: z.string().describe("La filière recommandée dans cette école"),
      estimatedAnnualCostCFA: z.string().describe("Coût annuel estimé en FCFA (ou 'Public/Gratuit')"),
      whyThisSchool: z.string().describe("Pourquoi cette école est recommandée par rapport au profil et budget de l'étudiant")
    })
  ).min(1).max(3).describe("Entre 1 et 3 écoles ou universités recommandées au Togo, en respectant le budget de l'étudiant"),
});

export async function POST(req: Request) {
  try {
    const { user, errorResponse } = await requireAuth();
    if (errorResponse) return errorResponse;

    const body = z.object({
      answers: z.object({
        interests: z.array(z.string().trim().min(1).max(200)).min(1).max(30),
        strongSubjects: z.array(z.string().max(200)).max(30),
        otherSubject: z.string().max(500).optional(),
        budget: z.string().max(100),
        mobility: z.string().max(200),
        currentCity: z.string().max(200),
      })
    }).parse(await readJson(req, 16_000));

    const answers = body.answers;

    // Rate limiting résilient
    try {
      await consumeQuota(user.id, 'orientation-day', 10, 86400);
    } catch (quotaErr) {
      if (quotaErr instanceof ApiError) throw quotaErr;
      console.warn('Rate limit check bypassed:', quotaErr);
    }

    let orientationResult = null;

    // Récupérer le catalogue pour enrichir le prompt de l'IA si disponible
    let careerCatalog: { title: string; description: string | null }[] = [];
    let schoolCatalog: { name: string; city: string | null }[] = [];
    try {
      const [careers, schools] = await Promise.all([
        db.select({ title: explorerCareers.title, description: explorerCareers.description }).from(explorerCareers).where(eq(explorerCareers.isPublished, true)).limit(100),
        db.select({ name: explorerSchools.name, city: explorerSchools.city }).from(explorerSchools).where(eq(explorerSchools.isPublished, true)).limit(100),
      ]);
      careerCatalog = careers;
      schoolCatalog = schools;
    } catch (dbErr) {
      console.warn('Could not fetch explorer catalog from DB:', dbErr);
    }

    // Tentative d'appel Groq IA si la clé d'API est configurée
    const apiKey = process.env.GROQ_API_KEY;
    const isValidKey = apiKey && apiKey.length > 10 && !apiKey.includes('dummy') && !apiKey.includes('test');

    if (isValidKey) {
      try {
        const groq = createGroq({ apiKey });

        const systemPrompt = `Tu es AÏDA (Intelligence Artificielle pour le Développement Académique), un conseiller d'orientation expert spécialisé sur le marché de l'emploi et de l'éducation au Togo.
Ton rôle est d'analyser le profil d'un étudiant togolais et de générer un bilan d'orientation extrêmement précis, réaliste et encourageant.

CONSIGNES STRICTES :
1. Tu dois respecter le budget de l'étudiant (s'il n'a pas de moyens, recommande l'Université de Lomé (UL) ou l'Université de Kara (UK)).
2. Les salaires doivent être réalistes pour le marché togolais en Francs CFA (ex: 250 000 - 850 000 FCFA / mois).
3. Ne recommande que des établissements réels reconnus au Togo (Université de Lomé, Université de Kara, ESGIS, IAI-Togo, EAMAU, Formatec, etc.).
4. Tes recommandations doivent être basées sur les secteurs porteurs du Togo (Agriculture, Port/Logistique, Numérique, Énergies, Santé, Commerce).
5. RÈGLE CRITIQUE : ZÉRO EMOJI dans l'intégralité du texte ou des champs.`;

        const userPrompt = `Voici les données de l'étudiant à analyser :
${JSON.stringify(answers, null, 2)}

Analyse ce profil et génère le rapport d'orientation au format JSON demandé.`;

        const { object } = await generateObject({
          model: groq(process.env.GROQ_ORIENTATION_MODEL || 'llama-3.3-70b-versatile'),
          maxOutputTokens: 2500,
          abortSignal: AbortSignal.timeout(30_000),
          maxRetries: 0,
          schema: OrientationResultSchema,
          system: systemPrompt + (careerCatalog.length && schoolCatalog.length ? '\nCatalogue de référence disponible : ' + JSON.stringify({ careerCatalog, schoolCatalog }) : ''),
          prompt: userPrompt,
        });

        orientationResult = object;
      } catch (aiError) {
        console.warn('Groq AI error in /api/orientation/generate, switching to deterministic fallback:', aiError);
      }
    }

    // Si Groq a échoué ou n'est pas configuré, utiliser le moteur de repli déterministe certifié Togo
    if (!orientationResult) {
      orientationResult = generateDeterministicOrientationM3(answers);
    }

    const sanitizedResult = sanitizeObject(orientationResult);
    await saveOrientation(user.id, answers, sanitizedResult);

    return NextResponse.json(sanitizedResult);
  } catch (error) {
    return apiError(error);
  }
}
