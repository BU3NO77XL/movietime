// Cache module-level de trailers oficiais HD (hero / modal backdrop)

export type OfficialTrailer = { key: string; name: string; size: number };

const cache = new Map<string, OfficialTrailer | null>();
const inflight = new Map<string, Promise<OfficialTrailer | null>>();

function cacheKey(tmdbId: number, isSeries: boolean): string {
  return `${isSeries ? 'tv' : 'movie'}:${tmdbId}`;
}

export function getCachedTrailer(tmdbId: number, isSeries: boolean): OfficialTrailer | null | undefined {
  const key = cacheKey(tmdbId, isSeries);
  if (!cache.has(key)) return undefined;
  return cache.get(key) ?? null;
}

/** Melhor trailer oficial HD do TMDB (cache + dedupe). */
export async function getOfficialTrailer(
  tmdbId: number,
  isSeries: boolean
): Promise<OfficialTrailer | null> {
  const key = cacheKey(tmdbId, isSeries);
  if (cache.has(key)) return cache.get(key) ?? null;

  const pending = inflight.get(key);
  if (pending) return pending;

  const promise = (async () => {
    try {
      const { TMDBService } = await import('@/components/streaming/TMDBIntegration');
      const trailer = await TMDBService.fetchBestOfficialTrailer(tmdbId, isSeries);
      cache.set(key, trailer);
      return trailer;
    } catch {
      cache.set(key, null);
      return null;
    } finally {
      inflight.delete(key);
    }
  })();

  inflight.set(key, promise);
  return promise;
}
