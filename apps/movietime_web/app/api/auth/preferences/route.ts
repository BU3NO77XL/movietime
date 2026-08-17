import { NextRequest, NextResponse } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase-admin';
import { getProfileIdFromRequest } from '@/lib/session';

export async function POST(request: NextRequest) {
  const body = await request.json();
  const profileId = await getProfileIdFromRequest(request, body.userId);
  const { avatarIndex, genres, contentLanguage = 'pt-BR' } = body;
  const supportedLanguages = ['pt-BR', 'en-US', 'es-ES', 'fr-FR', 'de-DE', 'it-IT'];

  if (
    !profileId ||
    avatarIndex == null ||
    !Array.isArray(genres) ||
    genres.length < 3 ||
    !supportedLanguages.includes(contentLanguage)
  ) {
    return NextResponse.json(
      { error: 'Dados de preferencias invalidos.' },
      { status: 400 },
    );
  }

  const { data: profile } = await supabaseAdmin
    .from('profiles')
    .select('id')
    .eq('id', profileId)
    .single();

  if (!profile) {
    return NextResponse.json(
      { error: 'Usuario nao encontrado.' },
      { status: 404 },
    );
  }

  const avatarNumber = Number(avatarIndex) + 1;
  const avatarUrl = Number.isInteger(avatarNumber) && avatarNumber >= 1 && avatarNumber <= 255
    ? new URL('/api/avatars/' + avatarNumber, request.url).toString()
    : null;

  const { data: preferences } = await supabaseAdmin
    .from('preferences')
    .upsert(
      {
        profile_id: profileId,
        avatar_index: Number(avatarIndex),
        genres: genres.join(','),
        content_language: contentLanguage,
      },
      { onConflict: 'profile_id', ignoreDuplicates: false },
    )
    .select()
    .single();

  await supabaseAdmin
    .from('profiles')
    .update({ avatar_url: avatarUrl })
    .eq('id', profileId);

  return NextResponse.json({ preferences, avatarUrl }, { status: 200 });
}
