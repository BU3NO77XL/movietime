'use client';

import { memo, RefObject } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Play, Share2 } from 'lucide-react';
import { Movie, CastMember } from '@/types/movie';
import ProgressiveImage from '@/components/streaming/ProgressiveImage';
import MovieTitle from '@/components/streaming/MovieTitle';
import RatingTooltip from '@/components/ui/RatingTooltip';
import RatingButtonIcon from '@/components/ui/RatingButtonIcon';
import RatingParticles from '@/components/ui/RatingParticles';
import ActionStatusSkeleton from '@/components/ui/ActionStatusSkeleton';
import { getAgeRatingColor } from '@/lib/ageRating';
import type { RatingValue } from '@/hooks/useRatingAction';

interface WatchHeroProps {
    movie: Movie;
    isSeries: boolean;
    logos: {
        file_path: string;
        file_type: string;
        width: number;
        height: number;
        iso_639_1: string | null;
    }[];
    isLoadingDetails: boolean;
    seriesDetails: {
        overview?: string;
        director?: string;
        cast: CastMember[];
        genres?: string[];
        tagline?: string;
        ageRating?: string;
        seasons?: { id: number; season_number: number; episode_count: number; name: string; air_date: string; poster_path: string }[];
        number_of_seasons?: number;
        number_of_episodes?: number;
        first_air_date?: string;
        last_air_date?: string;
    } | null;
    movieDetails: {
        overview?: string;
        budget?: number;
        director?: string;
        cast: CastMember[];
        genres?: string[];
        runtime?: number;
        tagline?: string;
        ageRating?: string;
        belongs_to_collection?: { id: number; name: string; poster_path: string; backdrop_path: string } | null;
    } | null;
    backdrops: string[];
    currentBackdropIndex: number;
    preloadedImages: Set<string>;
    preloadedBackdrops: Set<string>;
    animatedBackdropUrl: string | null;
    isBackdropMuted: boolean;
    onToggleMute: () => void;
    backdropVideoRef: RefObject<HTMLVideoElement | null>;
    displayYear: string | number | undefined;
    displayDuration: string | undefined;
    watchMatch: number | null;
    selectedSeason: number;
    selectedEpisode: number;
    savedHistory: { seasonNumber: number; episodeNumber: number } | null;
    urlSeason: string | null;
    urlEpisode: string | null;
    userId: number | null;
    isInWatchlist: boolean;
    listReady: boolean;
    currentRating: RatingValue | null;
    ratingReady: boolean;
    historyReady: boolean;
    showRatingTooltip: boolean;
    setShowRatingTooltip: (show: boolean) => void;
    onWatch: () => void;
    onToggleList: () => void;
    handleLikeAction: () => void;
    handleRatingAction: (tmdbId: number, mediaType: string, value: RatingValue | null) => void;
    ratingParticlesPos: { x: number; y: number } | null;
    listParticlesPos: { x: number; y: number } | null;
    clearRatingParticles: () => void;
    clearListParticles: () => void;
    ratingBtnRef: RefObject<HTMLButtonElement | null>;
    listBtnRef: RefObject<HTMLButtonElement | null>;
    setShowShareModal: (show: boolean) => void;
    setRatingParticlesPos: (pos: { x: number; y: number } | null) => void;
}

