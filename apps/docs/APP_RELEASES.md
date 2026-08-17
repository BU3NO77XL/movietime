# Atualizacao do aplicativo

O aplicativo consulta:

```text
https://movietimeweb.vercel.app/api/app-version
```

O download usa o endereco estavel:

```text
https://movietimeweb.vercel.app/api/app-version/download
```

## Publicar uma versao

1. Gere o APK localmente com a mesma chave Android:

```powershell
flutter build apk --release
```

2. No Supabase Storage, abra o bucket `app-releases` e envie o arquivo para um caminho como:

```text
android/movietime-1.0.1.apk
```

3. Em `app_releases`, insira a nova versao:

```sql
insert into public.app_releases
  (version_name, version_code, apk_path, file_name, release_notes, mandatory, is_active)
values
  ('1.0.1', 2, 'android/movietime-1.0.1.apk', 'movietime.apk',
   'Correcoes e melhorias.', false, true);
```

A versao anterior deve ser marcada como inativa antes da nova, pois apenas uma versao pode ficar ativa:

```sql
update public.app_releases set is_active = false where is_active = true;
```

O `version_code` precisa sempre aumentar e a chave de assinatura precisa ser a mesma.