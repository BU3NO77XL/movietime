const cache = new Map<number, boolean>();

// Sistema de batching para evitar muitas chamadas simultâneas
const pendingBatch = new Set<number>();
const waiters = new Map<number, Array<(value: boolean) => void>>();
let batchTimeout: ReturnType<typeof setTimeout> | null = null;

function resolveWaiters(tmdbId: number, value: boolean) {
  cache.set(tmdbId, value);
  const resolvers = waiters.get(tmdbId);
  if (resolvers) {
    resolvers.forEach((resolve) => resolve(value));
    waiters.delete(tmdbId);
  }
  pendingBatch.delete(tmdbId);
}

async function processBatch(tmdbIds: number[]): Promise<Map<number, boolean>> {
  const results = new Map<number, boolean>();
  const BATCH_SIZE = 5;
  const BATCH_DELAY = 800;

  try {
    const { TMDBService } = await import('@/components/streaming/TMDBIntegration');

    for (let i = 0; i < tmdbIds.length; i += BATCH_SIZE) {
      const chunk = tmdbIds.slice(i, i + BATCH_SIZE);

      const promises = chunk.map(async (tmdbId) => {
        try {
          const series = await TMDBService.fetchSeriesDetails(tmdbId);
          if (!series?.seasons) return [tmdbId, false] as [number, boolean];

          const currentYear = new Date().getFullYear();
          const hasNewSeasonThisYear = series.seasons.some((s: { air_date?: string | null }) => {
            if (!s.air_date) return false;
            const year = new Date(s.air_date).getFullYear();
            return year === currentYear;
          });

          return [tmdbId, hasNewSeasonThisYear] as [number, boolean];
        } catch {
          return [tmdbId, false] as [number, boolean];
        }
      });

      const chunkResults = await Promise.allSettled(promises);
      chunkResults.forEach((result) => {
        if (result.status === 'fulfilled') {
          const [id, hasNew] = result.value;
          results.set(id, hasNew);
          resolveWaiters(id, hasNew);
        }
      });

      if (i + BATCH_SIZE < tmdbIds.length) {
        await new Promise((resolve) => setTimeout(resolve, BATCH_DELAY));
      }
    }
  } catch {
    tmdbIds.forEach((id) => {
      results.set(id, false);
      resolveWaiters(id, false);
    });
  }

  // Garante resolução de qualquer id que tenha falhado no settled
  tmdbIds.forEach((id) => {
    if (!results.has(id)) {
      results.set(id, false);
      resolveWaiters(id, false);
    }
  });

  return results;
}

function scheduleBatch() {
  if (batchTimeout) clearTimeout(batchTimeout);
  batchTimeout = setTimeout(async () => {
    const idsToProcess = Array.from(pendingBatch);
    batchTimeout = null;
    if (idsToProcess.length > 0) {
      // Remove do pending antes de processar; waiters ficam até resolveWaiters
      idsToProcess.forEach((id) => pendingBatch.delete(id));
      await processBatch(idsToProcess);
    }
  }, 150);
}

/**
 * Verifica se a série tem temporada com air_date no ano atual.
 * Aguarda o batch processar (não retorna false prematuramente).
 */
export async function checkHasNewSeason(tmdbId: number): Promise<boolean> {
  if (cache.has(tmdbId)) return cache.get(tmdbId)!;

  return new Promise<boolean>((resolve) => {
    const existing = waiters.get(tmdbId);
    if (existing) {
      existing.push(resolve);
      return;
    }

    waiters.set(tmdbId, [resolve]);
    pendingBatch.add(tmdbId);
    scheduleBatch();
  });
}

/** Verifica múltiplos IDs de uma vez (útil para carrosséis). */
export async function checkMultipleNewSeasons(tmdbIds: number[]): Promise<Map<number, boolean>> {
  const unique = [...new Set(tmdbIds)];
  const uncachedIds = unique.filter((id) => !cache.has(id));

  if (uncachedIds.length > 0) {
    await processBatch(uncachedIds);
  }

  const results = new Map<number, boolean>();
  unique.forEach((id) => results.set(id, cache.get(id) ?? false));
  return results;
}
