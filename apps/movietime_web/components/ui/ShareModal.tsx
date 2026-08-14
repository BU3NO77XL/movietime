'use client';

import { useState } from 'react';
import { X, Share2, Check, Link2 } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { Movie } from '@/types/movie';
import { convertScoreToFivePoint } from '@/lib/utils';

interface ShareModalProps {
  movie: Movie;
  onClose: () => void;
}

export default function ShareModal({ movie, onClose }: ShareModalProps) {
  const [copied, setCopied] = useState(false);
  const shareUrl = typeof window !== 'undefined'
    ? `${window.location.origin}/watch?ref=${movie.tmdb_id}&type=${movie.type}`
    : '';

  const shareText = `Estou assistindo "${movie.title}" no Legacy Mov! ${shareUrl}`;

  const handleCopyLink = async () => {
    try {
      await navigator.clipboard.writeText(shareUrl);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      const input = document.createElement('input');
      input.value = shareUrl;
      document.body.appendChild(input);
      input.select();
      document.execCommand('copy');
      document.body.removeChild(input);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  const handleWhatsApp = () => {
    const url = `https://wa.me/?text=${encodeURIComponent(shareText)}`;
    window.open(url, '_blank', 'noopener,noreferrer');
  };

  const handleTwitter = () => {
    const url = `https://twitter.com/intent/tweet?text=${encodeURIComponent(shareText)}`;
    window.open(url, '_blank', 'noopener,noreferrer');
  };

  const rating = movie.score ? convertScoreToFivePoint(movie.score) : null;

  return (
    <AnimatePresence>
      <motion.div
        className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        onClick={onClose}
      >
        <motion.div
          className="bg-[#1a1a1a] border border-white/10 rounded-2xl max-w-sm w-full shadow-2xl overflow-hidden"
          initial={{ scale: 0.9, opacity: 0, y: 20 }}
          animate={{ scale: 1, opacity: 1, y: 0 }}
          exit={{ scale: 0.9, opacity: 0, y: 20 }}
          transition={{ type: 'spring', damping: 25, stiffness: 300 }}
          onClick={e => e.stopPropagation()}
        >
          <div className="relative">
            <button
              onClick={onClose}
              className="absolute top-3 right-3 z-10 p-1.5 bg-black/50 rounded-full hover:bg-black/70 transition-colors"
            >
              <X className="w-4 h-4 text-white" />
            </button>

            <div className="relative h-40 bg-gradient-to-t from-[#1a1a1a] to-transparent">
              {movie.backdrop_url ? (
                <img
                  src={movie.backdrop_url}
                  alt=""
                  className="w-full h-full object-cover absolute inset-0"
                />
              ) : (
                <div className="w-full h-full bg-gradient-to-br from-white/5 to-white/10 absolute inset-0" />
              )}
              <div className="absolute inset-0 bg-gradient-to-t from-[#1a1a1a] via-[#1a1a1a]/60 to-transparent" />
            </div>

            <div className="relative -mt-16 px-5 pb-2">
              <div className="flex items-end gap-4">
                <div className="w-20 h-28 shrink-0 rounded-lg overflow-hidden shadow-xl ring-2 ring-white/10">
                  {movie.poster_url ? (
                    <img src={movie.poster_url} alt={movie.title} className="w-full h-full object-cover" />
                  ) : (
                    <div className="w-full h-full bg-white/10 flex items-center justify-center">
                      <span className="text-2xl">🎬</span>
                    </div>
                  )}
                </div>
                <div className="flex-1 min-w-0 pb-0.5">
                  <h3 className="text-white font-bold text-sm leading-tight line-clamp-2">{movie.title}</h3>
                  <div className="flex items-center gap-2 mt-1">
                    {movie.year && <span className="text-gray-400 text-xs">{movie.year}</span>}
                    {rating && (
                      <div className="flex items-center gap-1">
                        <svg className="w-3 h-3 text-yellow-400 fill-yellow-400" viewBox="0 0 24 24">
                          <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
                        </svg>
                        <span className="text-yellow-400 text-xs font-medium">{rating}</span>
                      </div>
                    )}
                    <span className="text-white/60 text-xs capitalize">{movie.type === 'series' ? 'Série' : 'Filme'}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div className="px-5 py-4 space-y-3">
            <p className="text-gray-300 text-sm text-center font-medium">Compartilhe com seus amigos</p>
            <div className="flex gap-3">
              <button
                onClick={handleWhatsApp}
                className="flex-1 flex items-center justify-center gap-2 py-3 bg-[#25D366]/15 hover:bg-[#25D366]/25 border border-[#25D366]/30 rounded-xl transition-all group"
              >
                {/* WhatsApp SVG (fonte: Wikimedia Commons) */}
                <svg className="w-5 h-5" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden>
                  <path d="M16.002 3.2C9.027 3.2 3.6 8.627 3.6 15.6c0 2.742.9 5.267 2.441 7.339L5.2 28l5.196-1.353A12.345 12.345 0 0 0 16.002 27.2c6.975 0 12.402-5.427 12.402-12.4S22.977 3.2 16.002 3.2z" fill="#25D366"/>
                  <path d="M22.102 20.92c-.35-.17-2.07-1.02-2.39-1.14-.32-.12-.55-.17-.78.17s-.9 1.14-1.1 1.37c-.2.22-.39.25-.73.08-.34-.17-1.44-.53-2.75-1.69-1.02-.91-1.71-2.03-1.91-2.37-.2-.34-.02-.52.15-.7.15-.15.34-.39.51-.58.17-.2.23-.34.35-.56.12-.22.04-.41-.02-.58-.06-.17-.78-1.86-1.07-2.55-.28-.66-.57-.57-.78-.58-.2-.01-.42-.01-.64-.01s-.58.09-.89.43c-.31.34-1.18 1.15-1.18 2.8 0 1.65 1.21 3.25 1.38 3.48.17.22 2.39 3.65 5.8 4.98 3.41 1.33 3.41.89 4.02.84.61-.05 1.98-.81 2.26-1.6.28-.79.28-1.46.2-1.6-.08-.15-.28-.24-.63-.42z" fill="#fff"/>
                </svg>
                <span className="text-white text-sm font-medium">WhatsApp</span>
              </button>

              <button
                onClick={handleTwitter}
                className="flex-1 flex items-center justify-center gap-2 py-3 bg-white/5 hover:bg-white/10 border border-white/10 rounded-xl transition-all group"
              >
                {/* X icon (substitui Twitter) */}
                <svg className="w-5 h-5 text-white" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden>
                  <path d="M3 3l18 18M21 3L3 21" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
                <span className="text-white text-sm font-medium">X (antigo Twitter)</span>
              </button>
            </div>
            <button
              onClick={handleCopyLink}
              className="w-full flex items-center justify-center gap-2 py-2.5 bg-white/5 hover:bg-white/10 border border-white/10 rounded-xl transition-all"
            >
              {copied ? (
                <>
                  <Check className="w-4 h-4 text-green-400" />
                  <span className="text-green-400 text-sm font-medium">Copiado!</span>
                </>
              ) : (
                <>
                  <Link2 className="w-4 h-4 text-gray-300" />
                  <span className="text-gray-300 text-sm font-medium">Copiar Link</span>
                </>
              )}
            </button>
          </div>
        </motion.div>
      </motion.div>
    </AnimatePresence>
  );
}
