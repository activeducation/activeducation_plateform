import { NextResponse } from 'next/server';
import { createClient } from '@/utils/supabase/server';
import { db } from '@/db';
import { orientationResults, users } from '@/db/schema';
import { eq } from 'drizzle-orm';
import { generateObject } from 'ai';
import { createGroq } from '@ai-sdk/groq';
import { z } from 'zod';
import { generateDeterministicOrientationM3, sanitizeObject } from '@/lib/orientation';

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
    let user = null;
    try {
      const supabase = await createClient();
      const { data, error } = await supabase.auth.getUser();
      if (!error && data?.user) {
        user = data.user;
      }
    } catch {
      // Mode démo ou exécution sans session active : continuer gracieusement
      user = null;
    }

    const body = await req.json().catch(() => ({}));
    const answers = body.answers || body;

    if (!answers || (typeof answers === 'object' && Object.keys(answers).length === 0)) {
      return NextResponse.json({ error: 'Données manquantes' }, { status: 400 });
    }

    let orientationResult = null;

    // Tentative d'appel Groq IA si la clé d'API est configurée
    const apiKey = process.env.GROQ_API_KEY;
    const isValidKey = apiKey && apiKey.length > 10 && !apiKey.includes('dummy') && !apiKey.includes('test');

    if (isValidKey) {
      try {
        const groq = createGroq({
          apiKey,
        });

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
          model: groq('llama-3.1-70b-versatile'),
          schema: OrientationResultSchema,
          system: systemPrompt,
          prompt: userPrompt,
        });

        orientationResult = object;
      } catch (aiError) {
        console.warn('Groq AI error in /api/orientation/generate, switching to deterministic fallback:', aiError);
      }
    }

    // Bascule déterministe résiliente si Groq n'est pas disponible ou a échoué
    if (!orientationResult) {
      orientationResult = generateDeterministicOrientationM3(answers);
    }

    // Assainissement strict pour garantir ZÉRO EMOJI
    const sanitizedResult = sanitizeObject(orientationResult);

    // Enregistrement non-bloquant en base de données si l'utilisateur est authentifié
    if (user && user.id) {
      try {
        await db.insert(orientationResults).values({
          userId: user.id,
          inputs: answers,
          results: sanitizedResult,
        });

        const userProfile = await db.select().from(users).where(eq(users.id, user.id)).limit(1);
        if (userProfile.length > 0) {
          await db.update(users)
            .set({ xpPoints: (userProfile[0].xpPoints || 0) + 200 })
            .where(eq(users.id, user.id));
        }
      } catch (dbError) {
        console.warn('Database save warning in /api/orientation/generate (non-blocking):', dbError);
      }
    }

    return NextResponse.json(sanitizedResult);
  } catch (error) {
    console.error("Erreur lors de la génération de l'orientation", error);
    // Dernier filet de sécurité : ne jamais bloquer l'expérience utilisateur
    const safeFallback = generateDeterministicOrientationM3({});
    return NextResponse.json(sanitizeObject(safeFallback));
  }
}

