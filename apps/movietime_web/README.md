# MovieTime Web

Projeto Next.js do MovieTime.

Este diretorio contem:

- site web
- API routes usadas pelo app Flutter
- integracao com Supabase
- proxy/cache para TMDB

## Requisitos

- Node.js 24 recomendado para alinhar com o CI
- pnpm 11.9.0

Instalar pnpm, caso nao tenha:

```bash
npm install -g pnpm@11.9.0
```

## Preparar apos clonar

Na raiz do monorepo:

```bash
git clone https://github.com/BU3NO77XL/movietime.git
cd movietime/apps/movietime_web
pnpm install
```

## Variaveis de ambiente

Copie o exemplo:

```bash
cp .env.example .env
```

Preencha:

```text
TMDB_API_KEY
NEXT_PUBLIC_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY
```

Nunca commite `.env`. Ele fica ignorado pelo Git.

## Desenvolvimento

```bash
pnpm dev
```

Acesse:

```text
http://localhost:3000
```

API local:

```text
http://localhost:3000/api
```

Exemplo: abrir `/api/auth/login` no navegador retorna `405`, porque essa rota aceita `POST`, nao `GET`.

## Scripts

```bash
pnpm dev
pnpm build
pnpm start
pnpm lint
pnpm typecheck
pnpm test
```

## Rotas principais da API

Auth:

```text
POST /api/auth/login
POST /api/auth/signup
POST /api/auth/logout
GET  /api/auth/profile
PATCH /api/auth/profile
POST /api/auth/preferences
POST /api/auth/recommendations
```

Usuario/conteudo:

```text
GET/POST/DELETE /api/watchlist
GET/POST/DELETE /api/watch-history
GET/POST/DELETE /api/ratings
GET/POST        /api/match
GET             /api/content/[...path]
```

As rotas mobile aceitam:

```text
Authorization: Bearer <accessToken>
```

O fallback por `userId` existe para manter compatibilidade com o fluxo web atual.

## Deploy na Vercel

Ao criar ou ajustar o projeto na Vercel, use:

```text
Root Directory: apps/movietime_web
Framework Preset: Next.js
Install Command: pnpm install
Build Command: pnpm build
Output Directory: .next
```

Configure as variaveis de ambiente na Vercel:

```text
TMDB_API_KEY
NEXT_PUBLIC_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY
```

Depois disso, pushes na branch `main` fazem deploy automatico do web/API.

## CI

O workflow do GitHub Actions fica na raiz do monorepo:

```text
.github/workflows/web-ci.yml
```

Ele roda em mudancas dentro de:

```text
apps/movietime_web/**
```

Jobs:

- audit
- lint
- typecheck
- tests
- build

## Relacao com o Flutter

O app Flutter em `../movietime_app` consome esta API.

Em producao, o Flutter aponta por padrao para:

```text
https://movietimeweb.vercel.app
```

Para testar outro backend, use `MOVIETIME_API_BASE_URL` no Flutter.
