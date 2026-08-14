# MovieTime

Monorepo do MovieTime.

## Estrutura

```text
movietime/
  apps/
    movietime_app/  # Aplicativo Flutter
    movietime_web/  # Next.js web + API
  .github/
    workflows/
      web-ci.yml
  .gitignore
  README.md
```

## Apps

### Flutter

Diretorio:

```text
apps/movietime_app
```

Rodar:

```bash
cd apps/movietime_app
flutter pub get
flutter run
```

Documentacao completa:

```text
apps/movietime_app/README.md
```

### Web/API

Diretorio:

```text
apps/movietime_web
```

Rodar:

```bash
cd apps/movietime_web
pnpm install
pnpm dev
```

Documentacao completa:

```text
apps/movietime_web/README.md
```

## API Padrao

O app Flutter usa por padrao:

```text
https://movietimeweb.vercel.app
```

Essa URL pode ser sobrescrita no Flutter com:

```bash
--dart-define=MOVIETIME_API_BASE_URL=https://sua-api.vercel.app
```

## Vercel

Para hospedar o web/API na Vercel usando este monorepo:

```text
Root Directory: apps/movietime_web
Framework Preset: Next.js
Install Command: pnpm install
Build Command: pnpm build
Output Directory: .next
```

Configure as variaveis de ambiente na Vercel, nao no Git:

```text
TMDB_API_KEY
NEXT_PUBLIC_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY
```

## CI

O GitHub Actions do web fica em:

```text
.github/workflows/web-ci.yml
```

Ele roda apenas quando houver mudancas em:

```text
apps/movietime_web/**
.github/workflows/web-ci.yml
```
