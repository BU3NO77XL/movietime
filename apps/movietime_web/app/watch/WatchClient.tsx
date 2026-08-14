'use client';

import { useState, useEffect, Suspense, memo, useRef, useMemo, useCallback } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Movie, CastMember } from '@/types/movie';
import { motion } from 'framer-motion';

import { toast } from 'sonner';
import { TMDBService } from '@/components/streaming/TMDBIntegration';
import CastSlider from '@/components/streaming/CastSlider';
import Carousel from '@/components/streaming/Carousel';
import MovieModal from '@/components/streaming/MovieModal';
import { useRatingAction } from '@/hooks/useRatingAction';
import { useWatchNavigation } from '@/hooks/useWatchNavigation';
import { useLogoStore } from '@/stores/logoStore';
import LoginRequiredModal from '@/components/streaming/LoginRequiredModal';
import ShareModal from '@/components/ui/ShareModal';
import WatchHero from '@/components/watch/WatchHero';
import WatchSynopsis from '@/components/watch/WatchSynopsis';
import WatchEpisodes from '@/components/watch/WatchEpisodes';
import WatchSeriesDetails from '@/components/watch/WatchSeriesDetails';
import WatchCollection from '@/components/watch/WatchCollection';
import WatchCreatorSeries from '@/components/watch/WatchCreatorSeries';

// Hook para preload de imagens — chave estável evita loop de re-render
const useImagePreload = (urls: string[]) => {
    const [loadedImages, setLoadedImages] = useState<Set<string>>(() => new Set());
    const key = urls.join('|');

    useEffect(() => {
        if (!key) return;
        const list = key.split('|').filter(Boolean);
        let cancelled = false;

        list.forEach((url) => {
            const img = new window.Image();
            img.onload = () => {
                if (cancelled) return;
                setLoadedImages((prev) => {
                    if (prev.has(url)) return prev;
                    const next = new Set(prev);
                    next.add(url);
                    return next;
                });
            };
            img.src = url;
        });

        return () => { cancelled = true; };
    }, [key]);

    return loadedImages;
};

// Skeleton Components for Loading States
const Skeleton = memo(({ className }: { className?: string }) => (
    <div className={`animate-pulse bg-white/10 rounded ${className}`} />
));
Skeleton.displayName = 'Skeleton';

const SectionSkeleton = memo(() => (
    <div className="py-8">
        <div className="bg-[#1a1a1a] rounded-xl p-6 sm:p-8">
            <Skeleton className="h-6 w-48 mb-4" />
            <div className="flex gap-3 overflow-hidden">
                {[...Array(5)].map((_, i) => (
                    <Skeleton key={i} className="w-28 sm:w-32 lg:w-36 aspect-2/3 rounded-lg shrink-0" />
                ))}
            </div>
        </div>
    </div>
));
SectionSkeleton.displayName = 'SectionSkeleton';

const CastSkeleton = memo(() => (
    <div className="py-8 border-b border-white/10">
        <Skeleton className="h-6 w-40 mb-4" />
        <div className="flex gap-4 mb-4">
            {[...Array(6)].map((_, i) => (
                <Skeleton key={i} className="w-24 h-24 sm:w-28 sm:h-28 rounded-full shrink-0" />
            ))}
        </div>
        <div className="bg-[#1f1f1f] rounded-lg p-4">
            <div className="flex gap-4">
                <Skeleton className="w-28 sm:w-32 aspect-3/4 shrink-0" />
                <div className="flex-1 space-y-3">
                    <Skeleton className="h-5 w-32" />
                    <Skeleton className="h-4 w-24" />
                    <Skeleton className="h-20 w-full" />
                </div>
            </div>
        </div>
    </div>
));
CastSkeleton.displayName = 'CastSkeleton';

export default function Watch() {
    return (
        <Suspense fallback={<WatchLoading />}>
            <WatchContent />
        </Suspense>
    );
}

function WatchLoading() {
    return (
        <div className="min-h-screen bg-[#0a0a0a] flex items-center justify-center">
            <div className="w-10 h-10 border-2 border-white/20 border-t-white rounded-full animate-spin" />
        </div>
    );
}


