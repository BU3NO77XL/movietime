'use client';

import { memo, useCallback, useEffect, useRef, useState } from 'react';
import { motion } from 'framer-motion';
import { Play, ChevronLeft, ChevronRight } from 'lucide-react';
import { cn } from '@/lib/utils';
import { CastMember } from '@/types/movie';

interface Season {
    id: number;
    season_number: number;
    episode_count: number;
    name: string;
    air_date: string;
    poster_path: string;
}

interface Episode {
    id: number;
    episode_number: number;
    name: string;
    overview: string;
    air_date: string;
    runtime: number;
    still_path: string;
    vote_average: number;
}

interface WatchEpisodesProps {
    seriesDetails: {
        overview?: string;
        director?: string;
        cast: CastMember[];
        genres?: string[];
        tagline?: string;
        ageRating?: string;
        seasons?: Season[];
        number_of_seasons?: number;
        number_of_episodes?: number;
        first_air_date?: string;
        last_air_date?: string;
    };
    seasonDetails: { episodes: Episode[] } | null;
    selectedSeason: number;
    selectedEpisode: number;
    setSelectedEpisode: (episode: number) => void;
    isLoadingDetails: boolean;
    fetchSeasonDetails: (seasonNumber: number) => void;
}

const WatchEpisodes = memo(function WatchEpisodes({
    seriesDetails,
    seasonDetails,
    selectedSeason,
    selectedEpisode,
    setSelectedEpisode,
    isLoadingDetails,
    fetchSeasonDetails,
}: WatchEpisodesProps) {
    const [showLeftEpisodeArrow, setShowLeftEpisodeArrow] = useState(false);
    const [showRightEpisodeArrow, setShowRightEpisodeArrow] = useState(true);
    const episodesScrollRef = useRef<HTMLDivElement>(null);

    const handleEpisodeScroll = useCallback(() => {
        if (episodesScrollRef.current) {
            const { scrollLeft, scrollWidth, clientWidth } = episodesScrollRef.current;
            setShowLeftEpisodeArrow(scrollLeft > 10);
            setShowRightEpisodeArrow(scrollLeft < scrollWidth - clientWidth - 10);
        }
    }, []);

    const scrollEpisodes = useCallback((direction: 'left' | 'right') => {
        if (episodesScrollRef.current) {
            const scrollAmount = 300;
            episodesScrollRef.current.scrollBy({
                left: direction === 'left' ? -scrollAmount : scrollAmount,
                behavior: 'smooth'
            });
            setTimeout(() => handleEpisodeScroll(), 300);
        }
    }, [handleEpisodeScroll]);

    useEffect(() => {
        setShowLeftEpisodeArrow(false);
        setShowRightEpisodeArrow(true);
        if (episodesScrollRef.current) {
            episodesScrollRef.current.scrollLeft = 0;
        }
        const timer = setTimeout(() => handleEpisodeScroll(), 100);
        return () => clearTimeout(timer);
    }, [selectedSeason, seasonDetails, handleEpisodeScroll]);

    if (!seriesDetails.seasons || seriesDetails.seasons.length === 0) {
        return null;
    }

    return (
        <motion.section
            className="py-8"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.4, delay: 0.2, ease: 'easeOut' }}
        >

            {/* Cabeçalho da seção - Desktop: lado a lado, Mobile: empilhado */}
            <div className="mb-6 flex flex-col lg:flex-row lg:items-start lg:justify-between gap-4">
                
                {/* Lado esquerdo: Título e contador de episódios */}
                <div>
                    <h2 className="text-white text-xl md:text-2xl font-semibold mb-2">Episódios</h2>
                    {seriesDetails && (
                        <div className="flex items-center gap-2 text-sm text-gray-400">
                            <span>{seriesDetails.number_of_seasons} Temporadas</span>
                            <span className="w-1 h-1 rounded-full bg-gray-500" />
                            <span>{seriesDetails.number_of_episodes} Episódios</span>
                        </div>
                    )}
                </div>

                {/* Lado direito: Seletor de temporadas */}
                <div className="flex items-center gap-3">
                    <span className="text-white font-medium">Temporada:</span>
                    <div className="relative">
                        <select
                            value={selectedSeason}
                            onChange={(e: any) => fetchSeasonDetails(Number(e.target.value))}
                            className="bg-[#1f1f1f] text-white border border-white/20 rounded-lg py-2 pl-3 pr-8 appearance-none focus:outline-none focus:ring-2 focus:ring-[#1DB954] focus:border-transparent cursor-pointer"
                        >
                        {seriesDetails.seasons
                            .filter(season => season.season_number !== 0) // Excluir temporada especial
                            .map((season) => (
                                <option
                                    key={season.season_number}
                                    value={season.season_number}
                                    className="bg-[#1f1f1f] text-white"
                                >
                                    {season.season_number}
                                </option>
                            ))}
                    </select>
                    <div className="absolute inset-y-0 right-0 flex items-center px-2 pointer-events-none">
                        <svg className="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7"></path>
                        </svg>
                    </div>
                </div>
                <span className="text-gray-400 text-sm">
                    de {seriesDetails.seasons.filter(s => s.season_number !== 0).length}
                </span>
                </div>
            </div>

            {/* Carrossel de episódios */}
            <div className="relative group/episode -mx-4 sm:-mx-8 lg:-mx-12">
                {/* Botões de navegação - Estilo igual ao carrossel principal */}
                <button
                    onClick={() => scrollEpisodes('left')}
                    className={cn(
                        "absolute left-0 top-0 bottom-0 z-20 w-12",
                        "flex items-center justify-start pl-2",
                        "transition-opacity duration-300",
                        showLeftEpisodeArrow ? "opacity-100" : "opacity-0 pointer-events-none"
                    )}
                >
                    <div className="p-2 bg-black/60 transition-all duration-200 backdrop-blur-sm border border-white/10">
                        <ChevronLeft className="w-4 h-4 text-white" />
                    </div>
                </button>

                <button
                    onClick={() => scrollEpisodes('right')}
                    className={cn(
                        "absolute right-0 top-0 bottom-0 z-20 w-12",
                        "flex items-center justify-end pr-2",
                        "transition-opacity duration-300",
                        showRightEpisodeArrow ? "opacity-100" : "opacity-0 pointer-events-none"
                    )}
                >
                    <div className="p-2 bg-black/60 transition-all duration-200 backdrop-blur-sm border border-white/10">
                        <ChevronRight className="w-4 h-4 text-white" />
                    </div>
                </button>

                {/* Conteúdo rolável */}
                <div
                    ref={episodesScrollRef}
                    onScroll={handleEpisodeScroll}
                    className="flex gap-2.5 overflow-x-auto py-4 scrollbar-hide px-4 sm:px-8 lg:px-12"
                    style={{ scrollbarWidth: 'none', msOverflowStyle: 'none' }}
                >
                    {isLoadingDetails ? (
                        <div className="flex gap-2.5 py-2">
                            {[...Array(5)].map((_, i) => (
                                <div key={i} className="shrink-0 w-64">
                                    <div className="animate-pulse bg-white/10 rounded-lg h-36 mb-2" />
                                    <div className="animate-pulse bg-white/10 rounded h-4 w-3/4 mb-1" />
                                    <div className="animate-pulse bg-white/10 rounded h-3 w-1/2" />
                                </div>
                            ))}
                        </div>
                    ) : seasonDetails?.episodes && seasonDetails.episodes.length > 0 ? (
                        <>
                            {seasonDetails.episodes.map((episode) => (
                                <div
                                    key={episode.id}
                                    onClick={() => {
                                        setSelectedEpisode(episode.episode_number);
                                        const playerSection = document.getElementById('player-section');
                                        if (playerSection) {
                                            const headerOffset = 100;
                                            const elementPosition = playerSection.getBoundingClientRect().top;
                                            const offsetPosition = elementPosition + window.pageYOffset - headerOffset;
                                            window.scrollTo({
                                                top: offsetPosition,
                                                behavior: "smooth"
                                            });
                                        }
                                    }}
                                    className={`shrink-0 w-64 md:w-72 bg-[#1f1f1f] rounded overflow-hidden hover:bg-[#2a2a2a] transition-colors duration-200 cursor-pointer
                                        ${selectedEpisode === episode.episode_number ? 'ring-2 ring-[#46d369] ring-offset-2 ring-offset-[#1f1f1f]' : ''}`}
                                >
                                    <div className="relative">
                                        {episode.still_path ? (
                                            <img
                                                src={`https://image.tmdb.org/t/p/w300${episode.still_path}`}
                                                alt={episode.name}
                                                className="w-full h-36 object-cover"
                                            />
                                        ) : (
                                            <div className="w-full h-36 bg-gray-800 flex items-center justify-center">
                                                <Play className="w-8 h-8 text-gray-600" />
                                            </div>
                                        )}
                                        <div className="absolute bottom-2 right-2 bg-black/70 text-white text-xs px-2 py-1 rounded">
                                            {episode.runtime ? `${episode.runtime}min` : `Ep ${episode.episode_number}`}
                                        </div>
                                    </div>
                                    <div className="p-3">
                                        <h3 className="text-white font-medium text-xs sm:text-sm mb-1">
                                            {episode.episode_number}. {episode.name}
                                        </h3>
                                        <p className="text-gray-400 text-xs leading-relaxed">
                                            {episode.overview || 'Sem descrição disponível.'}
                                        </p>
                                        {episode.air_date && (
                                            <p className="text-gray-500 text-xs mt-2">
                                                {new Date(episode.air_date).toLocaleDateString('pt-BR')}
                                            </p>
                                        )}
                                    </div>
                                </div>
                            ))}

                        </>
                    ) : (
                        <p className="text-gray-400">Nenhum episódio encontrado para esta temporada.</p>
                    )}
                </div>
            </div>
        </motion.section>
    );
});

export default WatchEpisodes;
