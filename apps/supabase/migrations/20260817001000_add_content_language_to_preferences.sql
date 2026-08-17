alter table public.preferences
  add column if not exists content_language text not null default 'pt-BR';

update public.preferences
set content_language = 'pt-BR'
where content_language is null or length(trim(content_language)) = 0;

alter table public.preferences
  drop constraint if exists preferences_content_language_check;

alter table public.preferences
  add constraint preferences_content_language_check
  check (content_language in ('pt-BR', 'en-US', 'es-ES', 'fr-FR', 'de-DE', 'it-IT'));