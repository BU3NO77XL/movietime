'use client';

import { useEffect, useRef, useState } from 'react';
import { cn } from '@/lib/utils';

interface TrailerBackdropProps {
  youtubeKey: string | null;
  muted?: boolean;
  /** Espera antes de montar o iframe (backdrop estático fica sozinho) */
  startDelayMs?: number;
  /**
   * Tempo com o player rodando em oculto antes de exibir.
   * Cobre o flash inicial dos botões/logo do YouTube.
   * Default: 4000ms
   */
  revealDelayMs?: number;
  loop?: boolean;
  className?: string;
  onPlayingChange?: (playing: boolean) => void;
}

function ytCommand(iframe: HTMLIFrameElement | null, func: string, args: unknown[] = []) {
  if (!iframe?.contentWindow) return;
  iframe.contentWindow.postMessage(
    JSON.stringify({ event: 'command', func, args }),
    '*'
  );
}

/**
 * Backdrop de trailer TMDB (YouTube embed) — estilo Netflix.
 * O iframe carrega e toca em oculto; só vira visível após revealDelayMs
 * (evita botões/logo do YouTube no começo do play).
 */
export default function TrailerBackdrop({
  youtubeKey,
  muted = true,
  startDelayMs = 800,
  revealDelayMs = 4000,
  loop = false,
  className,
  onPlayingChange,
}: TrailerBackdropProps) {
  const iframeRef = useRef<HTMLIFrameElement>(null);
  const revealTimerRef = useRef<number | null>(null);
  const [boot, setBoot] = useState(false);
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    setBoot(false);
    setVisible(false);
    onPlayingChange?.(false);
    if (revealTimerRef.current) {
      window.clearTimeout(revealTimerRef.current);
      revealTimerRef.current = null;
    }

    if (!youtubeKey) return;

    const t = window.setTimeout(() => setBoot(true), startDelayMs);
    return () => {
      window.clearTimeout(t);
      if (revealTimerRef.current) {
        window.clearTimeout(revealTimerRef.current);
        revealTimerRef.current = null;
      }
      onPlayingChange?.(false);
    };
  }, [youtubeKey, startDelayMs]);

  useEffect(() => {
    if (!visible) return;
    ytCommand(iframeRef.current, muted ? 'mute' : 'unMute');
    if (!muted) ytCommand(iframeRef.current, 'setVolume', [100]);
  }, [muted, visible]);

  if (!youtubeKey || !boot) return null;

  const origin =
    typeof window !== 'undefined' ? encodeURIComponent(window.location.origin) : '';

  const params = new URLSearchParams({
    autoplay: '1',
    mute: '1',
    controls: '0',
    disablekb: '1',
    fs: '0',
    iv_load_policy: '3',
    modestbranding: '1',
    playsinline: '1',
    rel: '0',
    showinfo: '0',
    cc_load_policy: '0',
    enablejsapi: '1',
    ...(origin ? { origin } : {}),
    ...(loop ? { loop: '1', playlist: youtubeKey } : {}),
  });

  const src = `https://www.youtube-nocookie.com/embed/${youtubeKey}?${params.toString()}`;

  return (
    <div
      className={cn(
        'absolute inset-0 overflow-hidden pointer-events-none transition-opacity duration-700 ease-out',
        visible ? 'opacity-100' : 'opacity-0',
        className
      )}
      style={{ visibility: visible ? 'visible' : 'hidden' }}
      aria-hidden
    >
      <iframe
        ref={iframeRef}
        key={`${youtubeKey}-${loop ? 'l' : 'n'}`}
        src={src}
        title="Trailer"
        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
        allowFullScreen={false}
        className="absolute top-1/2 left-1/2 border-0"
        style={{
          width: '177.78vh',
          height: '56.25vw',
          minWidth: '100%',
          minHeight: '100%',
          transform: 'translate(-50%, -50%) scale(1.45)',
          pointerEvents: 'none',
        }}
        onLoad={() => {
          // Player já está em autoplay mudo e oculto; só revela após o delay
          // para pular a UI inicial do YouTube (botões/logo).
          if (revealTimerRef.current) window.clearTimeout(revealTimerRef.current);
          revealTimerRef.current = window.setTimeout(() => {
            setVisible(true);
            onPlayingChange?.(true);
            ytCommand(iframeRef.current, muted ? 'mute' : 'unMute');
            revealTimerRef.current = null;
          }, revealDelayMs);
        }}
      />
    </div>
  );
}
