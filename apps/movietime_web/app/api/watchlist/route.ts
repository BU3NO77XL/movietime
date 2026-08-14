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

  const { data: items, error } = await supabaseAdmin
    .from('watchlist')
    .select('*')
    .eq('profile_id', profileId)
    .order('added_at', { ascending: false });

  if (error) {
    return NextResponse.json(
      { error: 'Erro ao buscar watchlist.' },
      { status: 500 },
    );
  }

  return NextResponse.json({ items });
}

export async function POST(request: NextRequest) {
  const body = await request.json();
  const profileId = await getProfileIdFromRequest(request, body.userId);
  const { tmdbId, mediaType, title, posterUrl, backdropUrl } = body;

  if (!profileId || !tmdbId || !mediaType) {
    return NextResponse.json(
      { error: 'Usuario, tmdbId e mediaType sao obrigatorios.' },
      { status: 400 },
    );
  }

  const { data: item, error } = await supabaseAdmin
    .from('watchlist')
    .upsert(
      {
        profile_id: profileId,
        tmdb_id: Number(tmdbId),
        media_type: mediaType,
        title: title || '',
        poster_url: posterUrl || null,
        backdrop_url: backdropUrl || null,
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
      { error: 'Erro ao adicionar a watchlist.' },
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
    .from('watchlist')
    .delete()
    .eq('profile_id', profileId)
    .eq('tmdb_id', Number(tmdbId))
    .eq('media_type', mediaType);

  return NextResponse.json({ success: true });
}
