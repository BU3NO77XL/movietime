'use client';

// Shimmer wave animation — mesma direção e velocidade em todos os elementos
const S = "relative overflow-hidden bg-[#1e1e1e] before:absolute before:inset-0 before:-translate-x-full before:animate-[shimmer_1.6s_infinite] before:bg-gradient-to-r before:from-transparent before:via-white/[0.06] before:to-transparent";

/* ─── Hero skeleton ─────────────────────────────────────────────── */
function HeroSkeleton() {
    return (
        <div className="relative w-full h-[810px] bg-[#0a0a0a] overflow-hidden">
            {/* backdrop placeholder */}
            <div className={`absolute inset-0 ${S}`} />

            {/* overlays — idênticos ao HeroSection real */}
            <div
                className="absolute inset-0 z-10 pointer-events-none"
                style={{ background: 'linear-gradient(180deg,rgba(0,0,0,.38) 0%,rgba(0,0,0,.08) 30%,rgba(0,0,0,.42) 78%,rgba(0,0,0,.92) 100%)' }}
            />
            <div
                className="absolute inset-0 z-10 pointer-events-none"
                style={{ background: 'linear-gradient(90deg,rgba(0,0,0,.76) 0%,rgba(0,0,0,.36) 21%,rgba(0,0,0,0) 44%),linear-gradient(180deg,rgba(0,0,0,.55) 0%,rgba(0,0,0,0) 18%)' }}
            />

            {/* content — mesma posição do HeroSection: px-4 md:px-[38px] pt-[154px] */}
            <div className="absolute inset-0 z-20 px-4 md:px-[38px] pt-[154px] flex flex-col gap-5 max-w-[518px]">
                {/* logo/título */}
                <div className={`h-[100px] md:h-[120px] w-[280px] md:w-[420px] rounded-md ${S}`} />

                {/* badge Top10 */}
                <div className={`h-[30px] w-[160px] md:w-[220px] rounded-sm ${S}`} />

                {/* sinopse — 3 linhas */}
                <div className="space-y-2.5">
                    <div className={`h-[17px] w-full max-w-[490px] rounded ${S}`} />
                    <div className={`h-[17px] w-[85%] max-w-[440px] rounded ${S}`} />
                    <div className={`h-[17px] w-[60%] max-w-[310px] rounded ${S}`} />
                </div>

                {/* botões */}
                <div className="flex items-center gap-2 md:gap-4 mt-1">
                    <div className={`h-[50px] md:h-[52px] w-[130px] md:w-[152px] rounded-[4px] ${S}`} />
                    <div className={`h-[50px] md:h-[52px] w-[152px] md:w-[210px] rounded-[4px] ${S}`} />
                </div>
            </div>

            {/* bottom fade — igual ao real */}
            <div
                className="absolute bottom-0 left-0 right-0 h-[222px] z-20 pointer-events-none"
                style={{ background: 'linear-gradient(180deg,rgba(10, 10, 10,0) 0%,rgba(10, 10, 10,.15) 12%,rgba(10, 10, 10,.35) 26%,rgba(10, 10, 10,.58) 52%,rgba(10, 10, 10,1) 100%)' }}
            />
        </div>
    );
}

/* ─── Carrossel de posters (MovieCard: aspect-2/3, 160→200px) ───── */
function CarouselSkeleton({ title, count = 7 }: { title: string; count?: number }) {
    return (
        <section className="relative py-3 lg:py-4">
            {/* título */}
            <div className="pl-4 sm:pl-6 lg:pl-[24px] mb-2 lg:mb-3">
                <div className={`h-[22px] w-40 rounded ${S}`} />
            </div>

            {/* faixa de cards */}
            <div className="flex gap-3 lg:gap-4 pl-4 sm:pl-6 lg:pl-[24px] overflow-hidden">
                {Array.from({ length: count }).map((_, i) => (
                    <div
                        key={i}
                        className={`shrink-0 w-[140px] sm:w-[155px] lg:w-[170px] aspect-[2/3] rounded-sm sm:rounded-md ${S}`}
                    />
                ))}
            </div>
        </section>
    );
}

/* ─── Top 10 skeleton (Top10Card: posters maiores com número atrás) ─ */
function Top10Skeleton() {
    return (
        <section className="relative py-3 lg:py-4">
            <div className="pl-4 sm:pl-6 lg:pl-[24px] mb-2 lg:mb-3">
                <div className={`h-[22px] w-32 rounded ${S}`} />
            </div>

            <div className="flex gap-3 lg:gap-4 pl-4 sm:pl-6 lg:pl-[24px] overflow-hidden">
                {Array.from({ length: 8 }).map((_, i) => {
                    // rank 10 é mais largo — espelha Top10Card
                    const isLast = i === 9;
                    return (
                        <div
                            key={i}
                            className={`relative shrink-0 h-[175px] lg:h-[220px] xl:h-[265px] ${isLast ? 'w-[235px] lg:w-[245px] xl:w-[305px]' : 'w-[165px] lg:w-[210px] xl:w-[255px]'}`}
                        >
                            {/* número fantasma */}
                            <div className={`absolute left-0 top-0 w-[80px] lg:w-[105px] h-full rounded-sm opacity-30 ${S}`} />
                            {/* poster */}
                            <div className={`absolute top-0 left-[40px] lg:left-[48px] xl:left-[58px] w-[125px] lg:w-[155px] xl:w-[190px] h-full rounded-sm sm:rounded-md ${S}`} />
                        </div>
                    );
                })}
            </div>
        </section>
    );
}

/* ─── BackdropCarousel skeleton (cards landscape) ────────────────── */
function BackdropCarouselSkeleton() {
    return (
        <section className="relative py-3 lg:py-4">
            <div className="pl-4 sm:pl-6 lg:pl-[24px] mb-2 lg:mb-3">
                <div className={`h-[22px] w-24 rounded ${S}`} />
            </div>

            <div className="flex gap-3 lg:gap-4 pl-4 sm:pl-6 lg:pl-[24px] overflow-hidden">
                {Array.from({ length: 5 }).map((_, i) => (
                    <div
                        key={i}
                        className={`shrink-0 w-[260px] lg:w-[300px] aspect-video rounded-sm sm:rounded-md ${S}`}
                    />
                ))}
            </div>
        </section>
    );
}

/* ─── Root ────────────────────────────────────────────────────────── */
export default function PageSkeleton() {
    // Skeleton da home DESATIVADO - usando apenas um spinner branco centralizado
    // Se precisar reativar o skeleton completo, descomente o bloco abaixo e remova o retorno simplificado.
    /*
    return (
        <div className="min-h-screen bg-[#0a0a0a]">
                <HeroSkeleton />

                <div className="-mt-[380px] md:-mt-[420px] lg:-mt-[460px] relative z-20 pb-12 space-y-1">
                    <CarouselSkeleton title="" count={6} />
                    <CarouselSkeleton title="" count={7} />
                    <Top10Skeleton />
                    <BackdropCarouselSkeleton />
                    <CarouselSkeleton title="" count={7} />
                    <CarouselSkeleton title="" count={7} />
                    <CarouselSkeleton title="" count={7} />
                    <CarouselSkeleton title="" count={7} />
                </div>
        </div>
    );
    */

    return (
        <div className="min-h-screen bg-[#0a0a0a] flex items-center justify-center">
            <div className="w-12 h-12 border-4 border-white/90 border-t-transparent rounded-full animate-spin" aria-label="Carregando" />
        </div>
    );
}
