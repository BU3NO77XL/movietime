'use client';

import MovieCard from './MovieCard';
import { Movie } from '@/types/movie';
import BaseCarousel from '@/components/ui/BaseCarousel';

interface CarouselProps {
    title: string;
    movies: Movie[];
    onMovieClick: (movie: Movie) => void;
    showTitle?: boolean;
    maxItemsLoaded?: number;
    className?: string;
    containerClassName?: string;
    scrollContainerClassName?: string;
}

export default function Carousel({ title, movies, onMovieClick, showTitle = true, maxItemsLoaded, className, containerClassName, scrollContainerClassName }: CarouselProps) {
    if (!movies?.length) return null;

    return (
        <BaseCarousel
            title={title}
            showTitle={showTitle}
            maxItemsLoaded={maxItemsLoaded}
            className={className}
            containerClassName={containerClassName}
            scrollContainerClassName={scrollContainerClassName}
        >
            {movies.map((movie, index) => (
                <MovieCard
                    key={`${movie.tmdb_id ?? movie.id}-${index}`}
                    movie={movie}
                    onClick={onMovieClick}
                    index={index}
                />
            ))}
        </BaseCarousel>
    );
}
