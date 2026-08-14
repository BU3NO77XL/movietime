'use client';

import { useState, useEffect, type ReactNode } from 'react';
import { Play, Info } from 'lucide-react';
import { motion, AnimatePresence, Variants } from 'framer-motion';
import ProgressiveImage from './ProgressiveImage';
import TrailerBackdrop from './TrailerBackdrop';
import { HeroSkeleton } from '@/components/ui/Skeleton';
import { Movie } from '@/types/movie';
import { TMDBService } from './TMDBIntegration';
import { getOfficialTrailer } from '@/lib/trailerCache';
import { cn, toTmdbOriginalUrl } from '@/lib/utils';

function heroBackdropUrl(movie: Movie): string | null {
  // Sempre original (máxima qualidade) no billboard
  return toTmdbOriginalUrl(movie.backdrop_url || movie.poster_url);
}

interface HeroSectionProps {
    featuredMovies: Movie[];
    onWatch: (movie: Movie) => void;
    onMoreInfo: (movie: Movie) => void;
    top10Ranks?: Record<number, number>;
    /** Primeiro carrossel renderizado logo abaixo dos botões (fluxo no hero) */
    children?: ReactNode;
}

export default function HeroSection({ featuredMovies, onWatch, onMoreInfo, top10Ranks, children }: HeroSectionProps) {
    const [currentIndex, setCurrentIndex] = useState(-1);
    
    const [logosCache, setLogosCache] = useState<Record<string, string | null>>({});
    const [trailerKey, setTrailerKey] = useState<string | null>(null);
    const [trailerPlaying, setTrailerPlaying] = useState(false);
    
    const [displayContent, setDisplayContent] = useState<{
        movie: Movie;
        logo: string | null;
        isReady: boolean;
    } | null>(null);

    // Snapshot do featuredMovies na primeira vez que tiver dados — estabiliza o hero
    const [snapshot, setSnapshot] = useState<Movie[] | null>(null);
    useEffect(() => {
        if (featuredMovies?.length && !snapshot) {
            setSnapshot(featuredMovies);
            setCurrentIndex(Math.floor(Math.random() * featuredMovies.length));
        }
    }, [featuredMovies]);

    const heroMovies = snapshot || featuredMovies;

    // 1. Prefetch logos/backdrops (roda uma vez, quando o snapshot estabiliza)
    useEffect(() => {
        const prefetchAssets = async () => {
            if (!heroMovies?.length) return;

            const entries = await Promise.all(
                heroMovies.map(async (movie) => {
                    const cacheKey = String(movie.tmdb_id || movie.id);
                    try {
                        const logos = await TMDBService.fetchMovieLogos(
                            Number(movie.tmdb_id || movie.id),
                            movie.type === 'series'
                        );
                        const logoUrl = logos.length > 0
                            ? `https://image.tmdb.org/t/p/original${logos[0].file_path}`
                            : null;
                        return [cacheKey, logoUrl] as const;
                    } catch {
                        return [cacheKey, null] as const;
                    }
                })
            );

            setLogosCache((prev) => {
                const next = { ...prev };
                for (const [key, url] of entries) {
                    if (next[key] === undefined) next[key] = url;
                }
                return next;
            });

            // Preload de backdrops em memória (sem setState por imagem)
            heroMovies.forEach((movie) => {
                const url = heroBackdropUrl(movie);
                if (url) {
                    const img = new Image();
                    img.src = url;
                }
            });
        };

        prefetchAssets();
    }, [heroMovies]);

    // 2. Exibe o primeiro filme assim que o snapshot estiver pronto
    useEffect(() => {
        if (!heroMovies?.length) return;
        const movie = heroMovies[currentIndex];
        if (!movie) return;
        const cacheKey = String(movie.tmdb_id || movie.id);
        setDisplayContent({
            movie,
            logo: logosCache[cacheKey] || null,
            isReady: true
        });
    }, [heroMovies, currentIndex, logosCache]);

    // 3. Trailer oficial HD no backdrop (TMDB)
    useEffect(() => {
        if (!heroMovies?.length || currentIndex < 0) return;
        const movie = heroMovies[currentIndex];
        if (!movie) return;

        const tmdbId = Number(movie.tmdb_id || movie.id);
        if (!tmdbId) {
            setTrailerKey(null);
            setTrailerPlaying(false);
            return;
        }

        let cancelled = false;
        setTrailerKey(null);
        setTrailerPlaying(false);

        getOfficialTrailer(tmdbId, movie.type === 'series').then((trailer) => {
            if (cancelled) return;
            setTrailerKey(trailer?.key ?? null);
        });

        const next = heroMovies[(currentIndex + 1) % heroMovies.length];
        if (next?.tmdb_id || next?.id) {
            getOfficialTrailer(Number(next.tmdb_id || next.id), next.type === 'series').catch(() => {});
        }

        return () => {
            cancelled = true;
        };
    }, [heroMovies, currentIndex]);

    // 5. Auto-rotation a cada 2 minutos
    useEffect(() => {
        if (heroMovies?.length <= 1) return;

        const interval = setInterval(() => {
            setCurrentIndex((prev) => (prev + 1) % heroMovies.length);
        }, 120000);

        return () => clearInterval(interval);
    }, [heroMovies?.length]);

    if (!displayContent) return <HeroSkeleton />;

    const { movie, logo } = displayContent;
    const currentImageUrl = heroBackdropUrl(movie);
    const rank = movie.tmdb_id != null ? top10Ranks?.[movie.tmdb_id] : undefined;

    // Optimized Animation Variants
    const backdropVariants: Variants = {
        enter: (dir: number) => ({
            opacity: 0,
            scale: 1.05,
        }),
        center: {
            opacity: 1,
            scale: 1,
            transition: {
                duration: 1.2,
                ease: [0.33, 1, 0.68, 1], // Smooth ease-out
            }
        },
        exit: {
            opacity: 0,
            transition: {
                duration: 1.2,
                ease: [0.33, 1, 0.68, 1],
            }
        }
    };

    const contentVariants: Variants = {
        enter: { opacity: 0, y: 10 },
        center: {
            opacity: 1,
            y: 0,
            transition: {
                staggerChildren: 0.1,
                delayChildren: 0.2,
                duration: 0.6,
                ease: "easeOut"
            }
        },
        exit: { 
            opacity: 0, 
            y: -5,
            transition: { duration: 0.4, ease: "easeIn" } 
        }
    };

    const itemVariants: Variants = {
        enter: { opacity: 0, y: 10 },
        center: { opacity: 1, y: 0, transition: { duration: 0.5 } },
    };

    return (
        // Billboard + 1º carrossel sobreposto (padrão Netflix).
        // O overflow fica só no billboard; o carrossel sobe com margin negativo sem ser cortado.
        <section className="relative w-full bg-[#0a0a0a]">
            {/* Billboard — min-height garante espaço para navbar (72px) + info + faixa do carrossel */}
            <div className="relative w-full h-[62svh] min-h-[500px] max-h-[580px] sm:h-[68vh] sm:min-h-[560px] sm:max-h-[700px] md:h-[80vh] md:min-h-[620px] md:max-h-[810px] overflow-hidden">
                {/* Background Layer — imagem + trailer oficial HD (TMDB/YouTube) */}
                <AnimatePresence initial={false} mode="popLayout">
                    <motion.div
                        key={`bg-${movie.id}`}
                        variants={backdropVariants}
                        initial="enter"
                        animate="center"
                        exit="exit"
                        className="absolute inset-0"
                    >
                        <ProgressiveImage
                            src={currentImageUrl || null}
                            alt={movie.title}
                            className={cn(
                                'absolute inset-0 w-full h-full object-cover object-top transition-opacity duration-700',
                                trailerPlaying ? 'opacity-0' : 'opacity-100'
                            )}
                            preloaded={false}
                        />
                        <TrailerBackdrop
                            youtubeKey={trailerKey}
                            muted
                            loop
                            startDelayMs={800}
                            revealDelayMs={4000}
                            className="z-[1]"
                            onPlayingChange={setTrailerPlaying}
                        />
                    </motion.div>
                </AnimatePresence>

                {/* Premium Overlays */}
                <div
                    className="absolute inset-0 z-10 pointer-events-none"
                    style={{
                        background: 'linear-gradient(180deg, rgba(0, 0, 0, 0.38) 0%, rgba(0, 0, 0, 0.08) 30%, rgba(0, 0, 0, 0.42) 78%, rgba(0, 0, 0, 0.92) 100%)'
                    }}
                />
                <div
                    className="absolute inset-0 z-10 pointer-events-none"
                    style={{
                        background: 'linear-gradient(90deg, rgba(0, 0, 0, 0.76) 0%, rgba(0, 0, 0, 0.36) 21%, rgba(0, 0, 0, 0) 44%), linear-gradient(180deg, rgba(0, 0, 0, 0.55) 0%, rgba(0, 0, 0, 0) 18%)'
                    }}
                />

                {/* Bottom fade para o carrossel */}
                <div
                    className="absolute bottom-0 left-0 right-0 h-[45%] z-10 pointer-events-none"
                    style={{
                        background: 'linear-gradient(180deg, rgba(10, 10, 10, 0) 0%, rgba(10, 10, 10, 0.35) 40%, rgba(10, 10, 10, 0.85) 75%, rgba(10, 10, 10, 1) 100%)'
                    }}
                />

                {/*
                  Zona segura do conteúdo:
                  - top ≥ navbar fixa (72px) + respiro
                  - bottom reserva a faixa do 1º carrossel
                  justify-end ancora logo/botões embaixo sem invadir a navbar
                  Badge de idade fica SEMPRE entre botões e o 1º carrossel
                */}
                <div className="absolute inset-x-0 top-[80px] sm:top-[88px] md:top-[96px] bottom-[72px] sm:bottom-[80px] md:bottom-[96px] z-20 pointer-events-none flex flex-col justify-end overflow-hidden">
                    <AnimatePresence mode="popLayout">
                        <motion.div
                            key={`content-${movie.id}`}
                            variants={contentVariants}
                            initial="enter"
                            animate="center"
                            exit="exit"
                            className="w-full flex flex-col min-h-0"
                        >
                            {/* Bloco esquerdo: logo, Top 10, sinopse, botões */}
                            <div className="px-4 md:px-[38px] max-w-[518px] flex flex-col gap-2.5 sm:gap-3 md:gap-4 pointer-events-auto">
                                {/* Logo/Title */}
                                <motion.div variants={itemVariants} className="flex items-end shrink-0">
                                    {logo ? (
                                        <img
                                            src={logo}
                                            alt={movie.title}
                                            className="w-[70%] max-w-[260px] sm:max-w-[340px] md:w-auto md:max-w-[440px] max-h-[56px] sm:max-h-[84px] md:max-h-[130px] object-contain object-left"
                                        />
                                    ) : (
                                        <h1 className="text-white font-black text-2xl sm:text-3xl md:text-5xl leading-tight tracking-tighter uppercase drop-shadow-lg">
                                            {movie.title}
                                        </h1>
                                    )}
                                </motion.div>

                                {rank && (
                                    <motion.div variants={itemVariants} className="flex items-center shrink-0">
                                        <svg viewBox="0 0 245 30" fill="none" className="w-[140px] md:w-[220px] h-auto" aria-label={`Top ${rank} em ${movie.type === 'series' ? 'Séries' : 'Filmes'} hoje`}>
                                            <rect y="1.0957" width="27.8086" height="27.8086" rx="3.47608" fill="#F50723"/>
                                            <path d="M7.72649 13.7028H6.16834V8.3974H4.05576V7.04955H9.83908V8.3974H7.72649V13.7028Z" fill="white"/>
                                            <path d="M13.27 13.8557C12.7729 13.8557 12.3141 13.7697 11.903 13.5976C11.4824 13.4255 11.1192 13.1866 10.8228 12.8711C10.5169 12.5557 10.278 12.1924 10.1155 11.7622C9.94339 11.3416 9.85736 10.8828 9.85736 10.3762C9.85736 9.86951 9.94339 9.41067 10.1155 8.98051C10.278 8.5599 10.5169 8.19665 10.8228 7.8812C11.1192 7.56574 11.4824 7.32676 11.903 7.1547C12.3141 6.98263 12.7729 6.8966 13.27 6.8966C13.7766 6.8966 14.2355 6.98263 14.6561 7.1547C15.0671 7.32676 15.4304 7.56574 15.7363 7.8812C16.0422 8.19665 16.2812 8.5599 16.4532 8.98051C16.6157 9.41067 16.7018 9.86951 16.7018 10.3762C16.7018 10.8828 16.6157 11.3416 16.4532 11.7622C16.2812 12.1924 16.0422 12.5557 15.7363 12.8711C15.4304 13.1866 15.0671 13.4255 14.6561 13.5976C14.2355 13.7697 13.7766 13.8557 13.27 13.8557ZM13.27 12.4792C13.6333 12.4792 13.9583 12.3931 14.2355 12.2115C14.5127 12.0395 14.723 11.7909 14.8855 11.4755C15.048 11.16 15.1245 10.7968 15.1245 10.3762C15.1245 9.95555 15.048 9.58274 14.8855 9.26728C14.723 8.95183 14.5127 8.71285 14.2355 8.53123C13.9583 8.35916 13.6333 8.27313 13.27 8.27313C12.9163 8.27313 12.6009 8.35916 12.3236 8.53123C12.0464 8.71285 11.8266 8.95183 11.6736 9.26728C11.5111 9.58274 11.4346 9.95555 11.4346 10.3762C11.4346 10.7968 11.5111 11.16 11.6736 11.4755C11.8266 11.7909 12.0464 12.0395 12.3236 12.2115C12.6009 12.3931 12.9163 12.4792 13.27 12.4792Z" fill="white"/>
                                            <path d="M17.3002 13.7028V7.04955H20.0533C20.5982 7.04955 21.0761 7.14514 21.4681 7.33632C21.86 7.52751 22.1659 7.79517 22.3762 8.1393C22.5865 8.48343 22.6916 8.88492 22.6916 9.34376C22.6916 9.8026 22.5865 10.2041 22.3762 10.5482C22.1659 10.9019 21.86 11.1696 21.4681 11.3608C21.0761 11.5519 20.5982 11.6475 20.0533 11.6475H18.8584V13.7028H17.3002ZM18.8584 10.3284H19.8239C20.2732 10.3284 20.5982 10.2423 20.8085 10.0703C21.0092 9.90775 21.1144 9.65921 21.1144 9.34376C21.1144 9.0283 21.0092 8.78932 20.8085 8.61726C20.5982 8.45475 20.2732 8.36872 19.8239 8.36872H18.8584V10.3284Z" fill="white"/>
                                            <text x="9" y="24" fill="white" fontSize="13" fontWeight="900" fontFamily="'Netflix Sans'">{rank}</text>
                                            <text x="35" y="21" fill="white" fontSize="17" fontWeight="700" fontFamily="'Netflix Sans'">Top {rank} em {movie.type === 'series' ? 'Séries' : 'Filmes'} hoje</text>
                                        </svg>
                                    </motion.div>
                                )}

                                {/* Synopsis — escondida no mobile; no máximo 3 linhas no desktop */}
                                <motion.p
                                    variants={itemVariants}
                                    className="hidden sm:block text-white text-[15px] md:text-[17px] leading-[1.35] drop-shadow-[0_1px_2px_rgba(0,0,0,0.45)] max-w-[518px] line-clamp-2 md:line-clamp-3"
                                >
                                    {movie.synopsis}
                                </motion.p>

                                {/* Buttons */}
                                <motion.div variants={itemVariants} className="flex items-center gap-2 md:gap-[16px] shrink-0">
                                    <button
                                        onClick={() => onWatch(movie)}
                                        className="bg-white hover:bg-gray-200 text-black flex items-center justify-center gap-1 md:gap-2 px-4 sm:px-5 md:px-[32px] h-[42px] sm:h-[48px] md:h-[52px] rounded-[2px] transition-colors"
                                    >
                                        <Play className="w-5 h-5 md:w-7 md:h-7 fill-black" />
                                        <span className="text-[15px] sm:text-[18px] md:text-[20px] font-bold">Assistir</span>
                                    </button>
                                    <button
                                        onClick={() => onMoreInfo(movie)}
                                        className="bg-[#6D6D6E]/70 hover:bg-[#6D6D6E]/80 text-white flex items-center justify-center gap-1 md:gap-2 px-4 sm:px-5 md:px-[32px] h-[42px] sm:h-[48px] md:h-[52px] rounded-[2px] transition-colors backdrop-blur-md shrink-0 whitespace-nowrap"
                                    >
                                        <Info className="w-5 h-5 md:w-7 md:h-7 shrink-0" />
                                        <span className="text-[14px] sm:text-[18px] md:text-[20px] font-bold whitespace-nowrap">Mais Informações</span>
                                    </button>
                                </motion.div>
                            </div>

                            {/*
                              Badge de idade + ícone de áudio:
                              sempre logo ABAIXO dos botões e ACIMA do 1º carrossel
                              (mobile e desktop)
                            */}
                            <motion.div
                                variants={itemVariants}
                                className="mt-3 sm:mt-4 md:mt-5 flex justify-end items-center h-[35px] shrink-0"
                                aria-label={`Classificação: ${movie.rating || '14+'}`}
                            >
                                <div className="relative w-[35px] h-[35px] mr-[8px] z-10">
                                    <svg viewBox="0 0 35 35" fill="none" xmlns="http://www.w3.org/2000/svg" className="w-full h-full">
                                        <circle cx="17.5" cy="17.5" r="17" stroke="white" strokeOpacity="0.7"/>
                                        <path d="M21.7507 12.1205C21.9559 12.2231 22.0585 12.4284 22.2638 12.531C22.3664 12.6336 22.3664 12.6336 22.469 12.7362L20.6219 13.0441C20.1088 13.1467 19.6984 13.6598 19.801 14.2755C19.9036 14.7886 20.3141 15.0964 20.8271 15.0964C20.9298 15.0964 20.9298 15.0964 21.0324 15.0964L25.3423 14.2755C25.8554 14.1729 26.2659 13.6598 26.1632 13.0441L25.3423 8.83677C25.2397 8.32368 24.7266 7.91321 24.1109 8.01583C23.5978 8.11845 23.1873 8.63153 23.29 9.24724L23.5978 10.9917C23.3926 10.7865 23.0847 10.4786 22.8795 10.376C22.8795 10.376 22.8795 10.376 22.7769 10.376C22.6743 10.2734 22.5716 10.1708 22.469 10.1708C22.2638 9.96556 22.0585 9.86294 21.7507 9.6577C21.4428 9.45247 21.135 9.34985 20.8271 9.14462H20.7245C20.6219 9.042 20.4167 9.042 20.2114 8.93938C19.801 8.83677 19.3905 8.73415 19.0827 8.63153C18.8774 8.63153 18.6722 8.52892 18.4669 8.52892H18.3643C18.2617 8.52892 18.0565 8.52892 17.9539 8.52892C17.7486 8.52892 17.4408 8.52892 17.2355 8.52892C12.1047 8.52892 8 12.6336 8 17.7645C8 22.8953 12.1047 27 17.2355 27C22.3664 27 26.4711 22.8953 26.4711 17.7645C26.4711 17.1488 26.0606 16.7383 25.4449 16.7383C24.8292 16.7383 24.4187 17.1488 24.4187 17.7645C24.4187 21.7665 21.2376 24.9477 17.2355 24.9477C13.2335 24.9477 10.0523 21.7665 10.0523 17.7645C10.0523 13.7624 13.2335 10.5813 17.2355 10.5813C17.4408 10.5813 17.7486 10.5813 17.9539 10.5813C18.1591 10.5813 18.2617 10.5813 18.4669 10.6839C18.6722 10.6839 18.7748 10.7865 18.98 10.7865C19.0827 10.7865 19.1853 10.8891 19.2879 10.8891C20.0062 11.0943 20.7245 11.4022 21.3402 11.9153C21.4428 12.0179 21.5455 12.0179 21.6481 12.1205C21.6481 11.9153 21.7507 12.0179 21.7507 12.1205Z" fill="white"/>
                                    </svg>
                                </div>
                                <div className="flex items-center bg-[#333333]/60 border-l-[3px] border-[#DCDCDC] h-[35px] pl-[12px] pr-[16px] sm:pr-[24px] md:pr-[58px]">
                                    <span className="text-white text-[16px] sm:text-[18px] font-medium tracking-wider whitespace-nowrap">
                                        {movie.rating || '14+'}
                                    </span>
                                </div>
                            </motion.div>
                        </motion.div>
                    </AnimatePresence>
                </div>
            </div>

            {/* 1º carrossel — sempre abaixo dos botões e do badge de idade */}
            {children && (
                <div
                    className="relative z-30"
                    style={{ marginTop: 'clamp(-72px, -12vw, -48px)' }}
                >
                    {children}
                </div>
            )}
        </section>
    );
}
