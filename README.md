# MovieTime

Monorepo local do MovieTime.

- `movietime_app/`: aplicativo Flutter.
- `movietime_web/`: projeto web/backend Next.js usado pela API hospedada na Vercel.

O app Flutter consome a API em `https://movietimeweb.vercel.app` por padrao. Para rodar o app:

```bash
cd movietime_app
flutter pub get
flutter run
```
