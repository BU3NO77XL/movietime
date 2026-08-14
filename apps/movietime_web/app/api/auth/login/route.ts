import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase-admin';
import { createSession } from '@/lib/session';

export async function POST(request: NextRequest) {
  const { email, password } = await request.json();

  if (!email || !password) {
    return NextResponse.json(
      { error: 'Email e senha sao obrigatorios.' },
      { status: 400 },
    );
  }

  let session;
  try {
    session = await createSession(email, password);
  } catch {
    return NextResponse.json(
      { error: 'Credenciais invalidas.' },
      { status: 401 },
    );
  }

  const { data: profile } = await supabaseAdmin
    .from('profiles')
    .select('*, preferences(*)')
    .eq('email', email)
    .maybeSingle();

  if (!profile) {
    return NextResponse.json(
      { error: 'Perfil nao encontrado.' },
      { status: 404 },
    );
  }

  return NextResponse.json({
    user: {
      id: profile.id,
      email: profile.email,
      name: profile.full_name,
      role: profile.role,
      avatarUrl: profile.avatar_url,
      createdAt: profile.created_at,
      preferences: profile.preferences
        ? {
            avatarIndex: profile.preferences.avatar_index,
            genres: profile.preferences.genres
              ? profile.preferences.genres.split(',')
              : [],
            recommendationsUpdatedAt:
              profile.preferences.recommendations_updated_at || null,
          }
        : null,
    },
    session: {
      accessToken: session.access_token,
      refreshToken: session.refresh_token,
      expiresAt: session.expires_at,
    },
  });
}
