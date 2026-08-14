# MovieTime App

Aplicativo Flutter do MovieTime.

Este diretorio contem apenas o app mobile/web em Flutter. O backend e a versao web em Next.js ficam em:

```text
../movietime_web
```

Por padrao, o app consome a API hospedada em:

```text
https://movietimeweb.vercel.app
```

Essa URL pode ser trocada sem alterar codigo usando `--dart-define`.

## Requisitos

Antes de rodar o app, instale:

- Git
- Flutter SDK
- Android Studio, para emulador Android e SDK Android
- VS Code ou Android Studio como editor
- Chrome, para rodar em modo web

## Instalar Flutter

1. Baixe o Flutter:

```text
https://docs.flutter.dev/get-started/install
```

2. Extraia o SDK em uma pasta fixa. Exemplo no Windows:

```text
C:\src\flutter
```

3. Adicione o Flutter ao `PATH`:

```text
C:\src\flutter\bin
```

4. Feche e abra o terminal novamente.

5. Confira a instalacao:

```bash
flutter doctor
```

6. Siga os ajustes indicados pelo `flutter doctor`, principalmente Android SDK, licencas e Chrome.

Para aceitar licencas Android:

```bash
flutter doctor --android-licenses
```

## Preparar apos clonar

Na raiz do monorepo:

```bash
git clone https://github.com/BU3NO77XL/movietime.git
cd movietime/apps/movietime_app
flutter pub get
```

Confira os dispositivos disponiveis:

```bash
flutter devices
```

## Rodar no emulador Android

1. Abra o Android Studio.
2. Abra o Device Manager.
3. Crie ou inicie um emulador Android.
4. No terminal, a partir da raiz do monorepo:

```bash
cd apps/movietime_app
flutter run
```

Se houver mais de um dispositivo:

```bash
flutter devices
flutter run -d NOME_OU_ID_DO_DISPOSITIVO
```

## Rodar em celular fisico Android

1. No celular, ative o modo desenvolvedor.
2. Ative a depuracao USB.
3. Conecte o celular no computador via USB.
4. Autorize a depuracao USB no celular.
5. Confira se o Flutter reconheceu:

```bash
flutter devices
```

6. Rode:

```bash
flutter run -d NOME_OU_ID_DO_CELULAR
```

O app instalado no celular usa a API da Vercel por padrao, entao nao precisa apontar para `localhost`.

## Rodar no navegador

Para rodar em Chrome:

```bash
flutter run -d chrome
```

Para gerar build web:

```bash
flutter build web
```

O build fica em:

```text
build/web
```

## Configurar URL da API

O app usa a variavel de build:

```text
MOVIETIME_API_BASE_URL
```

Se ela nao for informada, o app usa:

```text
https://movietimeweb.vercel.app
```

### Scripts prontos

No Windows:

```bat
scripts\run.bat
scripts\build-apk.bat
scripts\build-web.bat
```

Com outra API:

```bat
scripts\run.bat https://sua-api.vercel.app
scripts\build-apk.bat https://sua-api.vercel.app
scripts\build-web.bat https://sua-api.vercel.app
```

No macOS/Linux:

```bash
sh scripts/run.sh
sh scripts/build-apk.sh
sh scripts/build-web.sh
```

Com outra API:

```bash
sh scripts/run.sh https://sua-api.vercel.app
sh scripts/build-apk.sh https://sua-api.vercel.app
sh scripts/build-web.sh https://sua-api.vercel.app
```

Se nenhuma URL for passada, os scripts usam a API padrao da Vercel.

### Comandos manuais

Para usar outro deploy da Vercel:

```bash
flutter run --dart-define=MOVIETIME_API_BASE_URL=https://sua-api.vercel.app
```

Para gerar APK apontando para outro backend:

```bash
flutter build apk --dart-define=MOVIETIME_API_BASE_URL=https://sua-api.vercel.app
```

Para gerar build web apontando para outro backend:

```bash
flutter build web --dart-define=MOVIETIME_API_BASE_URL=https://sua-api.vercel.app
```

## Usar backend local em vez da Vercel

Normalmente nao precisa. O padrao e Vercel.

Para testar contra o backend local do `apps/movietime_web`, rode o backend em outro terminal e passe a URL manualmente.

Emulador Android acessando backend local do computador:

```bash
flutter run --dart-define=MOVIETIME_API_BASE_URL=http://10.0.2.2:3000
```

Celular fisico acessando backend local do computador:

```bash
flutter run --dart-define=MOVIETIME_API_BASE_URL=http://SEU_IP_LOCAL:3000
```

Exemplo:

```bash
flutter run --dart-define=MOVIETIME_API_BASE_URL=http://192.168.0.25:3000
```

Web/Desktop acessando backend local:

```bash
flutter run -d chrome --dart-define=MOVIETIME_API_BASE_URL=http://localhost:3000
```

## Validar antes de enviar mudancas

Rode:

```bash
dart analyze
flutter test
```

Para testar apenas a camada de API:

```bash
flutter test test/api_client_test.dart
```

## Observacoes

- Nao coloque chaves secretas do Supabase no app Flutter.
- A chave `SUPABASE_SERVICE_ROLE_KEY` deve ficar somente no backend/Vercel.
- O app salva sessao com `flutter_secure_storage`.
- Para build Windows com plugins, o Windows pode pedir Developer Mode ativo.
