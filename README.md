# MovieTime

Monorepo MovieTime — app Flutter (mobile e web) + site/API Next.js integrado ao Supabase e ao TMDB para descoberta e gestão de filmes e séries.

Resumo

MovieTime é uma plataforma para descobrir, organizar e gerenciar filmes e séries. Este monorepo contém o aplicativo Flutter (mobile e web) e a aplicação web/API em Next.js que alimentam o app móvel e o site público.

Visão geral da estrutura

```
movietime/
  apps/
    movietime_app/   # Aplicativo Flutter (mobile/web)
    movietime_web/   # Next.js (site público + API routes)
  .github/
    workflows/
      web-ci.yml      # CI do web
  README.md
```

Principais tecnologias

- Flutter (Dart) — app mobile/web
- Next.js (TypeScript) — web e API routes
- Supabase — Auth, Postgres, Storage
- TMDB — dados de filmes e séries
- pnpm / npm, GitHub Actions

Pré-requisitos

- Git
- Flutter SDK (versão compatível com o projeto)
- Node.js (recomendado: Node 24+) e pnpm (ou npm/yarn)
- Conta e projeto no Supabase (para integração)
- API Key do TMDB

Variáveis de ambiente (exemplos)

Web / API (apps/movietime_web/.env.example)

NEXT_PUBLIC_SUPABASE_URL=https://<seu-supabase>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<sua-anon-key>
SUPABASE_SERVICE_ROLE_KEY=<sua-service-role-key>  # somente server-side
TMDB_API_KEY=<sua-tmdb-api-key>

Flutter (apps/movietime_app)

Usar --dart-define ou flutter_dotenv. Exemplo via dart-define ao executar:

--dart-define=MOVIETIME_API_BASE_URL=https://movietimeweb.vercel.app
--dart-define=SUPABASE_URL=https://<seu-supabase>.supabase.co
--dart-define=SUPABASE_ANON_KEY=<sua-anon-key>
--dart-define=TMDB_API_KEY=<sua-tmdb-api-key>

Nunca comite chaves secretas no repositório. Use variáveis de ambiente do provedor de deploy/CI.

Instalação e execução

1) Clonar o repositório

```bash
git clone https://github.com/BU3NO77XL/movietime.git
cd movietime
```

2) Mobile (Flutter)

```bash
cd apps/movietime_app
flutter pub get
flutter run            # ou flutter run -d chrome para web
```

Builds:

```bash
flutter build apk       # Android
flutter build ios       # iOS (macOS)
flutter build web       # Web
```

Para apontar o app para outra API durante execução:

```bash
flutter run --dart-define=MOVIETIME_API_BASE_URL=https://sua-api.vercel.app
```

3) Web / API (Next.js)

```bash
cd apps/movietime_web
pnpm install
pnpm dev               # ambiente de desenvolvimento
pnpm build
pnpm start             # start em produção
```

A API local fica em http://localhost:3000/api

Deploy (Vercel)

Para publicar `apps/movietime_web` na Vercel:

- Root Directory: apps/movietime_web
- Framework Preset: Next.js
- Install Command: pnpm install
- Build Command: pnpm build
- Output Directory: .next

Adicione variáveis de ambiente no painel da Vercel (não no Git): TMDB_API_KEY, NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY

CI

O workflow do web está em `.github/workflows/web-ci.yml`. Ele roda em alterações dentro de `apps/movietime_web/**` e executa jobs de audit, lint, typecheck, tests e build.

Banco de dados e Supabase

- Crie um projeto no Supabase e configure as tabelas necessárias (usuários, watchlists, ratings, etc.).
- Use a `SUPABASE_SERVICE_ROLE_KEY` somente em servidores.
- Para rodar Supabase localmente, siga a documentação oficial do Supabase CLI.

Integração com TMDB

- Obtenha uma API key em https://www.themoviedb.org e configure a variável TMDB_API_KEY.

Testes e lint

- Flutter:

```bash
cd apps/movietime_app
flutter test
flutter analyze
```

- Next.js / TypeScript:

```bash
cd apps/movietime_web
pnpm lint
pnpm test
pnpm typecheck
```

Contribuindo

Contribuições são bem-vindas:

1. Abra uma issue descrevendo a mudança.
2. Crie uma branch: `feat/<descrição>` ou `fix/<descrição>`.
3. Abra um Pull Request com explicação e testes quando aplicável.

Roadmap (sugestões)

- Recomendação personalizada
- Compartilhamento de listas entre usuários
- Notificações e sincronização com calendário

Licença

Adicione um arquivo LICENSE na raiz (por exemplo MIT) caso queira uma licença pública.

Notas finais

Este README foi atualizado automaticamente para refletir a estrutura atual do monorepo. Posso ajustar o conteúdo (idioma, nível de detalhe, exemplos de scripts) ou sincronizar com os scripts exatos em `apps/movietime_web/package.json` e `apps/movietime_app` — diga se quer que eu atualize com valores extraídos dos arquivos do repositório.
