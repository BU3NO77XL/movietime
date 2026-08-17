import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase-admin';
import { getProfileIdFromRequest } from '@/lib/session';

function serializeProfile(profile: any) {
  return {
    id: profile.id,
    email: profile.email,
    name: profile.full_name,
    role: profile.role,
    avatarUrl: profile.avatar_url,
    listName: profile.list_name,
    createdAt: profile.created_at,
    preferences: profile.preferences
      ? {
          avatarIndex: profile.preferences.avatar_index,
          genres: profile.preferences.genres
            ? profile.preferences.genres.split(',')
            : [],
          recommendationsUpdatedAt:
            profile.preferences.recommendations_updated_at || null,
            contentLanguage: profile.preferences.content_language || 'pt-BR',
        }
      : null,
  };
}

export async function PATCH(request: NextRequest) {
  const body = await request.json();
  const profileId = await getProfileIdFromRequest(request, body.userId);
  const { name, listName } = body;

  if (!profileId) {
    return NextResponse.json({ error: 'Nao autenticado.' }, { status: 401 });
  }

  const updates: Record<string, any> = {};
  if (typeof name === 'string' && name.trim()) updates.full_name = name.trim();
  if (typeof listName === 'string') {
    updates.list_name = listName.trim() || null;
  }

  if (Object.keys(updates).length === 0) {
    return NextResponse.json(
      { error: 'Nenhum campo para atualizar.' },
      { status: 400 },
    );
  }

  const { data, error } = await supabaseAdmin
    .from('profiles')
    .update(updates)
    .eq('id', profileId)
    .select('*, preferences(*)')
    .single();

  if (error || !data) {
    return NextResponse.json(
      { error: 'Erro ao atualizar perfil.' },
      { status: 500 },
    );
  }

  return NextResponse.json({ user: serializeProfile(data) });
}

export async function GET(request: NextRequest) {
  const profileId = await getProfileIdFromRequest(
    request,
    request.nextUrl.searchParams.get('userId'),
  );

  if (!profileId) {
    return NextResponse.json({ error: 'Nao autenticado.' }, { status: 401 });
  }

  const { data: profile, error } = await supabaseAdmin
    .from('profiles')
    .select('*, preferences(*)')
    .eq('id', profileId)
    .single();

  if (error || !profile) {
    return NextResponse.json(
      { error: 'Perfil nao encontrado.' },
      { status: 404 },
    );
  }

  return NextResponse.json({ user: serializeProfile(profile) });
}
