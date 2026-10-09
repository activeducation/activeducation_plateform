import { createBrowserClient } from '@supabase/ssr'

// Crée un client Supabase sécurisé pour une utilisation dans le navigateur
export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      auth: {
        storage: typeof window !== "undefined" ? window.sessionStorage : undefined,
      },
    }
  )
}
