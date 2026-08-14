'use client';

import { useEffect, useState, useMemo, useRef, Component, type ReactNode } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Play, Plus, Check, Volume2, VolumeX } from 'lucide-react';
import { Movie } from '@/types/movie';
import { cn, toTmdbOriginalUrl } from '@/lib/utils';
import { calcMatch } from '@/lib/match';
import { easeOutQuint, movieModalContent, slideUpFade, staggerContainer, modalStagger, modalSlideUp } from '@/lib/motion';
import { TMDBService } from './TMDBIntegration';
import TrailerBackdrop from './TrailerBackdrop';
import RatingTooltip from '@/components/ui/RatingTooltip';
import RatingButtonIcon from '@/components/ui/RatingButtonIcon';
import RatingParticles from '@/components/ui/RatingParticles';
import NetflixBadge from '@/components/streaming/NetflixBadge';
import { getAgeRatingColor } from '@/lib/ageRating';
import { useRatingAction } from '@/hooks/useRatingAction';
import ActionStatusSkeleton from '@/components/ui/ActionStatusSkeleton';
import { getOfficialTrailer } from '@/lib/trailerCache';

class ModalErrorBoundary extends Component<{children: ReactNode}, {hasError: boolean}> {
    constructor(props: {children: ReactNode}) {
        super(props);
        this.state = { hasError: false };
    }
    static getDerivedStateFromError(error: any) {
        console.error('[MODAL-ERROR]', error);
        return { hasError: true };
    }
    componentDidCatch(error: any, info: any) {
        console.error('[MODAL-ERROR-DETAIL]', error, info);
    }
    render() {
        if (this.state.hasError) {
            return null;
        }
        return this.props.children;
    }
}

interface MovieModalProps {
    movie: Movie | null;
    isOpen: boolean;
    onClose: () => void;
    onWatch: (movie: Movie) => void;
    onAddToList: (movie: Movie) => void;
    isInWatchlist?: boolean;
    /** false enquanto a watchlist ainda não foi carregada (evita flash + → ✓) */
    listReady?: boolean;
    onRemoveFromList?: (movie: Movie) => void;
}

