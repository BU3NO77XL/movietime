import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
    return twMerge(clsx(inputs));
}

// Page URL creator (simplified for Next.js)
export function createPageUrl(page: string): string {
    const routes: Record<string, string> = {
        Home: "/",
        MyList: "/my-list",
        Watch: "/watch",
    };
    return routes[page] || "/";
}

// Convert score from 10-point scale to 5-point scale
export function convertScoreToFivePoint(score: number): string {
    const converted = score / 2;
    // Always show one decimal place
    return converted.toFixed(1);
}
// Helper para garantir que URLs de vídeo sejam carregadas corretamente em produção
export function getAnimatedBackdropUrl(relativePath: string): string {
    // Garantir que o caminho comece com /
    const path = relativePath.startsWith('/') ? relativePath : `/${relativePath}`;
    
    // Em desenvolvimento e produção, usar caminho relativo para o arquivo público
    return path;
}

const TMDB_IMG = 'https://image.tmdb.org/t/p';

/**
 * Força a maior qualidade possível de imagem TMDB (`/original/`).
 * Aceita URL completa (qualquer size w1280/w780/...) ou path relativo (`/abc.jpg`).
 */
export function toTmdbOriginalUrl(url: string | null | undefined): string | null {
    if (!url || typeof url !== 'string') return null;
    const trimmed = url.trim();
    if (!trimmed) return null;

    // URL completa TMDB com size → original
    if (/image\.tmdb\.org\/t\/p\//i.test(trimmed)) {
        return trimmed.replace(/\/t\/p\/[^/]+\//i, '/t/p/original/');
    }

    // Path relativo do TMDB
    if (trimmed.startsWith('/')) {
        return `${TMDB_IMG}/original${trimmed}`;
    }

    return trimmed;
}