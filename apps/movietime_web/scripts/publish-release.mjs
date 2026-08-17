import { createClient } from '@supabase/supabase-js';
import { createReadStream, readFileSync } from 'node:fs';
import { stat } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const appRoot = path.resolve(webRoot, '..', 'movietime_app');

function loadEnvFile(filePath) {
  try {
    const content = readFileSync(filePath, 'utf8');
    for (const line of content.split(/\r?\n/)) {
      const match = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
      if (!match || match[1] in process.env) continue;
      process.env[match[1]] = match[2].replace(/^['"]|['"]$/g, '');
    }
  } catch (error) {
    if (error.code !== 'ENOENT') throw error;
  }
}

function requiredEnv(name, fallbackName) {
  const value = process.env[name] || (fallbackName && process.env[fallbackName]);
  if (!value) throw new Error('Variavel obrigatoria ausente: ' + name);
  return value;
}

loadEnvFile(path.join(appRoot, '.env.release'));

const supabaseUrl = requiredEnv('SUPABASE_URL', 'NEXT_PUBLIC_SUPABASE_URL');
const secretKey = requiredEnv('SUPABASE_SECRET_KEY', 'SUPABASE_SERVICE_ROLE_KEY');
const pubspec = readFileSync(path.join(appRoot, 'pubspec.yaml'), 'utf8');
const versionMatch = pubspec.match(/^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$/m);

if (!versionMatch) throw new Error('Nao foi possivel localizar a versao no pubspec.yaml.');

const [, versionName, versionCodeText] = versionMatch;
const versionCode = Number(versionCodeText);
const apkName = 'movietime-v' + versionName + '.apk';
const apkPath = process.env.RELEASE_APK || path.join(appRoot, 'build', 'releases', apkName);
const releasePath = 'releases/' + apkName;
const fileInfo = await stat(apkPath);
const notes = process.env.RELEASE_NOTES || 'Atualizacao MovieTime ' + versionName;
const mandatory = /^(1|true|yes|sim)$/i.test(process.env.RELEASE_MANDATORY || 'false');

const supabase = createClient(supabaseUrl, secretKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

console.log('Publicando ' + apkName + ' (' + (fileInfo.size / 1024 / 1024).toFixed(2) + ' MB)...');

const { error: uploadError } = await supabase.storage
  .from('app-releases')
  .upload(releasePath, createReadStream(apkPath), {
    cacheControl: '3600',
    contentType: 'application/vnd.android.package-archive',
    upsert: true,
  });

if (uploadError) throw new Error('Falha no upload: ' + uploadError.message);

const { error: deactivateError } = await supabase
  .from('app_releases')
  .update({ is_active: false })
  .eq('is_active', true);

if (deactivateError) throw new Error('Falha ao desativar versoes antigas: ' + deactivateError.message);

const { error: releaseError } = await supabase
  .from('app_releases')
  .upsert({
    version_name: versionName,
    version_code: versionCode,
    apk_path: releasePath,
    file_name: apkName,
    file_size_bytes: fileInfo.size,
    release_notes: notes,
    mandatory,
    is_active: true,
  }, { onConflict: 'version_code' });

if (releaseError) throw new Error('Falha ao registrar a versao: ' + releaseError.message);

console.log('Release ' + versionName + ' (' + versionCode + ') publicada e ativada.');