export default function MovieModal({ movie, isOpen, onClose, onWatch, onAddToList, isInWatchlist, listReady = true, onRemoveFromList }: MovieModalProps) {
    const [cast, setCast] = useState<any[]>([]);
    const [similar, setSimilar] = useState<Movie[]>([]);
    const [similarLoading, setSimilarLoading] = useState(true);
    const [similarImagesLoaded, setSimilarImagesLoaded] = useState<Set<number>>(new Set());
    const [trailers, setTrailers] = useState<{ key: string; name: string; type: string; site: string; official: boolean; size: number }[]>([]);
    const [backdropTrailerKey, setBackdropTrailerKey] = useState<string | null>(null);
    const [trailerPlaying, setTrailerPlaying] = useState(false);
    const [keywords, setKeywords] = useState<string[]>([]);
    const [isMuted, setIsMuted] = useState(true);
    const [logoUrl, setLogoUrl] = useState<string | null>(null);
    const [isOnNetflix, setIsOnNetflix] = useState(false);
    const [detailGenres, setDetailGenres] = useState<string[]>([]);
    const [showRatingTooltip, setShowRatingTooltip] = useState(false);
    const [ratingParticlesPos, setRatingParticlesPos] = useState<{ x: number; y: number } | null>(null);
    const [listParticlesPos, setListParticlesPos] = useState<{ x: number; y: number } | null>(null);
    const ratingBtnRef = useRef<HTMLButtonElement>(null);
    const listBtnRef = useRef<HTMLButtonElement>(null);
    const [userId, setUserId] = useState<number | null>(null);
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

    useEffect(() => {
        try {
            const stored = localStorage.getItem('userBasicInfo');
            if (stored) setUserId(JSON.parse(stored).id ?? null);
        } catch { /* ignore */ }
    }, []);

    const { currentRating, ratingReady, handleRatingAction } = useRatingAction(
        userId,
        movie?.tmdb_id != null ? Number(movie.tmdb_id) : null,
        movie?.type,
        () => { onClose(); window.dispatchEvent(new Event('requireLogin')); },
    );

    const [details, setDetails] = useState<{
        overview?: string;
        runtime?: number;
        number_of_seasons?: number;
        number_of_episodes?: number;
        ageRating?: string;
        tagline?: string;
        first_air_date?: string;
        last_air_date?: string;
        director?: string;
        created_by?: string;
        score?: number;
    } | null>(null);

    const [favoriteGenres, setFavoriteGenres] = useState<string[]>([]);

    // match calcula com os dados que já temos — sem aguardar nada extra
    const matchPercentage = useMemo(() => {
        const score = details?.score ?? movie?.score;
        if (!score) return null;
        return calcMatch(
            score,
            detailGenres.length > 0 ? detailGenres : (movie?.genre || []),
            currentRating,
            favoriteGenres,
        );
    }, [details?.score, movie?.score, detailGenres, movie?.genre, currentRating, favoriteGenres]);

    const handleAddToListGuarded = (movie: Movie) => {
        // Usa userBasicInfo (fonte de verdade do app) em vez de sb-session
        const isAuthenticated = typeof window !== 'undefined' && !!localStorage.getItem('userBasicInfo');
        if (!isAuthenticated) {
            onClose();
            window.dispatchEvent(new Event('requireLogin'));
            return;
        }
        onAddToList(movie);
    };

    useEffect(() => {
        if (!isOpen || !movie) {
            document.body.style.overflow = 'unset';
            return;
        }

        document.body.style.overflow = 'hidden';
        let cancelled = false;

        // ── Reset imediato com dados disponíveis do card ────────────────────
        setCast([]);
        setSimilar([]);
        setSimilarLoading(true);
        setSimilarImagesLoaded(new Set());
        setTrailers([]);
        setBackdropTrailerKey(null);
        setTrailerPlaying(false);
        setIsMuted(true);
        setKeywords([]);
        setLogoUrl(null);
        setIsOnNetflix(false);
        setShowRatingTooltip(false);
        setFavoriteGenres([]);
        setRatingParticlesPos(null);
        setListParticlesPos(null);
        // Popula body imediatamente com o que temos — sem skeleton
        setDetailGenres(movie.genre || []);
        setDetails({
            overview: movie.synopsis,
            ageRating: movie.rating,
            runtime: undefined,
            number_of_seasons: undefined,
            number_of_episodes: undefined,
        });

        const tmdbId = Number(movie.tmdb_id || movie.id);
        const isSeries = movie.type === 'series';

        // ── ONDA 1: crítico — detalhes + logo em paralelo (aparece rápido) ──
        Promise.all([
            isSeries
                ? TMDBService.fetchSeriesDetails(tmdbId)
                : TMDBService.fetchMovieDetails(tmdbId),
            TMDBService.fetchMovieLogos(tmdbId, isSeries),
            TMDBService.fetchWatchProviders(tmdbId, isSeries),
        ]).then(([detailsData, logos, providers]) => {
            if (cancelled || !detailsData) return;
            if (detailsData.cast) setCast(detailsData.cast.slice(0, 5));
            if (detailsData.genres) setDetailGenres(detailsData.genres);
            setDetails({
                overview: detailsData.overview || movie.synopsis,
                runtime: 'runtime' in detailsData ? (detailsData as any).runtime : undefined,
                number_of_seasons: 'number_of_seasons' in detailsData ? (detailsData as any).number_of_seasons : undefined,
                number_of_episodes: 'number_of_episodes' in detailsData ? (detailsData as any).number_of_episodes : undefined,
                ageRating: detailsData.ageRating || movie.rating,
                tagline: detailsData.tagline,
                first_air_date: 'first_air_date' in detailsData ? (detailsData as any).first_air_date : undefined,
                last_air_date: 'last_air_date' in detailsData ? (detailsData as any).last_air_date : undefined,
                director: 'director' in detailsData ? (detailsData as any).director : undefined,
                created_by: 'created_by' in detailsData
                    ? (Array.isArray((detailsData as any).created_by)
                        ? (detailsData as any).created_by.map((c: any) => c.name).join(', ')
                        : (detailsData as any).created_by)
                    : undefined,
                score: (detailsData as any).vote_average ?? undefined,
            });

            if (logos && logos.length > 0) setLogoUrl(logos[0].file_path);

            if (providers?.flatrate) {
                setIsOnNetflix(providers.flatrate.some(p =>
                    p.provider_name.toLowerCase().includes('netflix')
                ));
            }
        }).catch(() => { /* ignore */ });

        // ── ONDA 2: preferências do usuário (ratings vêm do React Query / useRatingAction) ─
        if (userId) {
            fetch(`/api/auth/profile?userId=${userId}`)
                .then(r => r.json())
                .then((profileData) => {
                    if (cancelled) return;
                    if (profileData?.user?.preferences?.genres) {
                        setFavoriteGenres(profileData.user.preferences.genres);
                    }
                })
                .catch(() => { /* ignore */ });
        }

        // ── ONDA 2: similares (secundário, não bloqueia body) ──────────────
        TMDBService.fetchSimilar(tmdbId, isSeries).then((similarMovies) => {
            if (cancelled) return;
            setSimilar(similarMovies.slice(0, 6) as Movie[]);
            setSimilarLoading(false);
        }).catch(() => {
            if (!cancelled) setSimilarLoading(false);
        });

        // ── ONDA 2: trailers + keywords (baixa prioridade) ───────────────────
        TMDBService.fetchMovieVideos(tmdbId, isSeries).then((v) => {
            if (!cancelled) setTrailers(v);
        }).catch(() => {});
        getOfficialTrailer(tmdbId, isSeries).then((best) => {
            if (!cancelled) setBackdropTrailerKey(best?.key ?? null);
        }).catch(() => {
            if (!cancelled) setBackdropTrailerKey(null);
        });
        TMDBService.fetchMovieKeywords(tmdbId, isSeries)
            .then(kw => { if (!cancelled) setKeywords(kw.map(k => k.name)); })
            .catch(() => {});

        return () => {
            cancelled = true;
            document.body.style.overflow = 'unset';
        };
    }, [isOpen, movie?.tmdb_id, movie?.id, movie?.type, userId]);

    if (!movie) return null;

    // Backdrop sempre em máxima qualidade (TMDB /original/)
    const bgUrl = toTmdbOriginalUrl(movie.backdrop_url || movie.poster_url) || '';

    return (
        <ModalErrorBoundary>
        <>
        <AnimatePresence>
        {isOpen && (
            <div key={movie.tmdb_id ?? movie.id} className="fixed inset-0 z-[110]">
                    {/* Fundo escurecido ao abrir o modal */}
                    <motion.div
                        key="modal-overlay"
                        className="fixed inset-0 z-[110] bg-black/60"
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        transition={{ duration: 0.2 }}
                        onClick={onClose}
                        aria-hidden
                    />

                    {/* Modal Content */}
                    <motion.div
                        key="modal-container"
                        className="fixed inset-0 z-[111] flex items-start justify-center px-4 py-8 md:p-8 overflow-y-auto scrollbar-hide pb-[calc(60px+env(safe-area-inset-bottom,0px))] md:pb-8"
                        {...movieModalContent}
                    >
                        <div className="relative w-full max-w-[850px] bg-[#181818] rounded-lg shadow-[0_28px_80px_rgba(0,0,0,0.65)] overflow-hidden my-8"
                        >
                        <div className="relative h-[478px] w-full overflow-hidden">
                            {/* Backdrop Image + trailer oficial HD (TMDB) */}
                            {bgUrl && (
                                <motion.div
                                    className={cn(
                                        'absolute inset-0 transition-opacity duration-700',
                                        trailerPlaying ? 'opacity-0' : 'opacity-100'
                                    )}
                                    style={{
                                        backgroundImage: `url("${bgUrl}")`,
                                        backgroundSize: 'cover',
                                        backgroundPosition: 'center top',
                                        backgroundRepeat: 'no-repeat',
                                    }}
                                    initial={{ opacity: 1, filter: 'blur(18px)' }}
                                    animate={{ opacity: 1, filter: 'blur(0px)' }}
                                    transition={{ duration: 2.2, ease: easeOutQuint }}
                                />
                            )}

                            {isOpen && (
                                <TrailerBackdrop
                                    youtubeKey={backdropTrailerKey}
                                    muted={isMuted}
                                    loop={false}
                                    startDelayMs={600}
                                    revealDelayMs={4000}
                                    className="z-[1]"
                                    onPlayingChange={setTrailerPlaying}
                                />
                            )}

                            {/* Dark overlay */}
                            <div className="absolute inset-0 z-10" style={{ backgroundColor: 'rgba(0,0,0,0.22)' }} />

                            {/* Top-left soft glow */}
                            <div className="absolute inset-0 z-20 pointer-events-none" style={{
                                background: 'radial-gradient(circle at 14% 18%, rgba(255,255,255,0.22) 0%, rgba(255,255,255,0.08) 20%, transparent 45%)'
                            }} />

                            {/* Bottom Fade (mantido um pouco mais para baixo) */}
                            <div className="absolute inset-x-0 bottom-[-20px] h-[200px] bg-linear-to-t from-[#181818] via-[#181818]/94 to-transparent z-30" />

                            {/* Close Button */}
                            <button
                                onClick={onClose}
                                className="absolute top-6 right-6 z-40 w-9 h-9 flex items-center justify-center bg-[#181818]/70 text-white rounded-full hover:bg-white/10 transition-colors"
                            >
                                <X className="w-5 h-5" strokeWidth={2.2} />
                            </button>

                            {/* Main Title Area — logo aparece com fade suave quando carregado */}
                            <div className="absolute left-6 md:left-12 bottom-[108px] z-20">
                                {isOnNetflix && (
                                    <div className="flex items-center gap-2 mb-4 opacity-[0.74]">
                                        <img src="/assets/netflix-n.png" alt="Netflix" className="w-[18px] h-[32px] object-contain" />
                                        <span className="text-xs font-bold uppercase tracking-[0.16em] text-white">
                                            {movie.type === 'series' ? 'Série' : 'Filme'}
                                        </span>
                                    </div>
                                )}
                                
                                {logoUrl && (
                                    <motion.img
                                        src={`https://image.tmdb.org/t/p/original${logoUrl}`}
                                        alt={movie.title}
                                        className="h-20 md:h-32 object-contain filter drop-shadow-2xl max-w-[80vw] md:max-w-none"
                                        initial={{ opacity: 0 }}
                                        animate={{ opacity: 1 }}
                                        transition={{ duration: 0.6, ease: easeOutQuint }}
                                    />
                                )}
                            </div>

                            {/* Actions Area */}
                            <div className="absolute left-6 md:left-12 bottom-10 z-30 flex items-center gap-3">
                                <div className="flex items-center gap-3">
                                    <button
                                        onClick={() => onWatch(movie)}
                                        className="bg-white hover:bg-[#e6e6e6] text-black font-bold h-[48px] px-7 rounded-[2px] transition-all flex items-center gap-2"
                                    >
                                        <svg width="20" height="24" viewBox="0 0 20 24" fill="black">
                                            <path d="M19.4951 10.5876C20.1603 10.9831 20.1436 11.9519 19.465 12.324L1.4809 22.1878C0.8145 22.5533 0 22.0711 0 21.311L0 0.7577C0 -0.01775 0.8444 -0.49812 1.5109 -0.10191L19.4951 10.5876Z" transform="translate(0, 1)"/>
                                        </svg>
                                        <span className="text-base font-bold">Assistir</span>
                                    </button>

                                    <button
                                        ref={listBtnRef}
                                        onClick={() => {
                                            if (isInWatchlist && onRemoveFromList) {
                                                onRemoveFromList(movie);
                                            } else {
                                                addJustTriggered.current = true;
                                                requestAnimationFrame(() => { handleAddToListGuarded(movie); });
                                            }
                                        }}
                                        className="w-12 h-12 flex items-center justify-center bg-[#2a2a2a] hover:bg-[#333] border-2 border-white/50 rounded-full text-white transition-all backdrop-blur-md"
                                        aria-busy={!listReady}
                                    >
                                        {!listReady ? (
                                            <ActionStatusSkeleton size={22} />
                                        ) : isInWatchlist ? (
                                            <Check className="w-7 h-7" />
                                        ) : (
                                            <Plus className="w-7 h-7" />
                                        )}
                                    </button>
                                    
                                    <div className="relative">
                                        <button
                                            ref={ratingBtnRef}
                                            onClick={() => {
                                                const uid = userId ?? (localStorage.getItem('userBasicInfo') ? true : false);
                                                if (!uid) {
                                                    onClose();
                                                    window.dispatchEvent(new Event('requireLogin'));
                                                    return;
                                                }
                                                if (!ratingReady) return;
                                                // Sempre abre o tooltip: avaliar ou trocar avaliação (nunca remove)
                                                setShowRatingTooltip(!showRatingTooltip);
                                            }}
                                            className="w-12 h-12 flex items-center justify-center border-2 rounded-full border-white/50 bg-[#2a2a2a] hover:bg-[#333] text-white transition-all backdrop-blur-md"
                                            aria-label={currentRating ? 'Alterar avaliação' : 'Avaliar este título'}
                                            aria-busy={!ratingReady}
                                        >
                                            {!ratingReady ? (
                                                <ActionStatusSkeleton size={22} />
                                            ) : (
                                                <RatingButtonIcon rating={currentRating} />
                                            )}
                                        </button>

                                        <AnimatePresence>
                                        {showRatingTooltip && (
                                            <motion.div
                                                className="absolute bottom-full left-1/2 -translate-x-1/2 mb-3 z-50"
                                                initial={{ opacity: 0, scale: 0.85, y: 8 }}
                                                animate={{ opacity: 1, scale: 1, y: 0 }}
                                                exit={{ opacity: 0, scale: 0.85, y: 8 }}
                                                transition={{ duration: 0.15, ease: 'easeOut' }}
                                            >
                                                <RatingTooltip
                                                    currentRating={currentRating}
                                                    onRate={(value) => {
                                                        const id = Number(movie?.tmdb_id);
                                                        if (id) handleRatingAction(id, movie!.type, value);
                                                        setShowRatingTooltip(false);
                                                        const el = ratingBtnRef.current;
                                                        if (el) {
                                                            const r = el.getBoundingClientRect();
                                                            setRatingParticlesPos({ x: r.left + r.width / 2, y: r.top + r.height / 2 });
                                                        }
                                                    }}
                                                />
                                            </motion.div>
                                        )}
                                        </AnimatePresence>
                                    </div>
                                </div>
                            </div>
                            {ratingParticlesPos && (
                                <RatingParticles
                                    x={ratingParticlesPos.x}
                                    y={ratingParticlesPos.y}
                                    onComplete={() => setRatingParticlesPos(null)}
                                />
                            )}
                            {listParticlesPos && (
                                <RatingParticles
                                    x={listParticlesPos.x}
                                    y={listParticlesPos.y}
                                    onComplete={() => setListParticlesPos(null)}
                                />
                            )}

                            {/* Volume — ativo com trailer oficial tocando */}
                            <div className="absolute right-4 md:right-8 bottom-10 z-30">
                                <button
                                    type="button"
                                    disabled={!backdropTrailerKey || !trailerPlaying}
                                    onClick={() => setIsMuted((m) => !m)}
                                    aria-label={isMuted ? 'Ativar som do trailer' : 'Silenciar trailer'}
                                    className={cn(
                                        'w-12 h-12 flex items-center justify-center border-2 rounded-full transition-all',
                                        backdropTrailerKey && trailerPlaying
                                            ? 'bg-[#2a2a2a]/80 border-white/50 text-white hover:bg-[#333] cursor-pointer'
                                            : 'bg-transparent border-white/10 text-white/30 cursor-not-allowed'
                                    )}
                                >
                                    {isMuted ? <VolumeX className="w-6 h-6" /> : <Volume2 className="w-6 h-6" />}
                                </button>
                            </div>
                        </div>

                        {/* Body Section */}
                        <div className="px-6 md:px-12 pb-12 pt-0 bg-[#181818]">
                            <AnimatePresence mode="wait">
                                {(
                                    <motion.div
                                        key="body-content"
                                        variants={modalStagger}
                                    >
                            <motion.div className="grid grid-cols-1 md:grid-cols-[1fr_240px] gap-12" variants={modalSlideUp}>
                                {/* Left Column: Summary */}
                                <div className="space-y-5">
                                    {/* Meta row */}
                                    <div className="flex flex-wrap items-center gap-2 text-base">
                                        {matchPercentage != null
                                            ? <span className="text-[#46d369] font-bold">{matchPercentage}% Match</span>
                                            : <span className="text-[#46d369] font-bold">{movie.score ? `${Math.round(movie.score * 10)}% Match` : '--% Match'}</span>
                                        }
                                        <span className="text-[#bcbcbc]">{movie.year}</span>
                                        <span className="text-[#bcbcbc]">
                                            {movie.type === 'series'
                                                ? details?.number_of_seasons
                                                    ? `${details.number_of_seasons} Temporada${details.number_of_seasons > 1 ? 's' : ''}`
                                                    : '1 Temporada'
                                                : details?.runtime
                                                ? `${Math.floor(details.runtime / 60)}h ${details.runtime % 60}m`
                                                : movie.duration}
                                        </span>
                                        <span className="px-1.5 py-0.5 border border-[#808080] text-[11px] font-bold rounded-[2px] text-[#e5e5e5]">
                                            {details?.ageRating || movie.rating || '14+'}
                                        </span>
                                        <span className="px-1.5 py-0.5 border border-white/20 text-[10px] font-bold rounded-[2px] text-white/60">HD</span>
                                        <svg className="w-10 h-4" viewBox="0 0 39 16" fill="none" aria-label="Audiodescrição">
                                            <path fillRule="evenodd" clipRule="evenodd" d="M0 16L11.1999 0H15.9999V16H11.9999V14.4H7.19996L5.59997 16H0ZM11.9999 5.6L8.8 10.4H11.9999V5.6Z" fill="#BCBCBC"/>
                                            <path fillRule="evenodd" clipRule="evenodd" d="M16.8 0V16H24.8C26.4 15.7 29.6 14.4 29.6 8C29.3 5.3 27.7 0 23.2 0H16.8ZM20.8 11.2V4.8C24 4.8 24.8 6.9 24.8 8C24.8 10.6 23.7 11.2 23.2 11.2H20.8Z" fill="#BCBCBC"/>
                                            <path d="M28.8 0C32 1.6 32 14.4 28.8 16H29.6C33.6 13.6 33.6 2.4 29.6 0L28.8 0Z" fill="#BCBCBC"/>
                                            <path d="M32 0C35.2 1.6 35.2 14.4 32 16H32.8C36.8 13.6 36.8 2.4 32.8 0L32 0Z" fill="#BCBCBC"/>
                                        </svg>
                                    </div>

                                    {/* Top 10 Badge */}
                                    {movie.rank && movie.rank <= 10 && (
                                        <div className="flex items-center">
                                            <svg width="245" height="30" viewBox="0 0 245 30" fill="none" aria-label={`#${movie.rank} em ${movie.type === 'series' ? 'Séries' : 'Filmes'} hoje`}>
                                                <rect y="1.0957" width="27.8086" height="27.8086" rx="3.47608" fill="#F50723"/>
                                                <path d="M7.72649 13.7028H6.16834V8.3974H4.05576V7.04955H9.83908V8.3974H7.72649V13.7028Z" fill="white"/>
                                                <path d="M13.27 13.8557C12.7729 13.8557 12.3141 13.7697 11.903 13.5976C11.4824 13.4255 11.1192 13.1866 10.8228 12.8711C10.5169 12.5557 10.278 12.1924 10.1155 11.7622C9.94339 11.3416 9.85736 10.8828 9.85736 10.3762C9.85736 9.86951 9.94339 9.41067 10.1155 8.98051C10.278 8.5599 10.5169 8.19665 10.8228 7.8812C11.1192 7.56574 11.4824 7.32676 11.903 7.1547C12.3141 6.98263 12.7729 6.8966 13.27 6.8966C13.7766 6.8966 14.2355 6.98263 14.6561 7.1547C15.0671 7.32676 15.4304 7.56574 15.7363 7.8812C16.0422 8.19665 16.2812 8.5599 16.4532 8.98051C16.6157 9.41067 16.7018 9.86951 16.7018 10.3762C16.7018 10.8828 16.6157 11.3416 16.4532 11.7622C16.2812 12.1924 16.0422 12.5557 15.7363 12.8711C15.4304 13.1866 15.0671 13.4255 14.6561 13.5976C14.2355 13.7697 13.7766 13.8557 13.27 13.8557ZM13.27 12.4792C13.6333 12.4792 13.9583 12.3931 14.2355 12.2115C14.5127 12.0395 14.723 11.7909 14.8855 11.4755C15.048 11.16 15.1245 10.7968 15.1245 10.3762C15.1245 9.95555 15.048 9.58274 14.8855 9.26728C14.723 8.95183 14.5127 8.71285 14.2355 8.53123C13.9583 8.35916 13.6333 8.27313 13.27 8.27313C12.9163 8.27313 12.6009 8.35916 12.3236 8.53123C12.0464 8.71285 11.8266 8.95183 11.6736 9.26728C11.5111 9.58274 11.4346 9.95555 11.4346 10.3762C11.4346 10.7968 11.5111 11.16 11.6736 11.4755C11.8266 11.7909 12.0464 12.0395 12.3236 12.2115C12.6009 12.3931 12.9163 12.4792 13.27 12.4792Z" fill="white"/>
                                                <path d="M17.3002 13.7028V7.04955H20.0533C20.5982 7.04955 21.0761 7.14514 21.4681 7.33632C21.86 7.52751 22.1659 7.79517 22.3762 8.1393C22.5865 8.48343 22.6916 8.88492 22.6916 9.34376C22.6916 9.8026 22.5865 10.2041 22.3762 10.5482C22.1659 10.9019 21.86 11.1696 21.4681 11.3608C21.0761 11.5519 20.5982 11.6475 20.0533 11.6475H18.8584V13.7028H17.3002ZM18.8584 10.3284H19.8239C20.2732 10.3284 20.5982 10.2423 20.8085 10.0703C21.0092 9.90775 21.1144 9.65921 21.1144 9.34376C21.1144 9.0283 21.0092 8.78932 20.8085 8.61726C20.5982 8.45475 20.2732 8.36872 19.8239 8.36872H18.8584V10.3284Z" fill="white"/>
                                                <text x="9" y="24" fill="white" fontSize="13" fontWeight="900" fontFamily="'Netflix Sans'">{movie.rank}</text>
                                                <text x="35" y="21" fill="white" fontSize="17" fontWeight="400" fontFamily="'Netflix Sans'">#{movie.rank} em {movie.type === 'series' ? 'Séries' : 'Filmes'} hoje</text>
                                            </svg>
                                        </div>
                                    )}

                                    <p className="text-white text-[16px] leading-[26px] font-normal">
                                        {details?.overview || movie.synopsis}
                                    </p>
                                </div>

                                {/* Right Column: Meta */}
                                <div className="space-y-3.5 text-sm leading-5">
                                    <div className="flex flex-wrap gap-1">
                                        <span className="text-[#777777]">Elenco:</span>
                                        <span className="text-white">{cast.map(c => c.name).join(', ') || 'Informação indisponível'}</span>
                                    </div>
                                    <div className="flex flex-wrap gap-1">
                                        <span className="text-[#777777]">Gêneros:</span>
                                        <span className="text-white">{detailGenres.length > 0 ? detailGenres.join(', ') : movie.genre?.join(', ') || 'Filmes, Séries'}</span>
                                    </div>
                                </div>
                            </motion.div>

                            {/* More Like This */}
                            <motion.div
                                className="mt-12"
                                variants={modalSlideUp}
                            >
                                <h3 className="text-2xl font-bold text-white mb-6 tracking-tight">Títulos semelhantes</h3>
                                <AnimatePresence mode="popLayout">
                                {similarLoading ? (
                                    <motion.div
                                        key="skeleton"
                                        className="flex flex-wrap gap-x-5 gap-y-4"
                                        initial={{ opacity: 0 }}
                                        animate={{ opacity: 1 }}
                                        exit={{ opacity: 0 }}
                                        transition={{ duration: 0.2 }}
                                    >
                                        {Array.from({ length: 6 }).map((_, i) => (
                                            <div
                                                key={i}
                                                className="bg-[#2f2f2f] rounded-[4px] overflow-hidden flex flex-col flex-1 min-w-[200px] w-[calc(33.333%-13.33px)] animate-pulse"
                                            >
                                                <div className="w-full aspect-video bg-[#3a3a3a]" />
                                                <div className="px-4 pt-4 pb-1">
                                                    <div className="h-3 bg-[#3a3a3a] rounded w-3/4" />
                                                </div>
                                                <div className="flex items-center justify-between px-4 pb-3">
                                                    <div className="flex items-center gap-2">
                                                        <div className="h-5 bg-[#3a3a3a] rounded-[3px] w-14" />
                                                        <div className="h-5 bg-[#3a3a3a] rounded-[4px] w-9" />
                                                        <div className="h-4 bg-[#3a3a3a] rounded w-10" />
                                                    </div>
                                                    <div className="w-10 h-10 rounded-full bg-[#3a3a3a]" />
                                                </div>
                                                <div className="px-[14px] pb-[14px] flex-1 space-y-1.5">
                                                    <div className="h-3 bg-[#3a3a3a] rounded w-full" />
                                                    <div className="h-3 bg-[#3a3a3a] rounded w-5/6" />
                                                    <div className="h-3 bg-[#3a3a3a] rounded w-4/6" />
                                                </div>
                                                </div>
                                            ))}
                                        </motion.div>
                                    ) : similar.length > 0 && (
                                    <motion.div
                                        className="flex flex-wrap gap-x-5 gap-y-4"
                                        variants={staggerContainer}
                                        initial="initial"
                                        animate="animate"
                                    >
                                        {similar.map((item, idx) => {
                                            const loaded = similarImagesLoaded.has(idx);
                                            return (
                                            <motion.div
                                                key={idx}
                                                onClick={() => onWatch(item)}
                                                className="bg-[#2f2f2f] rounded-[4px] overflow-hidden group cursor-pointer flex flex-col flex-1 min-w-[200px] w-[calc(33.333%-13.33px)]"
                                                variants={slideUpFade}
                                            >
                                                <div className="relative w-full aspect-video bg-[#3a3a3a]">
                                                    <img
                                                        src={item.backdrop_url || item.poster_url}
                                                        alt=""
                                                        loading="lazy"
                                                        onLoad={() => setSimilarImagesLoaded(prev => new Set(prev).add(idx))}
                                                        className={`w-full h-full object-cover transition-opacity duration-500 ${loaded ? 'opacity-100' : 'opacity-0'}`}
                                                    />
                                                    {loaded && (
                                                        <>
                                                            <NetflixBadge className="absolute top-[7px] left-[7px] z-10" />
                                                            {item.duration && (
                                                                <span className="absolute top-[7px] right-[7px] bg-black/60 px-[6px] py-[2px] rounded-[3px] text-[12px] font-normal text-white/92 leading-none">{item.duration}</span>
                                                            )}
                                                        </>
                                                    )}
                                                    <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity bg-black/40">
                                                        <div className="w-10 h-10 rounded-full bg-white/20 backdrop-blur-md flex items-center justify-center border border-white/40">
                                                            <Play className="w-5 h-5 fill-white" />
                                                        </div>
                                                    </div>
                                                </div>
                                                    <div className="px-4 pt-3 pb-0.5">
                                                        {item.score != null && (
                                                            <p className="text-[#46d369] text-[11px] font-bold leading-none mb-1.5">{Math.round(item.score * 10)}% Match</p>
                                                        )}
                                                        <p className="text-white text-[13px] font-medium leading-tight truncate">{item.title}</p>
                                                    </div>
                                                    <div className="flex items-center justify-between px-4 pb-3">
                                                        <div className="flex items-center gap-2">
                                                        <span className="px-[6.5px] border border-[#bcbcbc] text-[13px] font-semibold rounded-[2px] text-white/88 leading-none py-[5px]">{item.rating || '14'}</span>
                                                        <span className="px-[6.5px] border border-[#808080] text-[13px] font-semibold rounded-[2px] text-white/88 leading-none py-[5px]">HD</span>
                                                        <span className="text-[#bcbcbc] text-[15px] font-normal">{item.year}</span>
                                                        </div>
                                                        <button className="w-10 h-10 rounded-full bg-[#2a2a2a] border-2 border-white/50 flex items-center justify-center text-white">
                                                            <Plus className="w-5 h-5" strokeWidth={1.5} />
                                                        </button>
                                                    </div>
                                                    <div className="px-[14px] pb-[14px] flex-1">
                                                        <p className="text-[#d2d2d2] text-[14px] leading-[20px] line-clamp-4">{item.synopsis}</p>
                                                    </div>
                                            </motion.div>
                                            );
                                        })}
                                    </motion.div>
                                )}
                            </AnimatePresence>
                            </motion.div>

                            {/* Trailers & More */}
                            {trailers.length > 0 && (
                                <motion.div
                                    className="mt-12"
                                    variants={modalSlideUp}
                                >
                                    <h3 className="text-2xl font-bold text-white mb-6 tracking-tight">Trailers e mais</h3>
                                    <div className="flex gap-[33px]">
                                        {trailers.map((trailer, i) => (
                                            <a
                                                key={i}
                                                href={`https://www.youtube.com/watch?v=${trailer.key}`}
                                                target="_blank"
                                                rel="noopener noreferrer"
                                                className="group block flex-1 min-w-0 max-w-[236px]"
                                            >
                                                <div className="relative w-full aspect-[236/132] overflow-hidden rounded-t-[4px] bg-white/10">
                                                    <img
                                                        src={`https://img.youtube.com/vi/${trailer.key}/mqdefault.jpg`}
                                                        alt=""
                                                        loading="lazy"
                                                        className="w-full h-full object-cover"
                                                    />
                                                    <div className="absolute inset-0 bg-black/0 group-hover:bg-black/40 transition-colors flex items-center justify-center">
                                                        <div className="w-10 h-10 rounded-full bg-white/20 backdrop-blur-md flex items-center justify-center border border-white/40 opacity-0 group-hover:opacity-100 transition-opacity">
                                                            <Play className="w-5 h-5 fill-white" />
                                                        </div>
                                                    </div>
                                                </div>
                                                <div className="w-full px-4 py-4 flex items-center justify-center">
                                                    <p className="text-white text-[16px] font-medium leading-tight text-center line-clamp-2">{trailer.name}</p>
                                                </div>
                                            </a>
                                        ))}
                                    </div>
                                </motion.div>
                            )}

                            {/* About Section */}
                            <div className="mt-12">
                                <div className="flex items-center gap-1.5 mb-5">
                                    <span className="text-white text-[24px] font-normal leading-[30px]">Sobre</span>
                                    <span className="text-white text-[24px] font-medium leading-[30px]">{movie.title}</span>
                                </div>
                                <div className="flex flex-col gap-2 text-[15px] leading-[20px]">
                                    {movie.type === 'series' ? (
                                        <>
                                            <p><span className="text-[#777777]">Criado por: </span><span className="text-white">{details?.created_by || 'Informação indisponível'}</span></p>
                                            <p><span className="text-[#777777]">Elenco: </span><span className="text-white">{cast.map(c => c.name).join(', ')}</span></p>
                                            <p><span className="text-[#777777]">Gêneros: </span><span className="text-white">{detailGenres.length > 0 ? detailGenres.join(', ') : movie.genre?.join(', ') || 'Filmes, Séries'}</span></p>
                                            {details?.number_of_seasons && details?.number_of_episodes && (
                                                <p><span className="text-[#777777]">Temporadas: </span><span className="text-white">{details.number_of_seasons} temporada{details.number_of_seasons > 1 ? 's' : ''} • {details.number_of_episodes} episódios</span></p>
                                            )}
                                        </>
                                    ) : (
                                        <>
                                            <p><span className="text-[#777777]">Direção: </span><span className="text-white">{details?.director || 'Informação indisponível'}</span></p>
                                            <p><span className="text-[#777777]">Elenco: </span><span className="text-white">{cast.map(c => c.name).join(', ')}</span></p>
                                            <p><span className="text-[#777777]">Gêneros: </span><span className="text-white">{detailGenres.length > 0 ? detailGenres.join(', ') : movie.genre?.join(', ') || 'Filmes, Séries'}</span></p>
                                        </>
                                    )}
                                    
                                    {keywords.length > 0 && (
                                        <p><span className="text-[#777777]">Este programa é: </span><span className="text-white">{keywords.join(', ')}</span></p>
                                    )}
                                    
                                    <div className="flex flex-col gap-1 text-[15px] leading-[20px]">
                                        <div className="flex items-center gap-3.5">
                                            <span className="text-[#777777]">Classificação:</span>
                                            <span className="px-[6.5px] py-[2px] border border-[#bcbcbc] rounded text-[13px] font-semibold text-white/88 leading-none">{details?.ageRating || movie.rating || '14+'}</span>
                                        </div>
                                        <span className="text-white/70 text-sm flex items-center gap-2 flex-wrap">
                                            recomendado para maiores de
                                            {/* Badge vermelho — só no texto de recomendação (estilo página Assistir) */}
                                            <span
                                                className="inline-flex items-center justify-center rounded-[2px] min-w-[24px] h-[22px] px-1 shadow-sm"
                                                style={{ backgroundColor: getAgeRatingColor(details?.ageRating || movie.rating || '14+') }}
                                            >
                                                <span
                                                    className="text-white"
                                                    style={{
                                                        fontFamily: '"Netflix Sans"',
                                                        fontSize: '12px',
                                                        fontWeight: 900,
                                                        lineHeight: 'normal',
                                                        letterSpacing: '-0.5px',
                                                    }}
                                                >
                                                    {(() => {
                                                        const raw = details?.ageRating || movie.rating || '14+';
                                                        const num = String(raw).replace(/[^\d]/g, '') || '14';
                                                        return num;
                                                    })()}
                                                </span>
                                            </span>
                                            anos
                                        </span>
                                    </div>
                                </div>
                            </div>
                        </motion.div>
                    )}
                    </AnimatePresence>
                </div>
            </div>
        </motion.div>
    </div>
)}
</AnimatePresence>
</>
</ModalErrorBoundary>
);
}
