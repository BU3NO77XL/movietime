import { NextRequest, NextResponse } from 'next/server';
import { getSessionFromRequest } from '@/lib/session';
import { supabaseAdmin } from '@/lib/supabase-admin';
import { readFile } from 'node:fs/promises';
import path from 'node:path';

function normalizeAvatarIndex(rawIndex: string) {
  const parsed = Number.parseInt(rawIndex, 10);
  if (!Number.isFinite(parsed) || parsed < 1 || parsed > 255) {
    return null;
  }

  return String(parsed).padStart(2, '0');
}

export async function GET(
  request: NextRequest,
  context: { params: Promise<{ index: string }> },
) {
  const session = await getSessionFromRequest(request);
  if (!session?.user) {
    return NextResponse.json({ error: 'Nao autenticado.' }, { status: 401 });
  }

  const { index } = await context.params;
  const normalized = normalizeAvatarIndex(index);
  if (!normalized) {
    return NextResponse.json(
      { error: 'Avatar invalido.' },
      { status: 400 },
    );
  }

  const objectPath = `images/${normalized}.png`;
  const { data, error } = await supabaseAdmin.storage
    .from('avatars')
    .download(objectPath);

  if (!error && data) {
    return new NextResponse(data, {
      status: 200,
      headers: {
        'Content-Type': data.type || 'image/png',
        'Cache-Control': 'private, max-age=3600',
      },
    });
  }

  try {
    const fallbackPath = path.join(
      process.cwd(),
      'public',
      'avatars',
      'images',
      `${normalized}.png`,
    );
    const buffer = await readFile(fallbackPath);
    return new NextResponse(buffer, {
      status: 200,
      headers: {
        'Content-Type': 'image/png',
        'Cache-Control': 'private, max-age=3600',
      },
    });
  } catch {
    return NextResponse.json(
      { error: 'Avatar nao encontrado.' },
      { status: 404 },
    );
  }
}
