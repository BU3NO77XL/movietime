'use client';

import { memo } from 'react';

interface StarRatingProps {
    score: number;
    /** Prefix before star index, e.g. "starGradient" or "starGradient-series" */
    gradientIdPrefix: string;
    /** Suffix after star index (usually movie.id) — produces `${prefix}-${star}-${suffix}` */
    gradientIdSuffix: string;
    sizeClass?: string;
    scoreClassName?: string;
}

const StarRating = memo(function StarRating({
    score,
    gradientIdPrefix,
    gradientIdSuffix,
    sizeClass = 'w-4 h-4 md:w-5 md:h-5',
    scoreClassName = 'text-sm md:text-base font-bold text-white',
}: StarRatingProps) {
    return (
        <>
            <div className="flex relative">
                {[1, 2, 3, 4, 5].map((star) => {
                    const ratingValue = score / 2; // Convert 0-10 to 0-5
                    const fillPercentage = Math.min(Math.max((ratingValue - (star - 1)) * 100, 0), 100);
                    const gradientId = `${gradientIdPrefix}-${star}-${gradientIdSuffix}`;

                    return (
                        <div key={star} className={`relative ${sizeClass} mr-0.5`}>
                            <svg
                                className="w-full h-full"
                                viewBox="0 0 24 24"
                            >
                                <defs>
                                    <linearGradient id={gradientId} x1="0%" y1="0%" x2="100%" y2="0%">
                                        <stop offset={`${fillPercentage}%`} stopColor="#ffffff" />
                                        <stop offset={`${fillPercentage}%`} stopColor="#4b5563" />
                                    </linearGradient>
                                </defs>
                                <path
                                    fill={`url(#${gradientId})`}
                                    d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"
                                />
                            </svg>
                        </div>
                    );
                })}
            </div>
            <span className={scoreClassName}>{(score / 2).toFixed(1)}</span>
        </>
    );
});

export default StarRating;