function WatchContent() {
    const queryClient = useQueryClient();
    const router = useRouter();
    const searchParams = useSearchParams();
    const movieId = searchParams.get('id');
    const urlTmdbId = searchParams.get('ref');
    const urlMediaType = searchParams.get('type') || 'movie';
    const urlRank = searchParams.get('rank');
    const urlSeason = searchParams.get('season');
    const urlEpisode = searchParams.get('episode');

    // Override local — ao clicar em item da Coleção, troca o filme SEM navegar
    // Isso elimina o round-trip ao servidor em produção
    const [localOverride, setLocalOverride] = useState<{
        tmdbId: string;
        mediaType: string;
        title: string;
        poster_url: string;
        backdrop_url: string;
        year: number;
    } | null>(null);

    // Hook de navegação otimizada (recebe setLocalOverride para fast-path)
    const { navigateToWatch } = useWatchNavigation(setLocalOverride);
    
    const { getLogosForMovie } = useLogoStore();

    // Valores ativos (override local tem prioridade sobre URL)
    const tmdbId = localOverride?.tmdbId ?? urlTmdbId;
    const mediaType = localOverride?.mediaType ?? urlMediaType;

    // Limpar override se a URL mudar externamente (ex: botão voltar do browser)
    useEffect(() => {
        if (localOverride && urlTmdbId !== localOverride.tmdbId) {
            setLocalOverride(null);
        }
    }, [urlTmdbId, localOverride]);

    const navStartRef = useRef<number>(0);
    const lastLoggedTmdbId = useRef<string | null>(null);
    if (tmdbId !== lastLoggedTmdbId.current) {
        navStartRef.current = performance.now();
        lastLoggedTmdbId.current = tmdbId;
        const cached = queryClient.getQueryData(['movie', 'tmdb', tmdbId, mediaType]);
        void cached; // suprime unused warning
    }
    
    // Estado para controlar se o componente foi montado no cliente (evita erro de hidratação)
    const [isMounted, setIsMounted] = useState(false);

    // Marcar como montado após o primeiro render no cliente
    useEffect(() => {
        setIsMounted(true);
    }, []);

    // Quando o id da mídia mudar (navegação para outro filme/série),
    // em dispositivos móveis queremos garantir que a página comece no topo.
    useEffect(() => {
        if (typeof window === 'undefined') return;
        try {
            const isMobile = window.innerWidth <= 768; // breakpoint para 'sm'
            if (isMobile) {
                window.scrollTo({ top: 0, left: 0, behavior: 'auto' });
            }
        } catch (e) {
            // fallback silencioso
            window.scrollTo(0, 0);
        }
    }, [movieId, tmdbId]);
    const [movieDetails, setMovieDetails] = useState<{ overview?: string; budget?: number; director?: string; cast: CastMember[]; genres?: string[]; runtime?: number; tagline?: string; ageRating?: string; belongs_to_collection?: { id: number; name: string; poster_path: string; backdrop_path: string } | null } | null>(null);
    const [seriesDetails, setSeriesDetails] = useState<{ overview?: string; director?: string; cast: CastMember[]; genres?: string[]; tagline?: string; ageRating?: string; seasons?: { id: number; season_number: number; episode_count: number; name: string; air_date: string; poster_path: string }[]; number_of_seasons?: number; number_of_episodes?: number; first_air_date?: string; last_air_date?: string } | null>(null);
    const [seasonDetails, setSeasonDetails] = useState<{ episodes: { id: number; episode_number: number; name: string; overview: string; air_date: string; runtime: number; still_path: string; vote_average: number }[] } | null>(null);
    const [selectedSeason, setSelectedSeason] = useState<number>(urlSeason ? Number(urlSeason) : 1);
    const [selectedEpisode, setSelectedEpisode] = useState<number>(urlEpisode ? Number(urlEpisode) : 1);
    const [similarMovies, setSimilarMovies] = useState<Movie[]>([]);
    const [trailers, setTrailers] = useState<{ key: string; name: string; type: string }[]>([]);
    const [keywords, setKeywords] = useState<{ id: number; name: string }[]>([]);
    const [logos, setLogos] = useState<{
        file_path: string;
        file_type: string;
        width: number;
        height: number;
        iso_639_1: string | null;
    }[]>([]);

    // Estado para indicar se o logo está pronto (carregado ou não existe)
    const [isLogoReady, setIsLogoReady] = useState(false);
    const [collection, setCollection] = useState<{ id: number; name: string; overview: string; backdrop_path: string; parts: { id: number; title: string; poster_path: string; release_date: string }[] } | null>(null);
    const [creatorSeries, setCreatorSeries] = useState<Movie[]>([]);
    const [creatorInfo, setCreatorInfo] = useState<{ id: number; name: string } | null>(null);
    const [isLoadingDetails, setIsLoadingDetails] = useState(true);
    const [selectedModalMovie, setSelectedModalMovie] = useState<Movie | null>(null);
    const [ratingParticlesPos, setRatingParticlesPos] = useState<{ x: number; y: number } | null>(null);
    const [listParticlesPos, setListParticlesPos] = useState<{ x: number; y: number } | null>(null);
    const ratingBtnRef = useRef<HTMLButtonElement>(null);
    const listBtnRef = useRef<HTMLButtonElement>(null);
    // Estado para backdrops rotativos
    const [backdrops, setBackdrops] = useState<string[]>([]);
    const [currentBackdropIndex, setCurrentBackdropIndex] = useState(0);
    // Estado para armazenar detalhes atualizados da série (como no HeroSection)
    const [updatedSeriesDetails, setUpdatedSeriesDetails] = useState<Record<string, { runtime: string; year?: number }>>({});
    // Estado para controle de áudio do backdrop animado
    const [isBackdropMuted, setIsBackdropMuted] = useState(true);
    const [showRatingTooltip, setShowRatingTooltip] = useState(false);
    const [showShareModal, setShowShareModal] = useState(false);
    const [userId, setUserId] = useState<number | null>(null);
    useEffect(() => {
        try {
            const u = localStorage.getItem('userBasicInfo');
            if (u) {
                setUserId(JSON.parse(u).id);
            } else {
                router.replace('/');
                setTimeout(() => window.dispatchEvent(new Event('requireLogin')), 100);
            }
        } catch { 
            router.replace('/');
            setTimeout(() => window.dispatchEvent(new Event('requireLogin')), 100);
        }
    }, [router]);
    const [watchMatch, setWatchMatch] = useState<number | null>(null);

    const { data: watchlistData, isFetched: watchlistFetched } = useQuery({
        queryKey: ['watchlist', userId],
        queryFn: () => fetch(`/api/watchlist?userId=${userId}`).then(r => r.json()),
        enabled: !!userId,
        staleTime: 60_000,
    });
    const watchlistItems = watchlistData?.items ?? [];
    const listReady = !userId || watchlistFetched;

    const [showLoginModal, setShowLoginModal] = useState(false);
    const backdropVideoRef = useRef<HTMLVideoElement>(null);

    const SYNOPSIS_LIMIT = 250;

    // Buscar filme por ID (se passado na URL)
    const { data: movieById, isLoading: isLoadingById } = useQuery({
        queryKey: ['movies', movieId],
        queryFn: async () => {
            const movies = queryClient.getQueryData<Movie[]>(['movies']);
            return movies?.find(m => m.id === movieId) || null;
        },
        enabled: !!movieId,
        staleTime: 1000 * 60 * 30,
    });

    // Busca por TMDB ID (para filmes similares ou da pesquisa)
    const { data: movieByTmdb, isLoading: isLoadingByTmdb } = useQuery({
        queryKey: ['movie', 'tmdb', tmdbId, mediaType],
        queryFn: async () => {
            const movies = queryClient.getQueryData<Movie[]>(['movies']);
            const cached = movies?.find(m => Number(m.tmdb_id) === Number(tmdbId));
            if (cached) return cached;

            const tmdbIdNum = Number(tmdbId);
            const isSeries = mediaType === 'series';
            const endpoint = isSeries ? 'tv' : 'movie';

            let tmdbData: any = null;
            try {
                const response = await fetch(`/api/content/${endpoint}/${tmdbIdNum}?language=pt-BR`);
                if (response.ok) {
                    tmdbData = await response.json();
                }
            } catch { /* ignore */ }

            if (tmdbData && Object.keys(tmdbData).length > 0 && !tmdbData.error) {
                const title = tmdbData.title || tmdbData.name || 'Untitled';
                const releaseDate = tmdbData.release_date || tmdbData.first_air_date || '';
                const year = releaseDate ? new Date(releaseDate).getFullYear() : new Date().getFullYear();

                let duration = '2h 0m';
                if (isSeries) {
                    const seasons = tmdbData.number_of_seasons || 1;
                    duration = `${seasons} Temporada${seasons > 1 ? 's' : ''}`;
                } else if (tmdbData.runtime) {
                    duration = `${Math.floor(tmdbData.runtime / 60)}h ${tmdbData.runtime % 60}m`;
                }

                return {
                    id: `tmdb-${tmdbIdNum}`,
                    title,
                    type: isSeries ? 'series' as const : 'movie' as const,
                    year,
                    rating: 'NR',
                    duration,
                    genre: tmdbData.genres?.map((g: { name: string }) => g.name) || [],
                    synopsis: tmdbData.overview || '',
                    cast: [],
                    director: 'Unknown',
                    poster_url: tmdbData.poster_path ? `https://image.tmdb.org/t/p/w500${tmdbData.poster_path}` : '',
                    backdrop_url: tmdbData.backdrop_path ? `https://image.tmdb.org/t/p/original${tmdbData.backdrop_path}` : '',
                    score: tmdbData.vote_average ? parseFloat(Number(tmdbData.vote_average).toFixed(1)) : 0,
                    tmdb_id: tmdbIdNum,
                    category: 'trending' as const,
                };
            }

            return {
                id: `tmdb-${tmdbIdNum}`,
                title: 'Assistir',
                type: isSeries ? 'series' as const : 'movie' as const,
                year: new Date().getFullYear(),
                rating: 'NR',
                duration: '',
                genre: [],
                synopsis: '',
                cast: [],
                director: '',
                poster_url: '',
                backdrop_url: '',
                tmdb_id: tmdbIdNum,
                category: 'trending' as const,
            };
        },
        enabled: !!tmdbId,
    });

    // Override direto do filme para navegação instantânea entre similares
    const [localMovieOverride, setLocalMovieOverride] = useState<Movie | null>(null);
    useEffect(() => { if (!localOverride) setLocalMovieOverride(null); }, [localOverride]);
    const movieRaw = localMovieOverride || movieById || movieByTmdb;
    // URL type tem prioridade sobre o type armazenado (corrige cache corrompido)
    const movie = movieRaw ? { ...movieRaw, type: (mediaType as 'movie' | 'series') || movieRaw.type } : null;
    const watchlistTmdbIds = useMemo(
        () => new Set(watchlistItems.map((i: { tmdb_id: number }) => i.tmdb_id)),
        [watchlistItems],
    );
    const isInWatchlist = movie && movie.tmdb_id ? watchlistTmdbIds.has(Number(movie.tmdb_id)) : false;
    const prevInWatchlist = useRef(isInWatchlist);
    const addJustTriggered = useRef(false);

    useEffect(() => {
        if (prevInWatchlist.current === false && isInWatchlist === true && addJustTriggered.current) {
            addJustTriggered.current = false;
            const el = listBtnRef.current;
            if (el) {
                const r = el.getBoundingClientRect();
                setListParticlesPos({ x: r.left + r.width / 2, y: r.top + r.height / 2 });
            }
        }
        prevInWatchlist.current = isInWatchlist;
    }, [isInWatchlist]);

    const { currentRating, ratingReady, handleRatingAction } = useRatingAction(
        userId,
        movie?.tmdb_id != null ? Number(movie.tmdb_id) : null,
        movie?.type,
        () => setShowLoginModal(true),
    );

    // Histórico: mesma key base da home quando possível; filtra no cliente para hidratar cache
    const { data: historyPayload, isFetched: historyFetched } = useQuery({
        queryKey: ['watchHistory', userId],
        queryFn: () => fetch(`/api/watch-history?userId=${userId}`).then(r => r.json()),
        enabled: !!userId,
        staleTime: 60_000,
    });

    const savedHistory = useMemo(() => {
        if (!movie?.tmdb_id || movie.type !== 'series' || !historyPayload?.items?.length) return null;
        const tmdbIdNum = Number(movie.tmdb_id);
        const match = (historyPayload.items as Array<Record<string, unknown>>).find(
            (i) => Number(i.tmdb_id) === tmdbIdNum && i.media_type === movie.type,
        );
        if (!match) return null;
        const seasonNum = Number(match.season_number ?? match.seasonNumber ?? 0);
        const episodeNum = Number(match.episode_number ?? match.episodeNumber ?? 0);
        if (seasonNum > 0 && episodeNum > 0) {
            return { seasonNumber: seasonNum, episodeNumber: episodeNum };
        }
        return null;
    }, [historyPayload, movie?.tmdb_id, movie?.type]);

    // Pronto para decidir Assistir vs Continua (sem flash)
    const historyReady = !userId || movie?.type !== 'series' || historyFetched;

    // Match (não bloqueia botões de lista/rating)
    useEffect(() => {
        if (!userId || !movie?.tmdb_id || !movie.type) return;

        const tmdbIdNum = Number(movie.tmdb_id);
        let cancelled = false;

        const matchParams = new URLSearchParams({
            userId: String(userId),
            tmdbId: String(tmdbIdNum),
            mediaType: movie.type,
        });
        if (movie.score != null) matchParams.set('tmdbScore', String(movie.score));
        if (movie.genre?.length) matchParams.set('genres', movie.genre.join(','));

        fetch(`/api/match?${matchParams}`)
            .then(r => r.json())
            .then((matchData) => {
                if (cancelled) return;
                if (matchData?.match != null) setWatchMatch(matchData.match);
            })
            .catch(() => {});

        return () => { cancelled = true; };
    }, [userId, movie?.tmdb_id, movie?.type, movie?.score, movie?.genre]);

    // Se temos um override local (clique na Coleção), usar os dados básicos dele
    // enquanto o React Query busca os dados completos em background
    const isLoading = localOverride
        ? false  // com override local, nunca mostra loading — dados básicos já disponíveis
        : movieId
            ? isLoadingById  // tem movieId: só espera a query por ID
            : isLoadingByTmdb; // só tmdbId: espera a query por tmdb

    // Timeout de segurança: se demorar mais de 8s e ainda não tiver dados, mostrar erro
    const [loadingTimedOut, setLoadingTimedOut] = useState(false);
    useEffect(() => {
        if (!isLoading) { setLoadingTimedOut(false); return; }
        const t = setTimeout(() => setLoadingTimedOut(true), 8000);
        return () => clearTimeout(t);
    }, [isLoading, tmdbId, movieId]);

    // Se não estamos carregando mas também não temos filme, algo deu errado
    const hasValidData = movie && Object.keys(movie).length > 0 && movie.tmdb_id;
    const shouldShowError = ((!isLoading && !hasValidData) || loadingTimedOut) && isMounted;

    // Determinar se é série ou filme (precisa estar antes dos useEffects que usam)
    const isSeries = movie && movie.type === 'series';

    // Efeito para carregar logos pré-carregados do store global (Zustand-like/Context)
    useEffect(() => {
        if (movie?.tmdb_id) {
            const preloaded = getLogosForMovie(movie.tmdb_id);
            if (preloaded) {
                setLogos(preloaded.logos);
                setIsLogoReady(preloaded.logoImageLoaded);
            }
        }
    }, [movie?.id, movie?.tmdb_id, getLogosForMovie]);

    // Preload das imagens principais para evitar flash de loading
    const imagesToPreload = useMemo(
        () => (movie
            ? [movie.backdrop_url, movie.poster_url].filter((img): img is string => Boolean(img))
            : []),
        [movie?.backdrop_url, movie?.poster_url],
    );

    const preloadedImages = useImagePreload(imagesToPreload);

    // Preload dos backdrops adicionais
    const preloadedBackdrops = useImagePreload(backdrops);

    // Fetch series details for accurate season count (como no HeroSection)
    useEffect(() => {
        const tmdbIdNum = movie?.tmdb_id ? Number(movie.tmdb_id) : null;
        const movieId = movie?.id;
        if (!movieId || !tmdbIdNum || isNaN(tmdbIdNum) || movie?.type !== 'series') return;

        let cancelled = false;
        (async () => {
            try {
                const seriesData = await TMDBService.fetchSeriesDetails(tmdbIdNum);
                if (cancelled || !seriesData) return;
                setUpdatedSeriesDetails((prev) => {
                    if (prev[movieId]) return prev;
                    return {
                        ...prev,
                        [movieId]: {
                            runtime: `${seriesData.number_of_seasons} Temporada${seriesData.number_of_seasons !== 1 ? 's' : ''}`,
                            year: seriesData.first_air_date ? new Date(seriesData.first_air_date).getFullYear() : undefined
                        }
                    };
                });
            } catch { /* silent */ }
        })();
        return () => { cancelled = true; };
    }, [movie?.id, movie?.type, movie?.tmdb_id]);

    // Resetar todos os dados do filme/série anterior quando mudar
    useEffect(() => {
        setLogos([]);
        setIsLogoReady(false);
        setIsLoadingDetails(true);
        setCollection(null);
        setMovieDetails(null);
        setSeriesDetails(null);
        setSeasonDetails(null);
        setSelectedSeason(1);
        setSelectedEpisode(1);
        setSimilarMovies([]);
        /* skip trailers reset */
        setCreatorSeries([]);
        setCreatorInfo(null);
        setKeywords([]);
        setWatchMatch(null);
        setShowShareModal(false);
        setShowRatingTooltip(false);
        setSelectedModalMovie(null);
        setRatingParticlesPos(null);
        setListParticlesPos(null);
        setLocalMovieOverride(null);
        addJustTriggered.current = false;
        prevInWatchlist.current = false;
    }, [movieId, tmdbId]);

    // Query rápida só para logos — resolve antes dos outros detalhes
    // Isso faz o título personalizado aparecer sem esperar todos os fetches
    const { data: quickLogosData } = useQuery({
        queryKey: ['watchLogos', movie?.tmdb_id, movie?.type],
        queryFn: async () => {
            if (!movie?.tmdb_id) return [];
            return TMDBService.fetchMovieLogos(Number(movie.tmdb_id), movie.type === 'series');
        },
        enabled: !!movie?.tmdb_id,
        staleTime: 1000 * 60 * 60, // logos mudam raramente — cache 1h
    });

    // Aplicar logos rápidos assim que chegarem (antes do fetchedDetails completo)
    useEffect(() => {
        if (quickLogosData && quickLogosData.length > 0 && logos.length === 0) {
            setLogos(quickLogosData);
        }
    }, [quickLogosData, logos.length]);

    const { data: fetchedDetails, isLoading: isLoadingDetailsQuery } = useQuery({        queryKey: ['watchDetails', movie?.tmdb_id, movie?.type],
        queryFn: async () => {
            if (!movie?.tmdb_id) return null;
            const tmdbIdNum = Number(movie.tmdb_id);
            const isSeriesType = movie.type === 'series';

            if (isSeriesType) {
                // ── FASE 1: crítico (logos + detalhes básicos) em paralelo
                const [seriesData, logosData] = await Promise.all([
                    TMDBService.fetchSeriesDetails(tmdbIdNum),
                    TMDBService.fetchMovieLogos(tmdbIdNum, true),
                ]);

                // ── FASE 2: secundário em paralelo (não bloqueia fase 1)
                const [similar, videos, keywordsData, fullDetails] = await Promise.all([
                    TMDBService.fetchSimilar(tmdbIdNum, true),
                    Promise.resolve([]), // trailers UI desativada
                    TMDBService.fetchMovieKeywords(tmdbIdNum, true),
                    (TMDBService as any).fetchSeriesFullDetails ? (TMDBService as any).fetchSeriesFullDetails(tmdbIdNum) : Promise.resolve(null),
                ]);

                let seasonTargetSeasonNumber = urlSeason ? Number(urlSeason) : 0;
                let seasonData = null;
                if (seriesData?.seasons && seriesData.seasons.length > 0) {
                    const targetSeason = seasonTargetSeasonNumber
                        ? seriesData.seasons.find((s: any) => s.season_number === seasonTargetSeasonNumber) || seriesData.seasons[0]
                        : seriesData.seasons.find((s: any) => s.season_number === 1) || seriesData.seasons[0];
                    if (targetSeason) {
                        seasonData = await TMDBService.fetchSeasonDetails(tmdbIdNum, targetSeason.season_number);
                        seasonData = { ...seasonData, season_number: targetSeason.season_number };
                    }
                }

                let creatorSeriesData: any[] = [];
                let creatorInfoData = null;
                if (fullDetails?.created_by && fullDetails.created_by.length > 0) {
                    creatorInfoData = fullDetails.created_by[0];
                    if ((TMDBService as any).fetchSeriesByCreator) {
                        const cs = await (TMDBService as any).fetchSeriesByCreator(creatorInfoData.id, tmdbIdNum);
                        creatorSeriesData = cs.map((s: any, i: number) => ({ ...s, id: `creator-${i}` }));
                    }
                }

                return {
                    isSeries: true,
                    seriesData,
                    seasonData,
                    creatorInfoData,
                    creatorSeriesData,
                    similar: similar.map((s: any, i: number) => ({ ...s, id: `similar-${i}` })),
                    videos,
                    keywordsData,
                    logosData
                };
            } else {
                // ── FASE 1: crítico (logos + detalhes básicos) em paralelo
                const [details, logosData] = await Promise.all([
                    TMDBService.fetchMovieDetails(tmdbIdNum),
                    TMDBService.fetchMovieLogos(tmdbIdNum, false),
                ]);

                // ── FASE 2: secundário em paralelo
                const [similar, videos, keywordsData] = await Promise.all([
                    TMDBService.fetchSimilar(tmdbIdNum, false),
                    Promise.resolve([]), // trailers UI desativada
                    TMDBService.fetchMovieKeywords(tmdbIdNum, false),
                ]);

                let collectionData = null;
                if (details?.belongs_to_collection?.id) {
                    collectionData = await TMDBService.fetchCollection(details.belongs_to_collection.id);
                }

                return {
                    isSeries: false,
                    details,
                    collectionData,
                    similar: similar.map((s: any, i: number) => ({ ...s, id: `similar-${i}` })),
                    videos,
                    keywordsData,
                    logosData
                };
            }
        },
        enabled: !!movie?.tmdb_id,
        staleTime: 1000 * 60 * 30, // 30 minutes
    });

    useEffect(() => {
        if (!fetchedDetails) return;

        // Aplicar logos imediatamente (aparecem antes do resto)
        if (fetchedDetails.logosData) setLogos(fetchedDetails.logosData);

        if (fetchedDetails.isSeries) {
            if (fetchedDetails.seriesData) setSeriesDetails(fetchedDetails.seriesData);
            if (fetchedDetails.seasonData) {
                const { season_number, ...seasonData } = fetchedDetails.seasonData as any;
                setSeasonDetails(seasonData);
                const targetSeason = urlSeason ? Number(urlSeason) : (savedHistory?.seasonNumber || season_number);
                const targetEpisode = urlEpisode ? Number(urlEpisode) : (savedHistory?.episodeNumber || 1);
                setSelectedSeason(targetSeason);
                setSelectedEpisode(targetEpisode);
            }
            if (fetchedDetails.creatorInfoData) setCreatorInfo(fetchedDetails.creatorInfoData);
            if (fetchedDetails.creatorSeriesData) setCreatorSeries(fetchedDetails.creatorSeriesData);
            setSimilarMovies(fetchedDetails.similar);
            /* trailers UI desativada — skip setTrailers */
            setKeywords(fetchedDetails.keywordsData);
        } else {
            if (fetchedDetails.details) setMovieDetails(fetchedDetails.details);
            if (fetchedDetails.collectionData) setCollection(fetchedDetails.collectionData);
            setSimilarMovies(fetchedDetails.similar);
            /* trailers UI desativada — skip setTrailers */
            setKeywords(fetchedDetails.keywordsData);
        }
        setIsLoadingDetails(false);
    }, [fetchedDetails]);

    // Efeito para pré-carregar a imagem do logo
    useEffect(() => {
        // Garantir que só roda no cliente
        if (!isMounted) return;
        
        // Se já temos logos pré-carregados do store, usar eles
        if (movie?.tmdb_id) {
            const preloaded = getLogosForMovie(movie.tmdb_id);
            if (preloaded && preloaded.logoImageLoaded) {
                setLogos(preloaded.logos);
                setIsLogoReady(true);
                return;
            }
        }

        // Se ainda está carregando detalhes ou não tem movie, aguardar
        if (isLoadingDetails || !movie) {
            return;
        }

        // Se já está pronto, não precisa recarregar
        if (isLogoReady) {
            return;
        }

        // Se não há logos após carregar detalhes, marca como pronto
        // Mas só se realmente terminou de carregar (isLoadingDetails = false)
        if (logos.length === 0) {
            // Pequeno delay para garantir que o React processou todos os updates
            const timer = setTimeout(() => {
                setIsLogoReady(true);
            }, 50);
            return () => clearTimeout(timer);
        }

        // Se há logo, pré-carrega a imagem
        const logoUrl = `https://image.tmdb.org/t/p/original${logos[0]?.file_path}`;
        const img = new window.Image();

        // Timeout de segurança: se demorar mais de 1.5 segundos, mostra mesmo assim
        const timeout = setTimeout(() => {
            setIsLogoReady(true);
        }, 1500);

        img.onload = () => {
            clearTimeout(timeout);
            setIsLogoReady(true);
        };

        img.onerror = () => {
            clearTimeout(timeout);
            setIsLogoReady(true);
        };

        img.src = logoUrl;

        return () => clearTimeout(timeout);
    }, [movie?.tmdb_id, movie, logos, getLogosForMovie, isLoadingDetails, isLogoReady, isMounted]);

    // Efeito para buscar e rotacionar backdrops
    useEffect(() => {
        // Resetar backdrops imediatamente quando o filme mudar
        setBackdrops([]);
        setCurrentBackdropIndex(0);

        if (!movie?.tmdb_id) return;

        const fetchBackdrops = async () => {
            const images = await TMDBService.fetchMovieImages(Number(movie.tmdb_id), movie.type === 'series');
            if (images.length > 0) {
                setBackdrops(images);
            }
        };

        fetchBackdrops();
    }, [movie?.tmdb_id, movie?.type]);

    useEffect(() => {
        if (backdrops.length <= 1) return;

        const tick = () => {
            if (document.hidden) return;
            setCurrentBackdropIndex((prev: number) => (prev + 1) % backdrops.length);
        };
        const interval = setInterval(tick, 8000);

        return () => clearInterval(interval);
    }, [backdrops]);

    // Função para buscar detalhes de uma temporada específica
    const fetchSeasonDetails = async (seasonNumber: number, targetEpisode?: number) => {
        // Verificar se temos um filme válido
        if (movie && Object.keys(movie).length > 0 && movie.tmdb_id) {
            setIsLoadingDetails(true);
            try {
                const seasonData = await TMDBService.fetchSeasonDetails(movie.tmdb_id, seasonNumber);
                setSeasonDetails(seasonData);
                setSelectedSeason(seasonNumber);
                setSelectedEpisode(targetEpisode ?? 1);
            } finally {
                setIsLoadingDetails(false);
            }
        }
    };

    useEffect(() => {
        if (!savedHistory || !movie?.tmdb_id || movie.type !== 'series') return;
        if (urlSeason || urlEpisode) return; // URL params take precedence
        if (savedHistory.seasonNumber > 0 && savedHistory.episodeNumber > 0) {
            if (selectedSeason !== savedHistory.seasonNumber) {
                fetchSeasonDetails(savedHistory.seasonNumber, savedHistory.episodeNumber);
            } else {
                setSelectedEpisode(savedHistory.episodeNumber);
            }
        }
    }, [savedHistory, movie?.tmdb_id, movie?.type, urlSeason, urlEpisode]);

    const addToListMutation = useMutation({
        mutationFn: () =>
            fetch('/api/watchlist', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    userId,
                    tmdbId: movie?.tmdb_id,
                    mediaType: movie?.type,
                    title: movie?.title,
                    posterUrl: movie?.poster_url,
                    backdropUrl: movie?.backdrop_url,
                }),
            }),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['watchlist', userId] });
            toast.success('Adicionado à sua lista!');
        },
    });

    const removeFromListMutation = useMutation({
        mutationFn: () =>
            fetch('/api/watchlist', {
                method: 'DELETE',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    userId,
                    tmdbId: movie?.tmdb_id,
                    mediaType: movie?.type,
                }),
            }),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['watchlist', userId] });
            toast.success('Removido da sua lista!');
        },
    });

    const handleLikeAction = useCallback(() => {
        if (!ratingReady) return;
        // Sempre abre o tooltip: avaliar ou trocar avaliação (nunca remove)
        setShowRatingTooltip((prev) => !prev);
    }, [ratingReady]);

    const handleSimilarMovieClick = useCallback((similarMovie: Movie) => {
        if (similarMovie && Object.keys(similarMovie).length > 0) {
            setLocalMovieOverride(similarMovie);
            navigateToWatch(similarMovie);
        }
    }, [navigateToWatch]);

    const handleToggleMute = useCallback(() => {
        setIsBackdropMuted((prev) => {
            const next = !prev;
            if (backdropVideoRef.current) {
                backdropVideoRef.current.muted = next;
            }
            return next;
        });
    }, []);

    const clearRatingParticles = useCallback(() => setRatingParticlesPos(null), []);
    const clearListParticles = useCallback(() => setListParticlesPos(null), []);


    // Verificar se temos um filme válido antes de renderizar
    // Removida a verificação de isLogoReady para evitar que a página fique travada no loading
    if (!isMounted || isLoading || !movie || Object.keys(movie).length === 0) {
        return <WatchLoading />;
    }

    // Se não está carregando mas também não tem dados válidos, mostrar erro
    if (shouldShowError) {
        return (
            <div className="min-h-screen bg-[#0a0a0a] flex items-center justify-center p-4">
                <div className="text-center max-w-md">
                    <h1 className="text-white text-2xl font-bold mb-4">Conteúdo não encontrado</h1>
                    <p className="text-gray-400 mb-6">Não foi possível carregar as informações deste título.</p>
                    <button
                        onClick={() => router.push('/')}
                        className="bg-white text-black px-6 py-2 rounded-sm font-semibold hover:bg-gray-200 transition"
                    >
                        Voltar para Home
                    </button>
                </div>
            </div>
        );
    }

    // Dados derivados de série ou filme
    const cast = isSeries ? seriesDetails?.cast || [] : movieDetails?.cast || [];
    const synopsis = isSeries ? seriesDetails?.overview || movie.synopsis || '' : movieDetails?.overview || movie.synopsis || '';

    // Obter valores atualizados para exibição (como no HeroSection)
    const displayDuration = isSeries && updatedSeriesDetails[movie.id]
        ? updatedSeriesDetails[movie.id].runtime
        : movie.duration;

    const displayYear = isSeries && updatedSeriesDetails[movie.id]?.year
        ? updatedSeriesDetails[movie.id].year
        : (isSeries ? seriesDetails?.first_air_date?.substring(0, 4) : movie.year);

    // Mapa de backdrops animados disponíveis (futuro: migrar para banco de dados)
    const animatedBackdrops: Record<string, { url: string; hasAudio: boolean }> = {
        'series-200875': { url: '/animated-backdrops/series-200875.mp4', hasAudio: true },      // Squid Game
        'movie-396422': { url: '/animated-backdrops/annabelle-backdrop.mp4', hasAudio: true },  // Annabelle
        'movie-1010581': { url: '/animated-backdrops/myfault-movie.mp4', hasAudio: false },     // My Fault (sem áudio)
        'movie-1156593': { url: '/animated-backdrops/sua-culpa-movie.mp4', hasAudio: false },   // Sua Culpa (sem áudio)
    };

    // Verificar se tem backdrop animado disponível
    const backdropKey = `${mediaType}-${movie.tmdb_id}`;
    const animatedBackdrop = animatedBackdrops[backdropKey] || null;
    const animatedBackdropUrl = animatedBackdrop?.url || null;
    const hasBackdropAudio = animatedBackdrop?.hasAudio || false;
    void hasBackdropAudio;

    const handleWatch = async () => {
        if (userId && movie?.tmdb_id) {
            try {
                await fetch('/api/watch-history', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        userId: String(userId),
                        tmdbId: String(movie.tmdb_id),
                        mediaType: movie.type,
                        seasonNumber: isSeries ? selectedSeason : undefined,
                        episodeNumber: isSeries ? selectedEpisode : undefined,
                        totalSeasons: isSeries ? seriesDetails?.number_of_seasons : undefined,
                        totalEpisodes: isSeries ? seriesDetails?.number_of_episodes : undefined,
                        seasonEpisodes: isSeries ? seriesDetails?.seasons?.find(s => s.season_number === selectedSeason)?.episode_count : undefined,
                        title: movie.title,
                        posterUrl: movie.poster_url,
                        backdropUrl: movie.backdrop_url,
                        progressPercent: 0,
                    }),
                });
                fetch('/api/achievements/check', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ userId, action: 'watched' }),
                }).catch(() => {});
            } catch (e) { /* silent */ }
        }
        const embedUrl = isSeries
            ? `https://megaembed.com/embed/${movie.tmdb_id}/${selectedSeason}/${selectedEpisode}`
            : `https://megaembed.com/embed/${movie.tmdb_id}`;
        window.location.href = embedUrl;
    };

    const handleToggleList = () => {
        if (!movie || Object.keys(movie).length === 0) return;
        if (!userId) {
            setShowLoginModal(true);
            return;
        }
        if (isInWatchlist) {
            removeFromListMutation.mutate();
        } else {
            addJustTriggered.current = true;
            addToListMutation.mutate();
        }
    };

    return (
        <div className="min-h-screen bg-[#0a0a0a]">
            {/* Hero Section - Similar to MovieModal */}
            <WatchHero
                movie={movie}
                isSeries={!!isSeries}
                logos={logos}
                isLoadingDetails={isLoadingDetails}
                seriesDetails={seriesDetails}
                movieDetails={movieDetails}
                backdrops={backdrops}
                currentBackdropIndex={currentBackdropIndex}
                preloadedImages={preloadedImages}
                preloadedBackdrops={preloadedBackdrops}
                animatedBackdropUrl={animatedBackdropUrl}
                isBackdropMuted={isBackdropMuted}
                onToggleMute={handleToggleMute}
                backdropVideoRef={backdropVideoRef}
                displayYear={displayYear}
                displayDuration={displayDuration}
                watchMatch={watchMatch}
                selectedSeason={selectedSeason}
                selectedEpisode={selectedEpisode}
                savedHistory={savedHistory}
                urlSeason={urlSeason}
                urlEpisode={urlEpisode}
                userId={userId}
                isInWatchlist={!!isInWatchlist}
                listReady={listReady}
                currentRating={currentRating}
                ratingReady={ratingReady}
                historyReady={historyReady}
                showRatingTooltip={showRatingTooltip}
                setShowRatingTooltip={setShowRatingTooltip}
                onWatch={handleWatch}
                onToggleList={handleToggleList}
                handleLikeAction={handleLikeAction}
                handleRatingAction={handleRatingAction}
                ratingParticlesPos={ratingParticlesPos}
                listParticlesPos={listParticlesPos}
                clearRatingParticles={clearRatingParticles}
                clearListParticles={clearListParticles}
                ratingBtnRef={ratingBtnRef}
                listBtnRef={listBtnRef}
                setShowShareModal={setShowShareModal}
                setRatingParticlesPos={setRatingParticlesPos}
            />

            {/* Content */}
            <motion.div
                className="relative z-20 bg-[#0a0a0a] overflow-clip"
                initial={{ opacity: 0, y: 30 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: 0.4, ease: 'easeOut' }}
            >
                <div className="max-w-[1400px] mx-auto px-4 sm:px-8 lg:px-12">

                    {/* Synopsis */}
                    <WatchSynopsis
                        synopsis={synopsis}
                        SYNOPSIS_LIMIT={SYNOPSIS_LIMIT}
                        isSeries={!!isSeries}
                        movieDetails={movieDetails}
                        movie={movie}
                    />


                    {/* Seletor de temporadas e carrossel de episódios para séries */}
                    {isSeries && seriesDetails?.seasons && seriesDetails.seasons.length > 0 && (
                        <WatchEpisodes
                            seriesDetails={seriesDetails}
                            seasonDetails={seasonDetails}
                            selectedSeason={selectedSeason}
                            selectedEpisode={selectedEpisode}
                            setSelectedEpisode={setSelectedEpisode}
                            isLoadingDetails={isLoadingDetails}
                            fetchSeasonDetails={fetchSeasonDetails}
                        />
                    )}

                    {/* Quick Info para SÉRIES - aparece DEPOIS dos episódios */}
                    {isSeries && (
                        <WatchSeriesDetails
                            seriesDetails={seriesDetails}
                            movie={movie}
                        />
                    )}

                    {/* Collection/Franchise */}
                    {collection && collection.parts.length > 1 && (
                        <WatchCollection
                            collection={collection}
                            movie={movie}
                            setLocalMovieOverride={setLocalMovieOverride}
                            setLocalOverride={setLocalOverride}
                            navigateToWatch={navigateToWatch}
                        />
                    )}


                    {/* Do Mesmo Criador - Para Séries (Slider estilo Collection com backdrop dinâmico) */}
                    {isSeries && creatorSeries.length > 0 && creatorInfo && (
                        <WatchCreatorSeries
                            creatorSeries={creatorSeries}
                            creatorInfo={creatorInfo}
                            navigateToWatch={navigateToWatch}
                            movie={movie}
                            setLocalMovieOverride={setLocalMovieOverride}
                        />
                    )}


                    {/* Cast */}
                    {isLoadingDetails ? (
                        <CastSkeleton />
                    ) : cast.length > 0 && (
                        <motion.section
                            className="py-8"
                            aria-label="Elenco principal do filme"
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ duration: 0.4, delay: 0.3, ease: 'easeOut' }}
                        >
                            <div className="bg-[#1a1a1a] rounded-xl p-6 sm:p-8 overflow-hidden">
                                <CastSlider cast={cast} />
                            </div>
                        </motion.section>
                    )}


                    {/* Trailers Section - DESATIVADO TEMPORARIAMENTE
                    (scroll state moved out of WatchContent; UI still disabled)
                    FIM - Trailers Section */}

                    {/* Discussões - Desativado temporariamente */}


                    {/* Similar Movies */}
                    {isLoadingDetails ? (
                        <SectionSkeleton />
                    ) : similarMovies.length > 0 && (
                        <motion.section
                            className="py-8"
                            aria-label="Títulos semelhantes a este filme"
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ duration: 0.4, delay: 0.4, ease: 'easeOut' }}
                        >
                                <h2 className="text-white text-xl md:text-2xl font-bold tracking-tight px-2 mb-3">Títulos Semelhantes</h2>
                                <div className="relative -mx-4 sm:-mx-8 lg:-mx-12">
                                    <Carousel
                                        title="Títulos Semelhantes"
                                        showTitle={false}
                                        movies={similarMovies}
                                        onMovieClick={handleSimilarMovieClick}
                                    />
                                </div>
                        </motion.section>
                    )}

                </div>
            </motion.div>
            {/* Movie Modal */}
            < MovieModal
                movie={selectedModalMovie}
                isOpen={!!selectedModalMovie}
                onClose={() => setSelectedModalMovie(null)}
                onWatch={(movie: Movie) => {
                    setSelectedModalMovie(null);
                    navigateToWatch(movie);
                }}
                onAddToList={() => { }}
            />
            {/* Modal de Login Necessário */}
            <LoginRequiredModal
                isOpen={showLoginModal}
                onClose={() => setShowLoginModal(false)}
            />
            {showShareModal && movie && (
                <ShareModal
                    movie={movie}
                    onClose={() => setShowShareModal(false)}
                />
            )}
        </div >
    );
}


