# MovieTime App

Aplicativo Flutter do MovieTime.

Este diretório contém apenas o app mobile/web em Flutter. O backend e a versão web em Next.js ficam fora daqui, em `../movietime_web`.

Por padrão, o app consome a API hospedada em:

```text
https://movietimeweb.vercel.app
```

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

2. Extraia o SDK em uma pasta fixa, por exemplo no Windows:

```text
C:\src\flutter
```

3. Adicione o Flutter ao `PATH`:

```text
C:\src\flutter\bin
```

4. Feche e abra o terminal novamente.

5. Confira a instalação:

```bash
flutter doctor
```

6. Siga os ajustes indicados pelo `flutter doctor`, principalmente Android SDK, licenças e Chrome.

Para aceitar licenças Android:

```bash
flutter doctor --android-licenses
```

## Preparar o projeto apos clonar

Na raiz do monorepo:

```bash
git clone https://github.com/BU3NO77XL/movietime.git
cd movietime/apps/movietime_app
flutter pub get
```

Confira os dispositivos disponíveis:

```bash
flutter devices
```

## Rodar no emulador Android

1. Abra o Android Studio.
2. Abra o Device Manager.
3. Crie ou inicie um emulador Android.
4. No terminal:

```bash
cd apps/movietime_app
flutter run
```

Se houver mais de um dispositivo:

```bash
flutter devices
flutter run -d NOME_OU_ID_DO_DISPOSITIVO
```

## Rodar em celular físico Android

1. No celular, ative o modo desenvolvedor.
2. Ative a depuração USB.
3. Conecte o celular no computador via USB.
4. Autorize a depuração USB no celular.
5. Confira se o Flutter reconheceu:

```bash
flutter devices
```

6. Rode:

```bash
flutter run -d NOME_OU_ID_DO_CELULAR
```

O app instalado no celular usa a API da Vercel por padrão, então não precisa apontar para `localhost`.

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

## Usar backend local em vez da Vercel

Normalmente não precisa. O padrão é Vercel.

Se quiser testar contra o backend local do `apps/movietime_web`, rode o backend em outro terminal e passe a URL manualmente.

Emulador Android acessando backend local do computador:

```bash
flutter run --dart-define=MOVIETIME_API_BASE_URL=http://10.0.2.2:3000
```

Celular físico acessando backend local do computador:

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

## Validar antes de enviar mudanças

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