const WatchHero = memo(function WatchHero({
    movie,
    isSeries,
    logos,
    isLoadingDetails,
    seriesDetails,
    movieDetails,
    backdrops,
    currentBackdropIndex,
    preloadedImages,
    preloadedBackdrops,
    animatedBackdropUrl,
    isBackdropMuted,
    onToggleMute,
    backdropVideoRef,
    displayYear,
    displayDuration,
    watchMatch,
    selectedSeason,
    selectedEpisode,
    savedHistory,
    urlSeason,
    urlEpisode,
    userId,
    isInWatchlist,
    listReady,
    currentRating,
    ratingReady,
    historyReady,
    showRatingTooltip,
    setShowRatingTooltip,
    onWatch,
    onToggleList,
    handleLikeAction,
    handleRatingAction,
    ratingParticlesPos,
    listParticlesPos,
    clearRatingParticles,
    clearListParticles,
    ratingBtnRef,
    listBtnRef,
    setShowShareModal,
    setRatingParticlesPos,
}: WatchHeroProps) {
    // Botão Continua ocupa mais espaço — oculta compartilhar para não quebrar o layout
    const showContinue =
        isSeries &&
        historyReady &&
        !!(savedHistory || (urlSeason && urlEpisode));

    return (
        <section className="relative h-[70vh] sm:h-[75vh] lg:h-[80vh] overflow-hidden">
            {/* Backdrop - Video animado ou Imagem */}
            <div className="absolute inset-0 overflow-hidden">
                {animatedBackdropUrl ? (
                    <video
                        ref={backdropVideoRef}
                        src={animatedBackdropUrl}
                        autoPlay
                        loop
                        muted={isBackdropMuted}
                        playsInline
                        preload="metadata"
                        className="w-full h-full object-cover"
                        onError={(e: any) => {
                            // console.error('Erro ao carregar vídeo de backdrop:', animatedBackdropUrl, e);
                        }}
                    />
                ) : (movie.backdrop_url || movie.poster_url) ? (
                    <div className="absolute inset-0 transition-opacity duration-2000 ease-in-out">
                        {(backdrops.length > 0 ? backdrops : [movie.backdrop_url || movie.poster_url]).map((bd, index) => (
                            <div
                                key={index}
                                className={`absolute inset-0 w-full h-full transition-all duration-2000 ease-out ${index === currentBackdropIndex
                                    ? 'opacity-100 scale-100'
                                    : 'opacity-0 scale-105'
                                    }`}
                                style={{
                                    filter: index === currentBackdropIndex ? 'blur(0px)' : 'blur(8px)'
                                }}
                            >
                                <ProgressiveImage
                                    src={bd}
                                    alt={movie.title}
                                    className="w-full h-full object-cover"
                                    preloaded={preloadedImages.has(bd) || preloadedBackdrops.has(bd)}
                                />
                            </div>
                        ))}
                    </div>
                ) : (
                    <div className="w-full h-full bg-linear-to-br from-[#1f1f1f] to-[#0a0a0a] flex items-center justify-center">
                        <span className="text-white/20 text-2xl font-bold">{movie.title}</span>
                    </div>
                )}
                <div className="absolute inset-0 bg-linear-to-t from-[#0a0a0a] via-[#0a0a0a]/60 to-transparent z-[1]" />
                <div className="absolute inset-0 bg-linear-to-r from-[#0a0a0a]/80 via-transparent to-transparent z-[2]" />
            </div>

            {/* Controles laterais desktop - volume e compartilhar */}
            <div className="hidden sm:flex absolute bottom-4 sm:bottom-8 lg:bottom-12 right-4 sm:right-8 lg:right-12 z-20 flex-col items-end gap-2">
                <button
                    onClick={onToggleMute}
                    className="bg-[#2a2a2a]/60 hover:bg-[#444444] border-2 border-[#ffffff]/70
                        rounded-full transition-all duration-200 flex items-center justify-center w-12 h-12 sm:w-10 sm:h-10 md:w-12 md:h-12
                        opacity-40 hover:opacity-100 focus:outline-none focus:ring-0"
                    aria-label={isBackdropMuted ? "Ativar som" : "Desativar som"}
                >
                    {isBackdropMuted ? (
                        <svg width="26" height="26" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                            <path fillRule="evenodd" clipRule="evenodd" d="M11 4.00003C11 3.59557 10.7564 3.23093 10.3827 3.07615C10.009 2.92137 9.57889 3.00692 9.29289 3.29292L4.58579 8.00003H1C0.447715 8.00003 0 8.44774 0 9.00003V15C0 15.5523 0.447715 16 1 16H4.58579L9.29289 20.7071C9.57889 20.9931 10.009 21.0787 10.3827 20.9239C10.7564 20.7691 11 20.4045 11 20V4.00003ZM5.70711 9.70714L9 6.41424V17.5858L5.70711 14.2929L5.41421 14H5H2V10H5H5.41421L5.70711 9.70714ZM15.2929 9.70714L17.5858 12L15.2929 14.2929L16.7071 15.7071L19 13.4142L21.2929 15.7071L22.7071 14.2929L20.4142 12L22.7071 9.70714L21.2929 8.29292L19 10.5858L16.7071 8.29292L15.2929 9.70714Z" fill="currentColor"></path>
                        </svg>
                    ) : (
                        <svg width="26" height="26" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                            <path fillRule="evenodd" clipRule="evenodd" d="M24 12C24 8.28699 22.525 4.72603 19.8995 2.10052L18.4853 3.51474C20.7357 5.76517 22 8.81742 22 12C22 15.1826 20.7357 18.2349 18.4853 20.4853L19.8995 21.8995C22.525 19.274 24 15.7131 24 12ZM11 4.00001C11 3.59555 10.7564 3.23092 10.3827 3.07613C10.009 2.92135 9.57889 3.00691 9.29289 3.29291L4.58579 8.00001H1C0.447715 8.00001 0 8.44773 0 9.00001V15C0 15.5523 0.447715 16 1 16H4.58579L9.29289 20.7071C9.57889 20.9931 10.009 21.0787 10.3827 20.9239C10.7564 20.7691 11 20.4045 11 20V4.00001ZM5.70711 9.70712L9 6.41423V17.5858L5.70711 14.2929L5.41421 14H5H2V10H5H5.41421L5.70711 9.70712ZM16.0001 12C16.0001 10.4087 15.368 8.8826 14.2428 7.75739L12.8285 9.1716C13.5787 9.92174 14.0001 10.9392 14.0001 12C14.0001 13.0609 13.5787 14.0783 12.8285 14.8285L14.2428 16.2427C15.368 15.1174 16.0001 13.5913 16.0001 12ZM17.0709 4.92896C18.9462 6.80432 19.9998 9.34786 19.9998 12C19.9998 14.6522 18.9462 17.1957 17.0709 19.0711L15.6567 17.6569C17.157 16.1566 17.9998 14.1218 17.9998 12C17.9998 9.87829 17.157 7.84346 15.6567 6.34317L17.0709 4.92896Z" fill="currentColor"></path>
                        </svg>
                    )}
                </button>

            </div>

            {/* Back Button - DESATIVADO TEMPORARIAMENTE 
            <div className="absolute top-20 left-4 sm:left-8 lg:left-12 z-20">
                <Link
                    href="/"
                    className="flex items-center gap-2 text-white/70 hover:text-white transition-colors"
                >
                    <ChevronLeft className="w-5 h-5" />
                    <span className="text-sm">Voltar</span>
                </Link>
            </div>
            FIM - Back Button */}


            {/* Hero Content - Bottom */}
            <motion.div
                className="absolute bottom-0 left-0 right-0 z-20 px-4 sm:px-8 lg:px-12 pb-0 sm:pb-2 lg:pb-4"
                initial={{ opacity: 0, y: 40 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, ease: 'easeOut' }}
            >
                <div className="max-w-4xl">

                    {/* Title - Otimizado */}
                    <motion.div
                        className="mb-2"
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.45, delay: 0.1, ease: 'easeOut' }}
                    >
                        <MovieTitle
                            title={movie.title}
                            logos={logos}
                            isLoading={isLoadingDetails && logos.length === 0}
                        />
                    </motion.div>

                    {/* BADGE TOP 10 DESATIVADO TEMPORARIAMENTE
                    {urlRank && (
                        <div className="flex items-center animate-in fade-in slide-in-from-left-4 duration-500 mb-4">
                            <svg width="245" height="30" viewBox="0 0 245 30" fill="none" aria-label={`#${urlRank} em ${movie.type === 'series' ? 'Séries' : 'Filmes'} hoje`}>
                                <rect y="1.0957" width="27.8086" height="27.8086" rx="3.47608" fill="#F50723"/>
                                <path d="M7.72649 13.7028H6.16834V8.3974H4.05576V7.04955H9.83908V8.3974H7.72649V13.7028Z" fill="white"/>
                                <path d="M13.27 13.8557C12.7729 13.8557 12.3141 13.7697 11.903 13.5976C11.4824 13.4255 11.1192 13.1866 10.8228 12.8711C10.5169 12.5557 10.278 12.1924 10.1155 11.7622C9.94339 11.3416 9.85736 10.8828 9.85736 10.3762C9.85736 9.86951 9.94339 9.41067 10.1155 8.98051C10.278 8.5599 10.5169 8.19665 10.8228 7.8812C11.1192 7.56574 11.4824 7.32676 11.903 7.1547C12.3141 6.98263 12.7729 6.8966 13.27 6.8966C13.7766 6.8966 14.2355 6.98263 14.6561 7.1547C15.0671 7.32676 15.4304 7.56574 15.7363 7.8812C16.0422 8.19665 16.2812 8.5599 16.4532 8.98051C16.6157 9.41067 16.7018 9.86951 16.7018 10.3762C16.7018 10.8828 16.6157 11.3416 16.4532 11.7622C16.2812 12.1924 16.0422 12.5557 15.7363 12.8711C15.4304 13.1866 15.0671 13.4255 14.6561 13.5976C14.2355 13.7697 13.7766 13.8557 13.27 13.8557ZM13.27 12.4792C13.6333 12.4792 13.9583 12.3931 14.2355 12.2115C14.5127 12.0395 14.723 11.7909 14.8855 11.4755C15.048 11.16 15.1245 10.7968 15.1245 10.3762C15.1245 9.95555 15.048 9.58274 14.8855 9.26728C14.723 8.95183 14.5127 8.71285 14.2355 8.53123C13.9583 8.35916 13.6333 8.27313 13.27 8.27313C12.9163 8.27313 12.6009 8.35916 12.3236 8.53123C12.0464 8.71285 11.8266 8.95183 11.6736 9.26728C11.5111 9.58274 11.4346 9.95555 11.4346 10.3762C11.4346 10.7968 11.5111 11.16 11.6736 11.4755C11.8266 11.7909 12.0464 12.0395 12.3236 12.2115C12.6009 12.3931 12.9163 12.4792 13.27 12.4792Z" fill="white"/>
                                <path d="M17.3002 13.7028V7.04955H20.0533C20.5982 7.04955 21.0761 7.14514 21.4681 7.33632C21.86 7.52751 22.1659 7.79517 22.3762 8.1393C22.5865 8.48343 22.6916 8.88492 22.6916 9.34376C22.6916 9.8026 22.5865 10.2041 22.3762 10.5482C22.1659 10.9019 21.86 11.1696 21.4681 11.3608C21.0761 11.5519 20.5982 11.6475 20.0533 11.6475H18.8584V13.7028H17.3002ZM18.8584 10.3284H19.8239C20.2732 10.3284 20.5982 10.2423 20.8085 10.0703C21.0092 9.90775 21.1144 9.65921 21.1144 9.34376C21.1144 9.0283 21.0092 8.78932 20.8085 8.61726C20.5982 8.45475 20.2732 8.36872 19.8239 8.36872H18.8584V10.3284Z" fill="white"/>
                                <text x="9" y="24" fill="white" fontSize="13" fontWeight="900" fontFamily="'Netflix Sans'">{urlRank}</text>
                                <text x="35" y="21" fill="white" fontSize="17" fontWeight="400" fontFamily="'Netflix Sans'">#{urlRank} em {movie.type === 'series' ? 'Séries' : 'Filmes'} hoje</text>
                            </svg>
                        </div>
                    )}
                    */}

                    {/* Tagline */}
                    {(isSeries ? seriesDetails?.tagline : movieDetails?.tagline) && (
                        <motion.p
                            className="text-gray-400 text-sm sm:text-base italic mt-2 mb-4"
                            initial={{ opacity: 0, y: 16 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ duration: 0.4, delay: 0.2, ease: 'easeOut' }}
                        >
                            "{(isSeries ? seriesDetails?.tagline : movieDetails?.tagline)}"
                        </motion.p>
                    )}

                    {!seriesDetails?.tagline && !movieDetails?.tagline && <div className="mb-4" />}

                    {/* Action Buttons - Netflix Style */}
                    <motion.div
                        className="flex flex-wrap items-center justify-between gap-2 mb-6"
                        role="group"
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.4, delay: 0.3, ease: 'easeOut' }}
                        aria-label="Ações do filme"
                    >
                        <div className="flex items-center gap-2">
                        <button
                            onClick={onWatch}
                            className="bg-white hover:bg-gray-200 text-black font-bold py-3 sm:py-2 md:py-3 px-8 md:px-10
                                rounded-sm transition-all duration-200 flex items-center justify-center text-base sm:text-base md:text-lg
                                focus:outline-none focus:ring-2 focus:ring-white focus:ring-offset-2 focus:ring-offset-black"
                            aria-label={
                                showContinue
                                    ? `Continuar ${movie.title} S${selectedSeason}:E${selectedEpisode}`
                                    : `Assistir ${movie.title}`
                            }
                        >
                            <Play className="w-6 h-6 sm:w-6 sm:h-6 mr-2 fill-current" aria-hidden="true" />
                            {showContinue
                                ? `Continua S${selectedSeason}:E${selectedEpisode}`
                                : 'Assistir'}
                        </button>
                        <div className="flex items-center gap-3">
                            <button
                                ref={listBtnRef}
                                onClick={onToggleList}
                                className={`bg-[#2a2a2a]/60 hover:bg-[#444444] border-2 border-[#ffffff]/70
                                    rounded-full transition-all duration-200 flex items-center justify-center w-12 h-12 sm:w-10 sm:h-10 md:w-12 md:h-12
                                    focus:outline-none focus:ring-0 text-white`}
                                aria-label={isInWatchlist ? 'Remover da lista' : 'Adicionar à minha lista'}
                                aria-busy={!listReady}
                            >
                                {!listReady ? (
                                    <ActionStatusSkeleton size={20} />
                                ) : isInWatchlist ? (
                                    <svg width="26" height="26" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                                        <path d="M5 13L9 17L19 7" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" fill="none" />
                                    </svg>
                                ) : (
                                    <svg width="26" height="26" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                                        <path fillRule="evenodd" clipRule="evenodd" d="M11 2V11H2V13H11V22H13V13H22V11H13V2H11Z" fill="currentColor" />
                                    </svg>
                                )}
                            </button>
                            <div className="relative">
                                <button
                                    ref={ratingBtnRef}
                                    onClick={handleLikeAction}
                                    className={`bg-[#2a2a2a]/60 hover:bg-[#444444] border-2 border-[#ffffff]/70
                                        rounded-full transition-all duration-200 flex items-center justify-center w-12 h-12 sm:w-10 sm:h-10 md:w-12 md:h-12
                                        focus:outline-none focus:ring-0 text-white`}
                                    aria-label={currentRating ? 'Alterar avaliação' : 'Avaliar este título'}
                                    aria-busy={!ratingReady}
                                >
                                    {!ratingReady ? (
                                        <ActionStatusSkeleton size={20} />
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
                                                handleRatingAction(Number(movie?.tmdb_id), movie?.type || 'movie', value);

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
                            {!showContinue && (
                            <button
                                onClick={() => setShowShareModal(true)}
                                className="hidden sm:flex bg-[#2a2a2a]/60 hover:bg-[#444444] border-2 border-[#ffffff]/70
                                    rounded-full transition-all duration-200 items-center justify-center w-12 h-12 sm:w-10 sm:h-10 md:w-12 md:h-12
                                    focus:outline-none focus:ring-0 text-white sm:ml-3 md:ml-4"
                                aria-label="Compartilhar"
                            >
                                <Share2 className="w-5 h-5" />
                            </button>
                            )}
                        </div>
                        </div>
                        {ratingParticlesPos && (
                            <RatingParticles
                                x={ratingParticlesPos.x}
                                y={ratingParticlesPos.y}
                                onComplete={clearRatingParticles}
                            />
                        )}
                        {listParticlesPos && (
                            <RatingParticles
                                x={listParticlesPos.x}
                                y={listParticlesPos.y}
                                onComplete={clearListParticles}
                            />
                        )}
                        {!showContinue && (
                        <button
                            onClick={() => setShowShareModal(true)}
                            className="sm:hidden bg-[#2a2a2a]/60 hover:bg-[#444444] border-2 border-[#ffffff]/70
                                rounded-full transition-all duration-200 flex items-center justify-center w-12 h-12 sm:w-10 sm:h-10 md:w-12 md:h-12
                                focus:outline-none focus:ring-0 text-white"
                            aria-label="Compartilhar"
                        >
                            <Share2 className="w-5 h-5" />
                        </button>
                        )}
                    </motion.div>


                    {/* Movie/Series Info */}
                    <div className="flex flex-wrap items-center gap-2 sm:gap-3 mt-1 text-base sm:text-base md:text-lg">
                        {watchMatch != null
                            ? <span className="text-[#46d369] font-bold text-base sm:text-base md:text-lg">{watchMatch}% Match</span>
                            : movie?.score != null
                            ? <span className="text-[#46d369] font-bold text-base sm:text-base md:text-lg">{Math.round(Number(movie.score) * 10)}% Match</span>
                            : null}
                        <span className="text-white font-bold text-base sm:text-base md:text-lg">{displayYear}</span>

                        {/* Age Rating Badge - Estilo Netflix */}
                        {(isSeries ? seriesDetails?.ageRating : movieDetails?.ageRating) && (() => {
                            const ratingStr = isSeries ? seriesDetails?.ageRating : movieDetails?.ageRating;
                            return (
                            <div
                                className="flex items-center justify-center rounded-[2px] min-w-[30px] sm:min-w-[32px] h-[30px] sm:h-[32px] px-1 shadow-sm overflow-hidden"
                                style={{ backgroundColor: getAgeRatingColor(ratingStr) }}
                            >
                                <span
                                    className="text-white block"
                                    style={{
                                        fontFamily: '"Netflix Sans"',
                                        fontSize: 'clamp(14px, 3.5vw, 16px)',
                                        fontWeight: 900,
                                        lineHeight: 'normal',
                                        letterSpacing: '-0.5px',
                                        transform: 'translateY(-1px)'
                                    }}
                                >
                                    {(isSeries ? (seriesDetails?.ageRating === '+18' ? '18' : seriesDetails?.ageRating) : (movieDetails?.ageRating === '+18' ? '18' : movieDetails?.ageRating))}
                                </span>
                            </div>
                            );
                        })()}

                        <span className="text-white font-bold text-base sm:text-base md:text-lg">{displayDuration}</span>
                        {(() => {
                            const genres = (isSeries ? seriesDetails?.genres : movieDetails?.genres) || movie.genre || [];
                            if (genres.length >= 2) {
                                return (
                                    <>
                                        <span className="w-1 h-1 rounded-full bg-gray-500" />
                                        <span className="text-gray-400 text-base sm:text-base md:text-lg">{genres[0]}</span>
                                        <span className="w-1 h-1 rounded-full bg-gray-500" />
                                        <span className="text-gray-400 text-base sm:text-base md:text-lg">{genres[1]}</span>
                                    </>
                                );
                            } else if (genres.length === 1) {
                                return (
                                    <>
                                        <span className="w-1 h-1 rounded-full bg-gray-500" />
                                        <span className="text-gray-400 text-base sm:text-base md:text-lg">{genres[0]}</span>
                                    </>
                                );
                            }
                            return null;
                        })()}

                    </div>

                </div>
            </motion.div>

        </section>
    );
});

export default WatchHero;