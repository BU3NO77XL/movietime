'use client';

import { memo, useCallback, useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useQueryClient } from '@tanstack/react-query';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import { Movie } from '@/types/movie';

interface CollectionPart {
    id: number;
    title: string;
    poster_path: string;
    release_date: string;
}

interface Collection {
    id: number;
    name: string;
    overview: string;
    backdrop_path: string;
    parts: CollectionPart[];
}

interface WatchCollectionProps {
    collection: Collection;
    movie: Movie;
    setLocalMovieOverride: (movie: Movie | null) => void;
    setLocalOverride: (override: {
        tmdbId: string;
        mediaType: string;
        title: string;
        poster_url: string;
        backdrop_url: string;
        year: number;
    } | null) => void;
    navigateToWatch: (movie: Movie) => void;
}

const WatchCollection = memo(function WatchCollection({
    collection,
    movie,
    setLocalMovieOverride,
    setLocalOverride,
}: WatchCollectionProps) {
    const router = useRouter();
    const queryClient = useQueryClient();
    const [showLeftCollectionArrow, setShowLeftCollectionArrow] = useState(false);
    const [showRightCollectionArrow, setShowRightCollectionArrow] = useState(false);
    const collectionScrollRef = useRef<HTMLDivElement>(null);

    const handleCollectionScroll = useCallback(() => {
        if (collectionScrollRef.current) {
            const { scrollLeft, scrollWidth, clientWidth } = collectionScrollRef.current;
            const hasOverflow = scrollWidth > clientWidth;
            setShowLeftCollectionArrow(hasOverflow && scrollLeft > 10);
            setShowRightCollectionArrow(hasOverflow && scrollLeft < scrollWidth - clientWidth - 10);
        }
    }, []);

    const scrollCollection = useCallback((direction: 'left' | 'right') => {
        if (collectionScrollRef.current) {
            collectionScrollRef.current.scrollBy({
                left: direction === 'left' ? -300 : 300,
                behavior: 'smooth'
            });
            setTimeout(() => handleCollectionScroll(), 300);
        }
    }, [handleCollectionScroll]);

    useEffect(() => {
        const checkOverflow = () => handleCollectionScroll();
        const timer = setTimeout(checkOverflow, 100);
        window.addEventListener('resize', checkOverflow);
        return () => {
            clearTimeout(timer);
            window.removeEventListener('resize', checkOverflow);
        };
    }, [collection, handleCollectionScroll]);

    if (collection.parts.length <= 1) {
        return null;
    }

    return (
        <section className="py-8">

            <div className="relative rounded-3xl overflow-hidden border border-white/10 shadow-[0_20px_50px_rgba(0,0,0,0.5)]">
                {/* Backdrop */}
                {collection.backdrop_path && (
                    <div className="absolute inset-0">
                        <img
                            src={`https://image.tmdb.org/t/p/w1280${collection.backdrop_path}` || movie.backdrop_url || movie.poster_url}
                            alt={collection.name}
                            className="w-full h-full object-cover blur-[3px] scale-105"
                        />
                        <div className="absolute inset-0 bg-black/50" />
                        <div className="absolute inset-0 bg-linear-to-r from-[#0a0a0a]/90 via-transparent to-transparent" />
                        <div className="absolute inset-0 bg-linear-to-t from-[#0a0a0a]/80 via-transparent to-transparent" />
                        {/* Brilho do Modal */}
                        <div className="absolute inset-0" style={{ background: 'radial-gradient(circle at 50% 0%, rgba(255, 255, 255, 0.06), transparent 50%)' }} />
                    </div>
                )}

                <div className={`relative z-10 p-4 sm:p-5 ${!collection.backdrop_path ? 'bg-[#1f1f1f]' : ''}`}>
            <h2 className="text-white text-lg md:text-xl font-semibold mb-1">{collection.name}</h2>
            <p className="text-gray-400 text-sm mb-4">
                        Parte de uma coleção com {collection.parts.length} títulos
                    </p>
                    <div className="relative group/collection">
                        {/* Left Arrow */}
                        {showLeftCollectionArrow && (
                            <button
                                onClick={() => scrollCollection('left')}
                                className="absolute left-0 top-1/2 -translate-y-1/2 z-20 p-2 rounded-lg bg-white/10 hover:bg-[#1DB954] transition-all duration-200 backdrop-blur-sm"
                            >
                                <ChevronLeft className="w-5 h-5 lg:w-6 lg:h-6 text-white" />
                            </button>
                        )}
                        {/* Right Arrow */}
                        {showRightCollectionArrow && (
                            <button
                                onClick={() => scrollCollection('right')}
                                className="absolute right-0 top-1/2 -translate-y-1/2 z-20 p-2 rounded-lg bg-white/10 hover:bg-[#1DB954] transition-all duration-200 backdrop-blur-sm"
                            >
                                <ChevronRight className="w-5 h-5 lg:w-6 lg:h-6 text-white" />
                            </button>
                        )}
                        <div
                            ref={collectionScrollRef}
                            onScroll={handleCollectionScroll}
                            className="flex gap-4 overflow-x-auto py-3 px-1 -mx-1 scrollbar-hide"
                        >
                            {collection.parts.map((part) => {
                                const isCurrentMovie = part.id === movie.tmdb_id;
                                return (
                                    <div
                                        key={part.id}
                                        onClick={() => {
                                            if (!isCurrentMovie) {
                                                const clickTime = performance.now();
                                                void clickTime;

                                                setLocalMovieOverride({
                                                    id: `tmdb-${part.id}`,
                                                    title: part.title,
                                                    type: 'movie' as const,
                                                    year: part.release_date ? new Date(part.release_date).getFullYear() : new Date().getFullYear(),
                                                    rating: 'NR',
                                                    duration: '',
                                                    genre: [],
                                                    synopsis: '',
                                                    cast: [],
                                                    director: '',
                                                    poster_url: part.poster_path ? `https://image.tmdb.org/t/p/w500${part.poster_path}` : '',
                                                    backdrop_url: '',
                                                    score: 0,
                                                    tmdb_id: part.id,
                                                    category: 'trending' as const,
                                                });

                                                // Troca o filme LOCALMENTE — zero round-trip ao servidor
                                                setLocalOverride({
                                                    tmdbId: String(part.id),
                                                    mediaType: 'movie',
                                                    title: part.title,
                                                    poster_url: part.poster_path ? `https://image.tmdb.org/t/p/w500${part.poster_path}` : '',
                                                    backdrop_url: '',
                                                    year: part.release_date ? new Date(part.release_date).getFullYear() : new Date().getFullYear(),
                                                });

                                                // Pre-popular o cache React Query com dados básicos para renderização imediata
                                                const partData = {
                                                    id: `tmdb-${part.id}`,
                                                    title: part.title,
                                                    type: 'movie' as const,
                                                    year: part.release_date ? new Date(part.release_date).getFullYear() : new Date().getFullYear(),
                                                    rating: 'NR',
                                                    duration: '',
                                                    genre: [],
                                                    synopsis: '',
                                                    cast: [],
                                                    director: '',
                                                    poster_url: part.poster_path ? `https://image.tmdb.org/t/p/w500${part.poster_path}` : '',
                                                    backdrop_url: '',
                                                    score: 0,
                                                    tmdb_id: part.id,
                                                    category: 'trending' as const,
                                                };
                                                queryClient.setQueryData(['movie', 'tmdb', String(part.id), 'movie'], partData);
                                                // Invalidar para forçar busca dos dados reais (score, duration, etc.) em background
                                                queryClient.invalidateQueries({ queryKey: ['movie', 'tmdb', String(part.id), 'movie'] });

                                                // Atualizar URL sem navegar (apenas para bookmarking/compartilhamento)
                                                window.history.replaceState(null, '', `/watch?ref=${part.id}`);
                                            }
                                        }}
                                        onMouseEnter={() => {
                                            if (!isCurrentMovie) {
                                                // Prefetch da rota + pré-carregar dados do filme para ter score/duration prontos no clique
                                                router.prefetch(`/watch?ref=${part.id}`);
                                                // Pre-aquecer o cache React Query com dados reais no hover
                                                if (!queryClient.getQueryData(['movie', 'tmdb', String(part.id), 'movie'])) {
                                                    fetch(`/api/content/movie/${part.id}?language=pt-BR`)
                                                        .then(r => r.json())
                                                        .then(data => {
                                                            if (data?.id) {
                                                                queryClient.setQueryData(['movie', 'tmdb', String(part.id), 'movie'], {
                                                                    id: `tmdb-${part.id}`,
                                                                    title: data.title || part.title,
                                                                    type: 'movie' as const,
                                                                    year: data.release_date ? new Date(data.release_date).getFullYear() : new Date().getFullYear(),
                                                                    rating: 'NR',
                                                                    duration: data.runtime ? `${Math.floor(data.runtime / 60)}h ${data.runtime % 60}m` : '',
                                                                    genre: data.genres?.map((g: any) => g.name) || [],
                                                                    synopsis: data.overview || '',
                                                                    cast: [],
                                                                    director: '',
                                                                    poster_url: data.poster_path ? `https://image.tmdb.org/t/p/w500${data.poster_path}` : part.poster_path ? `https://image.tmdb.org/t/p/w500${part.poster_path}` : '',
                                                                    backdrop_url: data.backdrop_path ? `https://image.tmdb.org/t/p/original${data.backdrop_path}` : '',
                                                                    score: data.vote_average ? parseFloat(data.vote_average.toFixed(1)) : 0,
                                                                    tmdb_id: part.id,
                                                                    category: 'trending' as const,
                                                                });
                                                            }
                                                        })
                                                        .catch(() => {});
                                                }
                                            }
                                        }}
                                        className={`shrink-0 group ${isCurrentMovie ? 'cursor-default' : 'cursor-pointer'} hover:scale-103 hover:-translate-y-1 transition-all duration-200`}
                                    >

                                        <div
                                            className={`relative w-28 sm:w-32 lg:w-36 aspect-2/3 rounded-lg overflow-hidden bg-[#1f1f1f] transition-all duration-300
                                    ${isCurrentMovie ? 'ring-2 ring-[#46d369] ring-offset-2 ring-offset-[#1f1f1f]' : 'hover:ring-1 hover:ring-white/30'}`}
                                            role="button"
                                            tabIndex={isCurrentMovie ? -1 : 0}
                                            aria-label={isCurrentMovie ? `${part.title} - Assistindo agora` : `Assistir ${part.title}`}
                                            onKeyDown={(e) => {
                                                if (!isCurrentMovie && (e.key === 'Enter' || e.key === ' ')) {
                                                    router.push(`/watch?ref=${part.id}`);
                                                }
                                            }}
                                        >
                                            {part.poster_path && part.poster_path !== '' ? (
                                                <img
                                                    src={`https://image.tmdb.org/t/p/w342${part.poster_path}`}
                                                    alt=""
                                                    loading="lazy"
                                                    className={`w-full h-full object-cover transition-all duration-300
                                                ${isCurrentMovie ? 'opacity-100' : 'opacity-80 group-hover:opacity-100'}`}
                                                />
                                            ) : (
                                                <div className="w-full h-full flex items-center justify-center bg-linear-to-br from-[#2a2a2a] to-[#1a1a1a] text-gray-400 text-xs p-3 text-center font-medium">
                                                    {part.title}
                                                </div>
                                            )}
                                            {isCurrentMovie && (
                                                <div className="absolute bottom-0 left-0 right-0 bg-[#46d369] py-1 text-center">
                                                    <span className="text-black text-[10px] font-bold uppercase">Assistindo</span>
                                                </div>
                                            )}
                                        </div>
                                        <p className={`text-xs mt-2 truncate w-28 sm:w-32 lg:w-36 transition-colors text-center ${isCurrentMovie ? 'text-white font-medium' : 'text-gray-400 group-hover:text-white'}`}>
                                            {part.title}
                                        </p>
                                        {part.release_date && (
                                            <p className="text-gray-400 text-[11px] mt-1 text-center">
                                                {new Date(part.release_date).getFullYear()}
                                            </p>
                                        )}
                                    </div>
                                );
                            })}

                        </div>
                    </div>
                </div>
            </div>
        </section>
    );
});

export default WatchCollection;
