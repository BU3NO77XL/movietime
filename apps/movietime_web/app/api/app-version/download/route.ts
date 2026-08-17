import { NextResponse } from 'next/server';

import { supabaseAdmin } from '@/lib/supabase-admin';

export const dynamic = 'force-dynamic';

export async function GET() {
  const { data: release, error } = await supabaseAdmin
    .from('app_releases')
    .select('apk_path, file_name')
    .eq('is_active', true)
    .order('version_code', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (error || !release) {
    return NextResponse.json(
      { error: 'Nenhuma versao publicada.' },
      { status: 404 },
    );
  }

  const fileUrl = supabaseAdmin.storage
    .from('app-releases')
    .getPublicUrl(release.apk_path).data.publicUrl;

  return NextResponse.redirect(fileUrl, {
    status: 302,
    headers: {
      'Cache-Control': 'no-store',
      'Content-Disposition': `attachment; filename="${release.file_name}"`,
    },
  });
}