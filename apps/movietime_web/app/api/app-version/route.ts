import { NextResponse } from 'next/server';

import { supabaseAdmin } from '@/lib/supabase-admin';

export const dynamic = 'force-dynamic';

export async function GET(request: Request) {
  const { data: release, error } = await supabaseAdmin
    .from('app_releases')
    .select(
      'version_name, version_code, file_name, file_size_bytes, release_notes, mandatory, created_at',
    )
    .eq('is_active', true)
    .order('version_code', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (error) {
    return NextResponse.json(
      { error: 'Nao foi possivel consultar a versao do aplicativo.' },
      { status: 500 },
    );
  }

  if (!release) {
    return NextResponse.json(
      { error: 'Nenhuma versao publicada.' },
      { status: 404 },
    );
  }

  const origin = new URL(request.url).origin;
  return NextResponse.json(
    {
      versionName: release.version_name,
      versionCode: release.version_code,
      fileName: release.file_name,
      fileSizeBytes: release.file_size_bytes,
      notes: release.release_notes,
      mandatory: release.mandatory,
      publishedAt: release.created_at,
      downloadUrl: `${origin}/api/app-version/download`,
    },
    {
      headers: {
        'Cache-Control': 'public, max-age=300, s-maxage=300',
      },
    },
  );
}