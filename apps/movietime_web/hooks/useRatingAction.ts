'use client';

import { useCallback } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';

export type RatingValue = 'love' | 'like' | 'dislike';

type RatingsPayload = { ratings: Record<string, string> };

export function ratingsQueryKey(userId: number | null | undefined) {
  return ['ratings', userId] as const;
}

export function getRatingFromMap(
  ratings: Record<string, string> | undefined,
  tmdbId: number | string | null | undefined,
  mediaType: string | null | undefined,
): RatingValue | null {
  if (!ratings || tmdbId == null || tmdbId === '' || !mediaType) return null;
  const key = `${tmdbId}_${mediaType}`;
  const value = ratings[key] ?? ratings[String(tmdbId)];
  if (value === 'love' || value === 'like' || value === 'dislike') return value;
  return null;
}

/** Busca e cacheia todas as avaliações do usuário (compartilhado entre modal e Watch). */
export function useUserRatings(userId: number | null) {
  return useQuery({
    queryKey: ratingsQueryKey(userId),
    queryFn: async (): Promise<RatingsPayload> => {
      const res = await fetch(`/api/ratings?userId=${userId}`);
      if (!res.ok) return { ratings: {} };
      const data = await res.json();
      return { ratings: data?.ratings ?? {} };
    },
    enabled: !!userId,
    staleTime: 5 * 60 * 1000,
    gcTime: 30 * 60 * 1000,
  });
}

/**
 * Hook de rating com cache React Query.
 * currentRating vem do cache (instantâneo se já carregado); ratingReady evita flash de ícone vazio.
 */
export function useRatingAction(
  userId: number | null,
  tmdbId: number | null | undefined,
  mediaType: string | null | undefined,
  onNotAuthenticated?: () => void,
) {
  const queryClient = useQueryClient();
  const { data, isFetched, isPending } = useUserRatings(userId);

  const currentRating = getRatingFromMap(data?.ratings, tmdbId, mediaType);
  // Sem usuário: pronto (não há rating). Com usuário: pronto após primeiro fetch (cache conta).
  const ratingReady = !userId || isFetched;

  const handleRatingAction = useCallback(
    async (id: number, type: string, value: RatingValue | null) => {
      if (value === null) return;

      const uid =
        userId ??
        (() => {
          try {
            return JSON.parse(localStorage.getItem('userBasicInfo') || '{}').id ?? null;
          } catch {
            return null;
          }
        })();

      if (!uid) {
        onNotAuthenticated?.();
        return;
      }

      const key = `${id}_${type}`;
      const previous = getRatingFromMap(
        queryClient.getQueryData<RatingsPayload>(ratingsQueryKey(uid))?.ratings,
        id,
        type,
      );

      // Otimista no cache compartilhado
      queryClient.setQueryData<RatingsPayload>(ratingsQueryKey(uid), (old) => ({
        ratings: { ...(old?.ratings ?? {}), [key]: value },
      }));

      try {
        const res = await fetch('/api/ratings', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ userId: uid, tmdbId: id, mediaType: type, value }),
        });
        if (!res.ok) {
          queryClient.setQueryData<RatingsPayload>(ratingsQueryKey(uid), (old) => {
            const ratings = { ...(old?.ratings ?? {}) };
            if (previous) ratings[key] = previous;
            else delete ratings[key];
            return { ratings };
          });
        }
      } catch {
        queryClient.setQueryData<RatingsPayload>(ratingsQueryKey(uid), (old) => {
          const ratings = { ...(old?.ratings ?? {}) };
          if (previous) ratings[key] = previous;
          else delete ratings[key];
          return { ratings };
        });
      }
    },
    [userId, onNotAuthenticated, queryClient],
  );

  return {
    currentRating,
    ratingReady,
    /** true enquanto o primeiro fetch está em andamento (sem cache ainda) */
    ratingLoading: !!userId && isPending && !isFetched,
    handleRatingAction,
  };
}
