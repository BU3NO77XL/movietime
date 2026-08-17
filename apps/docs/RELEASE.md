# Release Android

## Secrets do GitHub

Configure estes secrets no repositório `Settings > Secrets and variables > Actions`:

- `ANDROID_KEYSTORE_BASE64`: conteúdo Base64 do arquivo `.jks`.
- `ANDROID_KEYSTORE_PASSWORD`: senha do keystore.
- `ANDROID_KEY_ALIAS`: alias criado na chave.
- `ANDROID_KEY_PASSWORD`: senha do alias.
- `MOVIETIME_API_BASE_URL`: URL pública da API, sem barra final.

Nunca envie o arquivo `.jks`, `key.properties` ou senhas para o Git.

## Publicar uma versão

A versão do APK é definida pela tag. O workflow é executado quando uma tag no formato `vX.Y.Z` é enviada:

```powershell
git add .
git commit -m "release: prepara versao 1.0.0"
git push origin main
git tag v1.0.0
git push origin v1.0.0
```

O GitHub Actions compila o APK assinado e publica `movietime.apk` na Release. O aplicativo consulta a última Release e oferece o download quando a versão publicada é superior à instalada.

A chave de assinatura deve permanecer a mesma em todas as versões. Se ela for perdida ou trocada, o Android não aceitará a atualização sobre a instalação existente.