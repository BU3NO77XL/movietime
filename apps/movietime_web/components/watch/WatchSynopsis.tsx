'use client';

import { memo, useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { Movie, CastMember } from '@/types/movie';
import StarRating from '@/components/watch/StarRating';

interface WatchSynopsisProps {
    synopsis: string;
    SYNOPSIS_LIMIT: number;
    isSeries: boolean;
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
    movie: Movie;
}

const WatchSynopsis = memo(function WatchSynopsis({
    synopsis,
    SYNOPSIS_LIMIT,
    isSeries,
    movieDetails,
    movie,
}: WatchSynopsisProps) {
    const [isSynopsisExpanded, setIsSynopsisExpanded] = useState(false);

    useEffect(() => {
        setIsSynopsisExpanded(false);
    }, [synopsis, movie.tmdb_id]);

    return (
        <motion.section
            className="py-8"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.4, delay: 0.1, ease: 'easeOut' }}
        >
            <div className="bg-[#1a1a1a] rounded-xl p-6 sm:p-8">
                <h2 className="text-white text-xl md:text-2xl font-semibold mb-3">Descrição</h2>
                <p className="text-gray-200 text-base sm:text-base md:text-lg leading-relaxed max-w-4xl">
                    {!isSynopsisExpanded && synopsis.length > SYNOPSIS_LIMIT
                        ? `${synopsis.slice(0, SYNOPSIS_LIMIT)}...`
                        : synopsis}
                </p>
                {synopsis.length > SYNOPSIS_LIMIT && (
                    <button
                        onClick={() => setIsSynopsisExpanded(!isSynopsisExpanded)}
                        className="text-white hover:text-gray-300 text-sm font-medium mt-2 transition-colors"
                    >
                        {isSynopsisExpanded ? 'Ler menos' : 'Ler mais'}
                    </button>
                )}


                {/* Quick Info - MOVIDO PARA DEPOIS DOS EPISÓDIOS EM SÉRIES */}
                {!isSeries && (
                    <div className="flex flex-wrap gap-x-6 gap-y-1 mt-4 text-sm md:text-base text-gray-500">

                        {movieDetails?.director && (
                            <span>Direção: <span className="text-gray-300">{movieDetails.director}</span></span>
                        )}

                        {/* Star Rating based on Score */}
                        {(movie.score ?? 0) > 0 && (
                            <div className="flex items-center gap-2" title={`Avaliação: ${movie.score}/10`}>
                                <span>Avaliação do público:</span>
                                <StarRating
                                    score={movie.score ?? 0}
                                    gradientIdPrefix="starGradient"
                                    gradientIdSuffix={movie.id}
                                    sizeClass="w-4 h-4 md:w-5 md:h-5"
                                    scoreClassName="text-sm md:text-base font-bold text-white"
                                />
                            </div>
                        )}
                    </div>
                )}


                {/* Keywords/Tags - Desativado a pedido do usuario
                {keywords.length > 0 && (
                    <div className="flex flex-wrap gap-2 mt-4">

                        {keywords.map((keyword) => (
                            <span
                                key={keyword.id}
                                className="px-3 py-1 text-xs text-gray-400 bg-white/5 hover:bg-white/10 
                                    rounded-full border border-white/10 transition-colors cursor-default"
                            >
                                {keyword.name}
                            </span>
                        ))}
                    </div>
                )}
                */}
            </div>{/* fecha bg-[#1a1a1a] */}
        </motion.section>
    );
});

export default WatchSynopsis;
