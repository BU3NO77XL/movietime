import { Movie } from '@/types/movie';

export interface WatchHistoryItem {
  id: number;
  tmdb_id: number;
  media_type: string;
  season_number: number;
  episode_number: number;
  total_seasons: number;
  total_episodes: number;
  season_episodes: number;
  title: string;
  poster_url: string;
  backdrop_url: string;
  progress_percent: number;
  watched_at: string;
}

export function buildContinueWatchingItems(historyItems: WatchHistoryItem[], movies: Movie[]) {
  const deduped = new Map<number, WatchHistoryItem>();

  historyItems.forEach((item) => {
    const key = Number(item.tmdb_id);
    const existing = deduped.get(key);

    if (!existing) {
      deduped.set(key, item);
      return;
    }

    const shouldReplace = item.media_type === 'series' && existing.media_type === 'series'
      ? new Date(item.watched_at).getTime() >= new Date(existing.watched_at).getTime()
      : new Date(item.watched_at).getTime() >= new Date(existing.watched_at).getTime();

    if (shouldReplace) {
      deduped.set(key, item);
    }
  });

  return Array.from(deduped.values()).map((item) => {
    const match = movies.find((m) => Number(m.tmdb_id) === Number(item.tmdb_id));
    return {
      id: match?.id || String(item.tmdb_id),
      tmdb_id: item.tmdb_id,
      title: match?.title || item.title,
      type: (item.media_type || match?.type || 'movie') as 'movie' | 'series',
      year: match?.year || 0,
      poster_url: item.poster_url || match?.poster_url || '',
      backdrop_url: item.backdrop_url || match?.backdrop_url || '',
      genre: match?.genre || [],
      score: match?.score,
      rating: match?.rating,
      season_number: item.media_type === 'series' ? item.season_number : undefined,
      episode_number: item.media_type === 'series' ? item.episode_number : undefined,
      total_seasons: item.media_type === 'series' ? item.total_seasons : undefined,
      total_episodes: item.media_type === 'series' ? item.total_episodes : undefined,
      season_episodes: item.media_type === 'series' ? item.season_episodes : undefined,
    } satisfies Movie;
  });
}
