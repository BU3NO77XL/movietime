import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';

const supabaseUrl = process.env.SUPABASE_URL;
const publishableKey = process.env.SUPABASE_PUBLISHABLE_KEY;
const bucketName = process.env.SUPABASE_BUCKET_NAME || 'avatars';
const sourceDir =
  process.env.AVATAR_SOURCE_DIR ||
  path.resolve(process.cwd(), 'public', 'avatars', 'images');

if (!supabaseUrl || !publishableKey) {
  throw new Error(
    'SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY are required for upload.',
  );
}

const files = (await readdir(sourceDir))
  .filter((file) => file.toLowerCase().endsWith('.png'))
  .sort((a, b) => a.localeCompare(b, 'en'));

for (const fileName of files) {
  const filePath = path.join(sourceDir, fileName);
  const body = await readFile(filePath);
  const objectPath = `images/${fileName}`;
  const endpoint = `${supabaseUrl}/storage/v1/object/${bucketName}/${objectPath}`;

  const response = await fetch(endpoint, {
    method: 'POST',
    headers: {
      apikey: publishableKey,
      Authorization: `Bearer ${publishableKey}`,
      'Content-Type': 'image/png',
    },
    body,
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Upload failed for ${fileName}: ${response.status} ${errorText}`);
  }

  console.log(`uploaded ${fileName}`);
}

console.log(`done: ${files.length} avatar files uploaded to ${bucketName}`);
