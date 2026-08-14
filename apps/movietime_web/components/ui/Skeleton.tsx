'use client';

import { cn } from '@/lib/utils';

interface SkeletonProps {
  className?: string;
  variant?: 'card' | 'text' | 'circle' | 'rectangle';
  width?: string | number;
  height?: string | number;
  count?: number;
}

export default function Skeleton({
  className,
  variant = 'rectangle',
  width,
  height,
  count = 1
}: SkeletonProps) {
  const baseClasses = "animate-pulse bg-white/10 rounded";

  const variantClasses = {
    card: "aspect-2/3 w-full rounded-lg",
    text: "h-4 w-full rounded",
    circle: "rounded-full",
    rectangle: "rounded"
  };

  const skeletonElement = (
    <div
      className={cn(baseClasses, variantClasses[variant], className)}
      style={{ width, height }}
    />
  );

  if (count === 1) {
    return skeletonElement;
  }

  return (
    <>
      {Array.from({ length: count }, (_, i) => (
        <div key={i} className={cn(baseClasses, variantClasses[variant], className)} style={{ width, height }} />
      ))}
    </>
  );
}

// Skeleton components for specific use cases
export function MovieCardSkeleton({ count = 6 }: { count?: number }) {
  return (
    <div className="flex gap-3 lg:gap-4 px-4 sm:px-6 lg:px-12">
      {Array.from({ length: count }, (_, i) => (
        <div key={i} className="shrink-0 w-[110px] sm:w-[130px] lg:w-[160px]">
          <Skeleton variant="card" />
          <div className="mt-2 space-y-1">
            <Skeleton variant="text" className="h-3" />
            <Skeleton variant="text" className="h-2 w-3/4" />
          </div>
        </div>
      ))}
    </div>
  );
}

export function CarouselSkeleton({ title }: { title?: string }) {
  return (
    <section className="relative py-4 lg:py-6">
      <div className="max-w-[1800px] mx-auto px-4 sm:px-6 lg:px-12 mb-3 lg:mb-4">
        {title ? (
          <h2 className="text-lg sm:text-xl lg:text-2xl font-bold text-white tracking-tight">
            {title}
          </h2>
        ) : (
          <Skeleton variant="text" className="h-6 w-48" />
        )}
      </div>
      <MovieCardSkeleton />
    </section>
  );
}

export function HeroSkeleton() {
  return (
    <section className="relative w-full bg-[#0a0a0a]">
      <div className="relative w-full h-[62svh] min-h-[500px] max-h-[580px] sm:h-[68vh] sm:min-h-[560px] sm:max-h-[700px] md:h-[80vh] md:min-h-[620px] md:max-h-[810px]">
        <Skeleton className="absolute inset-0" />
        <div className="absolute inset-x-0 top-[80px] sm:top-[88px] md:top-[96px] bottom-[72px] sm:bottom-[80px] md:bottom-[96px] z-20 flex flex-col justify-end">
          <div className="px-4 md:px-[38px] max-w-[518px] space-y-3 md:space-y-4">
            <Skeleton variant="text" className="h-12 md:h-20 w-3/4" />
            <Skeleton variant="text" className="h-12 w-full hidden sm:block" />
            <div className="flex gap-3">
              <Skeleton className="h-[42px] md:h-[52px] w-28 md:w-36 rounded" />
              <Skeleton className="h-[42px] md:h-[52px] w-24 md:w-40 rounded" />
            </div>
          </div>
          {/* Badge de idade — entre botões e carrossel */}
          <div className="mt-3 sm:mt-4 md:mt-5 flex justify-end items-center h-[35px]">
            <Skeleton className="h-[35px] w-[35px] rounded-full mr-2" />
            <Skeleton className="h-[35px] w-20 sm:w-28 rounded-none" />
          </div>
        </div>
      </div>
    </section>
  );
}