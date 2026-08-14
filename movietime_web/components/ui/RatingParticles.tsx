'use client';

import { useMemo } from 'react';
import { motion } from 'framer-motion';

interface RatingParticlesProps {
  x: number;
  y: number;
  onComplete: () => void;
}

const PARTICLE_COUNT = 20;

function randomRange(min: number, max: number) {
  return min + Math.random() * (max - min);
}

/** Estrelinha de 4 pontas (sparkle) */
function Sparkle4({ size }: { size: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="white" aria-hidden>
      <path d="M12 0C12 6.627 17.373 12 24 12C17.373 12 12 17.373 12 24C12 17.373 6.627 12 0 12C6.627 12 12 6.627 12 0Z" />
    </svg>
  );
}

/** Estrelinha de 3 pontas */
function Sparkle3({ size }: { size: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="white" aria-hidden>
      <path d="M12 1.5L15.2 10.5L24 12L15.2 13.5L12 22.5L8.8 13.5L0 12L8.8 10.5L12 1.5Z" />
    </svg>
  );
}

/** Sparkle fino de 2 eixos (cruz em losango) */
function Sparkle2({ size }: { size: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="white" aria-hidden>
      <path d="M12 0L13.8 10.2L24 12L13.8 13.8L12 24L10.2 13.8L0 12L10.2 10.2L12 0Z" />
    </svg>
  );
}

type SparkleKind = 2 | 3 | 4;

interface Particle {
  dx: number;
  dy: number;
  size: number;
  delay: number;
  duration: number;
  rotate: number;
  kind: SparkleKind;
}

function createParticle(): Particle {
  const angle = randomRange(0, Math.PI * 2);
  const dist = randomRange(22, 85);
  const kinds: SparkleKind[] = [2, 3, 4];
  return {
    dx: Math.cos(angle) * dist,
    dy: Math.sin(angle) * dist,
    size: randomRange(6, 14),
    delay: randomRange(0, 0.12),
    duration: randomRange(0.7, 1.15),
    rotate: randomRange(-40, 40),
    kind: kinds[Math.floor(Math.random() * kinds.length)],
  };
}

function ParticleIcon({ kind, size }: { kind: SparkleKind; size: number }) {
  if (kind === 2) return <Sparkle2 size={size} />;
  if (kind === 3) return <Sparkle3 size={size} />;
  return <Sparkle4 size={size} />;
}

export default function RatingParticles({ x, y, onComplete }: RatingParticlesProps) {
  const particles = useMemo(
    () => Array.from({ length: PARTICLE_COUNT }, () => createParticle()),
    [],
  );

  return (
    <div
      className="fixed inset-0 pointer-events-none z-[100]"
      style={{ width: 0, height: 0, left: x, top: y }}
    >
      {particles.map((p, i) => (
        <motion.div
          key={i}
          className="absolute"
          style={{
            width: p.size,
            height: p.size,
            left: -p.size / 2,
            top: -p.size / 2,
            filter: 'drop-shadow(0 0 2px rgba(255,255,255,0.55))',
          }}
          initial={{ x: 0, y: 0, opacity: 0.95, scale: 0, rotate: 0 }}
          animate={{
            x: p.dx,
            y: p.dy,
            opacity: 0,
            scale: 1.15,
            rotate: p.rotate,
          }}
          transition={{
            x: { duration: p.duration, ease: [0.2, 0.45, 0.3, 1], delay: p.delay },
            y: { duration: p.duration, ease: [0.2, 0.45, 0.3, 1], delay: p.delay },
            opacity: { duration: 0.5, ease: 'easeOut', delay: p.delay + 0.25 },
            scale: { duration: 0.22, ease: 'easeOut', delay: p.delay },
            rotate: { duration: p.duration, ease: 'easeOut', delay: p.delay },
          }}
          onAnimationComplete={i === 0 ? onComplete : undefined}
        >
          <ParticleIcon kind={p.kind} size={p.size} />
        </motion.div>
      ))}
    </div>
  );
}
