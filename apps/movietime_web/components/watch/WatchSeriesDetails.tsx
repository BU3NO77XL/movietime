'use client';

import { memo } from 'react';
import { Movie, CastMember } from '@/types/movie';
import StarRating from '@/components/watch/StarRating';

interface WatchSeriesDetailsProps {
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
    movie: Movie;
}

const WatchSeriesDetails = memo(function WatchSeriesDetails({
    seriesDetails,
    movie,
}: WatchSeriesDetailsProps) {
    return (
        <section className="py-8">
            <div className="bg-[#1a1a1a] rounded-xl p-6 sm:p-8">
                <h2 className="text-white text-xl md:text-2xl font-semibold mb-4">Detalhes</h2>
                <div className="flex flex-col lg:flex-col gap-3 text-sm text-gray-500">

                    {seriesDetails?.director && (
                        <div className="flex items-center gap-2">
                            <span>Criação:</span>
                            <span className="text-gray-300">{seriesDetails.director}</span>
                        </div>
                    )}

                    {/* Star Rating based on Score */}
                    {(movie.score ?? 0) > 0 && (
                        <div className="flex items-center gap-2" title={`Avaliação: ${movie.score}/10`}>
                            <span>Avaliação:</span>
                            <StarRating
                                score={movie.score ?? 0}
                                gradientIdPrefix="starGradient-series"
                                gradientIdSuffix={movie.id}
                                sizeClass="w-4 h-4"
                                scoreClassName="text-sm font-bold text-white"
                            />
                        </div>
                    )}

                    {/* Informações adicionais para séries */}
                    {seriesDetails && (
                        <>
                            <div className="flex items-center gap-2">
                                <span>Data de lançamento:</span>
                                <span className="text-gray-300">{seriesDetails.first_air_date}</span>
                            </div>
                            <div className="flex items-center gap-2">
                                <span>Última data:</span>
                                <span className="text-gray-300">{seriesDetails.last_air_date}</span>
                            </div>
                        </>
                    )}
                </div>
            </div>{/* fecha bg-[#1a1a1a] */}
        </section>
    );
});

export default WatchSeriesDetails;
