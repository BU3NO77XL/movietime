# MovieTime

Monorepo local do MovieTime.

- `apps/movietime_app/`: aplicativo Flutter.
- `apps/movietime_web/`: projeto web/backend Next.js usado pela API hospedada na Vercel.

O app Flutter consome a API em `https://movietimeweb.vercel.app` por padrao. Para rodar o app:

```bash
cd apps/movietime_app
flutter pub get
flutter run
```
