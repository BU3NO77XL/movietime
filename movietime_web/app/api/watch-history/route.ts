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

  const tmdbId = request.nextUrl.searchParams.get('tmdbId');
  const mediaType = request.nextUrl.searchParams.get('mediaType');

  let query = supabaseAdmin
    .from('watch_history')
    .select('*')
    .eq('profile_id', profileId)
    .order('watched_at', { ascending: false });

  if (tmdbId) query = query.eq('tmdb_id', Number(tmdbId));
  if (mediaType) query = query.eq('media_type', mediaType);

  const { data: items, error } = await query;

  if (error) {
    return NextResponse.json(
      { error: 'Erro ao buscar historico.' },
      { status: 500 },
    );
  }

  return NextResponse.json({ items });
}

export async function POST(request: NextRequest) {
  const body = await request.json();
  const profileId = await getProfileIdFromRequest(request, body.userId);
  const {
    tmdbId,
    mediaType,
    seasonNumber,
    episodeNumber,
    totalSeasons,
    totalEpisodes,
    seasonEpisodes,
    title,
    posterUrl,
    backdropUrl,
    progressPercent,
  } = body;

  if (!profileId || !tmdbId || !mediaType) {
    return NextResponse.json(
      { error: 'Usuario, tmdbId e mediaType sao obrigatorios.' },
      { status: 400 },
    );
  }

  const { data: item, error } = await supabaseAdmin
    .from('watch_history')
    .upsert(
      {
        profile_id: profileId,
        tmdb_id: Number(tmdbId),
        media_type: mediaType,
        season_number: seasonNumber ?? 0,
        episode_number: episodeNumber ?? 0,
        total_seasons: totalSeasons ?? 0,
        total_episodes: totalEpisodes ?? 0,
        season_episodes: seasonEpisodes ?? 0,
        title: title || '',
        poster_url: posterUrl || null,
        backdrop_url: backdropUrl || null,
        progress_percent: progressPercent ?? 0,
        watched_at: new Date().toISOString(),
      },
      {
        onConflict:
          'profile_id,tmdb_id,season_number,episode_number,media_type',
        ignoreDuplicates: false,
      },
    )
    .select()
    .single();

  if (error) {
    return NextResponse.json(
      { error: 'Erro ao salvar historico.' },
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
    .from('watch_history')
    .delete()
    .eq('profile_id', profileId)
    .eq('tmdb_id', Number(tmdbId))
    .eq('media_type', mediaType);

  return NextResponse.json({ success: true });
}
