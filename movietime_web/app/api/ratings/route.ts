import { NextRequest, NextResponse } from 'next/server';
import { getProfileIdFromRequest } from '@/lib/session';
import { supabaseAdmin } from '@/lib/supabase-admin';

export async function GET(request: NextRequest) {
  const profileId = await getProfileIdFromRequest(
    request,
    request.nextUrl.searchParams.get('userId'),
  );

  if (!profileId) {
    return NextResponse.json({ error: 'Nao autenticado.' }, { status: 401 });
  }

  const { data: items } = await supabaseAdmin
    .from('ratings')
    .select('tmdb_id, media_type, value')
    .eq('profile_id', profileId);

  const ratings: Record<string, string> = {};
  for (const item of items || []) {
    ratings[`${item.tmdb_id}_${item.media_type}`] = item.value;
  }

  return NextResponse.json({ ratings });
}

export async function POST(request: NextRequest) {
  const body = await request.json();
  const profileId = await getProfileIdFromRequest(request, body.userId);
  const { tmdbId, mediaType, value } = body;

  if (!profileId || !tmdbId || !mediaType || !value) {
    return NextResponse.json(
      { error: 'Usuario, tmdbId, mediaType e value sao obrigatorios.' },
      { status: 400 },
    );
  }

  const { data: item, error } = await supabaseAdmin
    .from('ratings')
    .upsert(
      {
        profile_id: profileId,
        tmdb_id: Number(tmdbId),
        media_type: mediaType,
        value,
      },
      {
        onConflict: 'profile_id,tmdb_id,media_type',
        ignoreDuplicates: false,
      },
    )
    .select()
    .single();

  if (error) {
    return NextResponse.json(
      { error: 'Erro ao salvar avaliacao.' },
      { status: 500 },
    );
  }

  return NextResponse.json({ item }, { status: 201 });
}

export async function DELETE(request: NextRequest) {
  const body = await request.json();
  const profileId = await getProfileIdFromRequest(request, body.userId);
  const { tmdbId, mediaType } = body;

  if (!profileId || !tmdbId || !mediaType) {
    return NextResponse.json(
      { error: 'Usuario, tmdbId e mediaType sao obrigatorios.' },
      { status: 400 },
    );
  }

  await supabaseAdmin
    .from('ratings')
    .delete()
    .eq('profile_id', profileId)
    .eq('tmdb_id', Number(tmdbId))
    .eq('media_type', mediaType);

  return NextResponse.json({ success: true });
}
