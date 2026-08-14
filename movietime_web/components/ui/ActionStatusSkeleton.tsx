'use client';

/** Placeholder neutro para botões de ação enquanto o estado real ainda não chegou. */
export default function ActionStatusSkeleton({ size = 20 }: { size?: number }) {
  return (
    <span
      className="inline-block rounded-full bg-white/25 animate-pulse"
      style={{ width: size, height: size }}
      aria-hidden
    />
  );
}
