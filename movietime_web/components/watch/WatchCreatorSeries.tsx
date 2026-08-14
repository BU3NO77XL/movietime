'use client';

import { memo, useCallback, useEffect, useRef, useState } from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import { Movie } from '@/types/movie';

export const CREATOR_AUTO_PLAY_INTERVAL = 6000; // 6 segundos
const CREATOR_PAUSE_AFTER_INTERACTION = 120000; // 2 minutos

interface WatchCreatorSeriesProps {
    creatorSeries: Movie[];
    creatorInfo: { id: number; name: string };
    navigateToWatch: (movie: Movie) => void;
    movie: Movie;
    setLocalMovieOverride?: (movie: Movie | null) => void;
}

const WatchCreatorSeries = memo(function WatchCreatorSeries({
    creatorSeries,
    creatorInfo,
    navigateToWatch,
    movie,
    setLocalMovieOverride,
}: WatchCreatorSeriesProps) {
    const [showLeftCreatorArrow, setShowLeftCreatorArrow] = useState(false);
    const [showRightCreatorArrow, setShowRightCreatorArrow] = useState(false);
    const [activeCreatorBackdrop, setActiveCreatorBackdrop] = useState(0);
    const [selectedCreatorIndex, setSelectedCreatorIndex] = useState(0);
    const [isCreatorPaused, setIsCreatorPaused] = useState(false);
    const creatorScrollRef = useRef<HTMLDivElement>(null);
    const creatorPauseTimeoutRef = useRef<NodeJS.Timeout | null>(null);

    const handleCreatorScroll = useCallback(() => {
        if (creatorScrollRef.current) {
            const { scrollLeft, scrollWidth, clientWidth } = creatorScrollRef.current;
            const hasOverflow = scrollWidth > clientWidth;
            setShowLeftCreatorArrow(hasOverflow && scrollLeft > 10);
            setShowRightCreatorArrow(hasOverflow && scrollLeft < scrollWidth - clientWidth - 10);

            // Calcular qual item está mais visível para mudar o backdrop
            const itemWidth = 160; // Largura aproximada de cada card + gap
            const activeIndex = Math.round(scrollLeft / itemWidth);
            setActiveCreatorBackdrop(Math.min(activeIndex, creatorSeries.length - 1));
        }
    }, [creatorSeries.length]);

    const scrollCreator = useCallback((direction: 'left' | 'right') => {
        if (creatorScrollRef.current) {
            creatorScrollRef.current.scrollBy({
                left: direction === 'left' ? -300 : 300,
                behavior: 'smooth'
            });
            setTimeout(() => handleCreatorScroll(), 300);
        }
    }, [handleCreatorScroll]);

    const handleCreatorUserInteraction = useCallback((index: number) => {
        if (creatorPauseTimeoutRef.current) {
            clearTimeout(creatorPauseTimeoutRef.current);
        }

        setIsCreatorPaused(true);
        setSelectedCreatorIndex(index);
        setActiveCreatorBackdrop(index);

        // Scroll para o item selecionado
        if (creatorScrollRef.current) {
            const container = creatorScrollRef.current;
            const child = container.children[index] as HTMLElement;
            if (child) {
                const containerRect = container.getBoundingClientRect();
                const childRect = child.getBoundingClientRect();
                const scrollLeft = child.offsetLeft - container.offsetLeft - (containerRect.width / 2) + (childRect.width / 2);
                container.scrollTo({
                    left: scrollLeft,
                    behavior: 'smooth'
                });
            }
        }

        // Retomar autoplay após 2 minutos
        creatorPauseTimeoutRef.current = setTimeout(() => {
            setIsCreatorPaused(false);
        }, CREATOR_PAUSE_AFTER_INTERACTION);
    }, []);

    // Autoplay para o carrossel de criadores
    useEffect(() => {
        if (isCreatorPaused || creatorSeries.length <= 1) return;

        const interval = setInterval(() => {
            if (document.hidden) return;
            setSelectedCreatorIndex((prev: number) => {
                const nextIndex = (prev + 1) % creatorSeries.length;
                setActiveCreatorBackdrop(nextIndex);

                if (creatorScrollRef.current) {
                    const container = creatorScrollRef.current;
                    const child = container.children[nextIndex] as HTMLElement;
                    if (child) {
                        const containerRect = container.getBoundingClientRect();
                        const childRect = child.getBoundingClientRect();
                        const scrollLeft = child.offsetLeft - container.offsetLeft - (containerRect.width / 2) + (childRect.width / 2);
                        container.scrollTo({
                            left: scrollLeft,
                            behavior: 'smooth'
                        });
                    }
                }

                return nextIndex;
            });
        }, CREATOR_AUTO_PLAY_INTERVAL);

        return () => clearInterval(interval);
    }, [isCreatorPaused, creatorSeries.length]);

    // Limpar timeout ao desmontar
    useEffect(() => {
        return () => {
            if (creatorPauseTimeoutRef.current) {
                clearTimeout(creatorPauseTimeoutRef.current);
            }
        };
    }, []);

    // Verificar overflow inicial
    useEffect(() => {
        setActiveCreatorBackdrop(0);
        setSelectedCreatorIndex(0);
        setIsCreatorPaused(false);
        setShowLeftCreatorArrow(false);
        setShowRightCreatorArrow(false);
        if (creatorScrollRef.current) {
            creatorScrollRef.current.scrollLeft = 0;
        }
        const checkOverflow = () => handleCreatorScroll();
        const timer = setTimeout(checkOverflow, 100);
        window.addEventListener('resize', checkOverflow);
        return () => {
            clearTimeout(timer);
            window.removeEventListener('resize', checkOverflow);
        };
    }, [creatorSeries, handleCreatorScroll]);

    const handleSeriesClick = useCallback((series: Movie) => {
        if (series && Object.keys(series).length > 0) {
            setLocalMovieOverride?.(series);
            navigateToWatch(series);
        }
    }, [navigateToWatch, setLocalMovieOverride]);

    if (creatorSeries.length === 0) {
        return null;
    }

    return (
        <section className="py-8">

            <div className="relative rounded-3xl overflow-hidden border border-white/10 shadow-[0_20px_50px_rgba(0,0,0,0.5)]">
                {/* Backdrop Dinâmico com transição suave e efeito de blur - usando mesma abordagem do Hero */}
                <div className="absolute inset-0">
                    {creatorSeries.map((series, index) => (
                        <div
                            key={`creator-backdrop-${index}-${movie.tmdb_id}`}
                            className={`absolute inset-0 w-full h-full transition-all duration-2000 ease-out ${index === activeCreatorBackdrop
                                ? 'opacity-100 scale-100 blur-[3px]'
                                : 'opacity-0 scale-105 blur-lg'
                                }`}
                        >
                            <img
                                src={(series.backdrop_url && series.backdrop_url !== '')
                                    ? series.backdrop_url
                                    : 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1920&h=1080&fit=crop'}
                                alt=""
                                className="w-full h-full object-cover"
                                onError={(e) => {
                                    // Garantir fallback para não ter fundo vazio
                                    const target = e.target as HTMLImageElement;
                                    target.src = 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1920&h=1080&fit=crop';
                                }}
                            />
                        </div>
                    ))}
                    <div className="absolute inset-0 bg-black/50" />
                    <div className="absolute inset-0 bg-linear-to-r from-[#0a0a0a]/90 via-transparent to-transparent" />
                    <div className="absolute inset-0 bg-linear-to-t from-[#0a0a0a]/80 via-transparent to-transparent" />
                    {/* Brilho do Modal */}
                    <div className="absolute inset-0" style={{ background: 'radial-gradient(circle at 50% 0%, rgba(255, 255, 255, 0.06), transparent 50%)' }} />
                </div>

                <div className="relative z-10 p-4 sm:p-5">
                    <h2 className="text-white text-lg md:text-xl font-semibold mb-1">Mais de {creatorInfo.name}</h2>
                    <p className="text-gray-400 text-sm mb-4">
                        Outras séries do mesmo criador de {movie.title}
                    </p>
                    <div className="relative group/creator">
                        {/* Left Arrow */}
                        {showLeftCreatorArrow && (
                            <button
                                onClick={() => scrollCreator('left')}
                                className="absolute left-0 top-1/2 -translate-y-1/2 z-20 p-2 rounded-lg bg-white/10 hover:bg-[#1DB954] transition-all duration-200 backdrop-blur-sm"
                            >
                                <ChevronLeft className="w-5 h-5 lg:w-6 lg:h-6 text-white" />
                            </button>
                        )}
                        {/* Right Arrow */}
                        {showRightCreatorArrow && (
                            <button
                                onClick={() => scrollCreator('right')}
                                className="absolute right-0 top-1/2 -translate-y-1/2 z-20 p-2 rounded-lg bg-white/10 hover:bg-[#1DB954] transition-all duration-200 backdrop-blur-sm"
                            >
                                <ChevronRight className="w-5 h-5 lg:w-6 lg:h-6 text-white" />
                            </button>
                        )}
                        <div
                            ref={creatorScrollRef}
                            onScroll={handleCreatorScroll}
                            className="flex gap-4 overflow-x-auto py-3 px-1 -mx-1 scrollbar-hide"
                        >

                            {creatorSeries.map((series, index) => (
                                <div
                                    key={series.id}
                                    onClick={() => {
                                        handleCreatorUserInteraction(index);
                                        handleSeriesClick(series);
                                    }}
                                    className="shrink-0 group cursor-pointer hover:scale-103 hover:-translate-y-1 transition-all duration-200"
                                >

                                    <div
                                        className={`relative w-28 sm:w-32 lg:w-36 aspect-2/3 rounded-lg overflow-hidden bg-[#1f1f1f] transition-all duration-300
                                            ${index === selectedCreatorIndex ? 'ring-2 ring-[#46d369] ring-offset-2 ring-offset-transparent' : 'hover:ring-1 hover:ring-white/30'}`}
                                        role="button"
                                        tabIndex={0}
                                        aria-label={`Assistir ${series.title}`}
                                        onKeyDown={(e) => {
                                            if (e.key === 'Enter' || e.key === ' ') {
                                                handleCreatorUserInteraction(index);
                                                handleSeriesClick(series);
                                            }
                                        }}
                                    >
                                        {series.poster_url && series.poster_url !== '' ? (
                                            <img
                                                src={series.poster_url}
                                                alt=""
                                                loading="lazy"
                                                className={`w-full h-full object-cover transition-all duration-300
                                                    ${index === selectedCreatorIndex ? 'opacity-100' : 'opacity-80 group-hover:opacity-100'}`}
                                            />
                                        ) : (
                                            <div className="w-full h-full flex items-center justify-center bg-linear-to-br from-[#2a2a2a] to-[#1f1f1f] text-gray-400 text-xs p-3 text-center font-medium">
                                                {series.title}
                                            </div>
                                        )}

                                        {/* Barra de progresso - igual ao CastSlider */}
                                        {!isCreatorPaused && creatorSeries.length > 1 && index === selectedCreatorIndex && (
                                            <div className="absolute bottom-0 left-0 right-0 h-1 bg-black/60">
                                                <div
                                                    key={`progress-${selectedCreatorIndex}`}
                                                    className="h-full bg-[#46d369]"
                                                    style={{
                                                        width: '0%',
                                                        animation: `creatorProgress ${CREATOR_AUTO_PLAY_INTERVAL / 1000}s linear forwards`
                                                    }}
                                                />
                                            </div>
                                        )}

                                    </div>
                                    <p className={`text-xs mt-2 truncate w-28 sm:w-32 lg:w-36 transition-colors text-center
                                        ${index === selectedCreatorIndex ? 'text-white font-medium' : 'text-gray-400 group-hover:text-white'}`}>
                                        {series.title}
                                    </p>
                                    {series.year && (
                                        <p className="text-gray-400 text-[11px] mt-1 text-center">
                                            {series.year}
                                        </p>
                                    )}
                                </div>

                            ))}
                        </div>

                    </div>
                </div>
            </div>
        </section>
    );
});

export default WatchCreatorSeries;
