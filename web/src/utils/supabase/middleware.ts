import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({
    request,
  })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) => request.cookies.set(name, value))
          supabaseResponse = NextResponse.next({
            request,
          })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // IMPORTANT: Rafraîchir la session d'authentification
  // Cela empêchera le token d'expirer pour les utilisateurs actifs
  const {
    data: { user },
  } = await supabase.auth.getUser()

  // Protection des routes étudiantes
  if (
    !user &&
    request.nextUrl.pathname.startsWith('/student') &&
    !request.nextUrl.pathname.startsWith('/auth')
  ) {
    // Si l'utilisateur n'est pas connecté et essaie d'accéder au dashboard
    const url = request.nextUrl.clone()
    url.pathname = '/auth/login'
    return NextResponse.redirect(url)
  }

  // Redirection des utilisateurs connectés qui essaient d'aller sur les pages d'auth
  if (user && request.nextUrl.pathname.startsWith('/auth')) {
    const url = request.nextUrl.clone()
    url.pathname = '/student/cours'
    return NextResponse.redirect(url)
  }

  return supabaseResponse
}
