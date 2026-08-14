import { describe, expect, it } from 'vitest';
import { buildContinueWatchingItems } from '../lib/watch-history';

describe('buildContinueWatchingItems', () => {
  it('deduplica séries pelo tmdb_id e mantém o episódio mais recente no mesmo card', () => {
    const historyItems = [
      {
        id: 1,
        tmdb_id: 101,
        media_type: 'series',
        season_number: 1,
        episode_number: 2,
        total_seasons: 3,
        total_episodes: 20,
        season_episodes: 10,
        title: 'Example Series',
        poster_url: 'old.jpg',
        backdrop_url: 'old-backdrop.jpg',
        progress_percent: 20,
        watched_at: '2024-01-01T00:00:00.000Z',
      },
      {
        id: 2,
        tmdb_id: 101,
        media_type: 'series',
        season_number: 1,
        episode_number: 3,
        total_seasons: 3,
        total_episodes: 20,
        season_episodes: 10,
        title: 'Example Series',
        poster_url: 'new.jpg',
        backdrop_url: 'new-backdrop.jpg',
        progress_percent: 80,
        watched_at: '2024-01-02T00:00:00.000Z',
      },
      {
        id: 3,
        tmdb_id: 202,
        media_type: 'movie',
        season_number: 0,
        episode_number: 0,
        total_seasons: 0,
        total_episodes: 0,
        season_episodes: 0,
        title: 'Example Movie',
        poster_url: 'movie.jpg',
        backdrop_url: 'movie-backdrop.jpg',
        progress_percent: 50,
        watched_at: '2024-01-03T00:00:00.000Z',
      },
    ];

    const movies = [
      {
        id: 'series-1',
        tmdb_id: 101,
        title: 'Example Series',
        type: 'series' as const,
        year: 2024,
        poster_url: 'from-movies.jpg',
        backdrop_url: 'from-movies-backdrop.jpg',
        genre: ['Drama'],
        score: 8.4,
        rating: '18',
      },
    ];

    const result = buildContinueWatchingItems(historyItems as any, movies as any);

    expect(result).toHaveLength(2);
    expect(result.find((item) => item.tmdb_id === 101)).toMatchObject({
      tmdb_id: 101,
      season_number: 1,
      episode_number: 3,
      poster_url: 'new.jpg',
      type: 'series',
    });
    expect(result.find((item) => item.tmdb_id === 202)).toMatchObject({
      tmdb_id: 202,
      type: 'movie',
    });
  });
});
