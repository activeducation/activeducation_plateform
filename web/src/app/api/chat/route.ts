import { createOpenAI } from '@ai-sdk/openai';
import { streamText } from 'ai';

// Autoriser le traitement sur l'Edge (plus rapide)
export const runtime = 'edge';

export async function POST(req: Request) {
  try {
    const { messages, userContext } = await req.json();

    // Configuration de Groq via le provider OpenAI
    const groq = createOpenAI({
      baseURL: 'https://api.groq.com/openai/v1',
      apiKey: process.env.GROQ_API_KEY || "VOTRE_CLE_API_GROQ",
    });

    const systemPrompt = `Tu es AÏDA, l'intelligence artificielle d'ActivEducation. Tu es une conseillère d'orientation bienveillante, enthousiaste et experte pour les étudiants du Togo et d'Afrique francophone. 

INFORMATIONS EN TEMPS RÉEL SUR L'ÉTUDIANT À QUI TU PARLES :
- Nom : ${userContext?.name || 'Étudiant inconnu'}
- École / Niveau : ${userContext?.school || ''} (${userContext?.level || ''})
- Page actuelle visitée : ${userContext?.currentRoute || 'Non déterminée'}
- Progression globale : ${userContext?.stats || ''}
- Activités récentes : ${userContext?.achievements || ''}

Tu dois te servir de ces informations pour personnaliser tes réponses. Si l'étudiant te pose une question sur un cours, fais le lien avec ce qu'il a déjà accompli ou là où il se trouve.
Tu utilises toujours un ton professionnel mais amical, et tutoyes l'étudiant. Sois concise et pertinente.`;

    const result = await streamText({
      model: groq('llama-3.3-70b-versatile'),
      messages,
      system: systemPrompt,
    });

    return result.toTextStreamResponse();
  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: "Erreur de connexion à l'IA." }), { status: 500, headers: { 'Content-Type': 'application/json' } });
  }
}
