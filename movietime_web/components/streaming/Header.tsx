'use client';

import { useState, useEffect, useCallback, memo, useRef } from 'react';
import Link from 'next/link';
import { usePathname, useSearchParams } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
import { Search, User, Play, Star, Film, Tv, Settings, CreditCard, LogOut, Home, Flame, Globe } from 'lucide-react';
import { cn } from '@/lib/utils';
import NetflixAvatar from '../NetflixAvatar';
import SearchOverlay from './SearchOverlay';
import InstallButton from './InstallButton';

const HEADER_ITEMS = [
    { label: 'Início', href: '/' },
    { label: 'Séries', href: '/?filter=series' },
    { label: 'Filmes', href: '/?filter=movie' },
    { label: 'Novidades', href: '/' },
    { label: 'Minha Lista', href: '/my-list' },
    { label: 'Idiomas', href: '/' },
];

const Header = memo(function Header() {
    const pathname = usePathname();
    const searchParams = useSearchParams();
    const activeFilter = searchParams.get('filter') || '';

    const [scrolled, setScrolled] = useState(false);
    const [searchOpen, setSearchOpen] = useState(false);
    const [mounted, setMounted] = useState(false);
    const [userDropdownOpen, setUserDropdownOpen] = useState(false);
    const [userData, setUserData] = useState<{ name: string; email: string; role?: string; avatarUrl?: string | null; preferences?: { avatarIndex?: number; genres?: string } | null } | null>(() => {
      try {
        if (typeof window === 'undefined') return null;
        const stored = localStorage.getItem('userBasicInfo');
        return stored ? JSON.parse(stored) : null;
      } catch { return null; }
    });
    const scrollRafRef = useRef<number | null>(null);

    useEffect(() => { setMounted(true); }, []);

    useEffect(() => {
        const handleScroll = () => {
            if (scrollRafRef.current != null) return;
            scrollRafRef.current = requestAnimationFrame(() => {
                scrollRafRef.current = null;
                setScrolled(window.scrollY > 0);
            });
        };
        // Estado inicial + listener leve (rAF evita re-render a cada pixel de scroll)
        setScrolled(window.scrollY > 0);
        window.addEventListener('scroll', handleScroll, { passive: true });
        return () => {
            window.removeEventListener('scroll', handleScroll);
            if (scrollRafRef.current != null) cancelAnimationFrame(scrollRafRef.current);
        };
    }, []);

    const isNavActive = useCallback((link: { label: string; href: string }) => {
        if (link.href.includes('?filter=series')) return activeFilter === 'series';
        if (link.href.includes('?filter=movie')) return activeFilter === 'movie';
        if (link.href === '/my-list') return pathname === '/my-list';
        if (link.label === 'Início') return pathname === '/' && !activeFilter;
        return false;
    }, [activeFilter, pathname]);

    const handleNavClick = useCallback((e: { preventDefault: () => void }, href: string) => {
        if (href === '/my-list' && !userData) {
            e.preventDefault();
            window.dispatchEvent(new Event('requireLogin'));
        }
    }, [userData]);

    // ConditionalLayout já oculta Header em /login; guard extra pós-hooks
    if (pathname === '/login') return null;

    const renderIcon = (label: string, active = false) => {
        const cls = cn('w-5 h-5', active ? 'text-white' : 'text-gray-400');
        switch (label) {
            case 'Início':
                return <Home className={cls} />;
            case 'Séries':
                return <Tv className={cls} />;
            case 'Filmes':
                return <Film className={cls} />;
            case 'Novidades':
                return <Flame className={cls} />;
            case 'Minha Lista':
                return <Star className={cls} />;
            case 'Idiomas':
                return <Globe className={cls} />;
            default:
                return <Play className={cls} />;
        }
    };

    const renderUserIcon = (label: string) => {
        switch (label) {
            case 'Perfil':
                return <User className="w-4 h-4 text-gray-400" />;
            case 'Configurações':
                return <Settings className="w-4 h-4 text-gray-400" />;
            case 'Planos':
                return <CreditCard className="w-4 h-4 text-gray-400" />;
            case 'Sair':
                return <LogOut className="w-4 h-4 text-red-400" />;
            default:
                return <User className="w-4 h-4 text-gray-400" />;
        }
    };

    return (
        <>
            <header
                className={cn(
                    "fixed top-0 left-0 right-0 z-[100] transition-colors duration-300",
                    scrolled
                        ? "bg-[#0a0a0a]"
                        : "bg-transparent"
                )}
            >
                {/* Header Gradient matching rdesign */}
                <div 
                    className={cn(
                        "absolute inset-0 transition-opacity duration-300",
                        scrolled ? "opacity-0" : "opacity-100"
                    )}
                    style={{
                        background: 'linear-gradient(180deg, rgba(0, 0, 0, 0.7) 12.5%, rgba(0, 0, 0, 0) 100%)',
                        height: '72px'
                    }}
                />

                <div className="w-full px-4 md:px-[38px] relative z-10">
                    <div className="flex items-center justify-between h-[72px]">
                        <div className="flex items-center gap-[45px]">
                            <Link href="/" className="shrink-0 flex items-center gap-2 min-w-0">
                                {/* Logo fundo verde (ativo). Para voltar ao preto elegante, descomente o bloco abaixo e comente este. */}
                                <div className="w-8 h-8 sm:w-8 sm:h-8 md:w-8 md:h-8 rounded-md sm:rounded-lg bg-[#1DB954] flex items-center justify-center shrink-0 shadow-lg shadow-[#1DB954]/20">
                                    <Play className="w-4 h-4 sm:w-4 sm:h-4 md:w-4 md:h-4 text-white fill-white" />
                                </div>
                                {/* Logo fundo preto elegante (desativado)
                                <div
                                    className="w-8 h-8 sm:w-8 sm:h-8 md:w-8 md:h-8 rounded-md sm:rounded-lg flex items-center justify-center shrink-0"
                                    style={{
                                        background: 'linear-gradient(145deg, #1c1c1c 0%, #0a0a0a 55%, #111 100%)',
                                        boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.08), 0 2px 8px rgba(0,0,0,0.45)',
                                        border: '1px solid rgba(255,255,255,0.1)',
                                    }}
                                >
                                    <Play className="w-4 h-4 sm:w-4 sm:h-4 md:w-4 md:h-4 text-white fill-white" />
                                </div>
                                */}
                                <h1
                                    className="text-[19px] sm:text-[20px] md:text-[20px] lg:text-[22px] uppercase leading-none whitespace-nowrap"
                                    style={{
                                        color: '#FFFFFF',
                                        fontFamily: '"Netflix Sans"',
                                        fontWeight: 900,
                                        letterSpacing: '-0.04em',
                                        textTransform: 'uppercase'
                                    }}
                                >
                                    Legacy Mov
                                </h1>
                            </Link>

                            {/* Desktop Navigation */}
                            <nav className="hidden md:flex items-center gap-[28px] pt-[4px]">
                                {HEADER_ITEMS?.map((link) => {
                                    const isActive = isNavActive(link);

                                    return (
                                        <Link
                                            key={link.label}
                                            href={link.href}
                                            onClick={(e) => handleNavClick(e, link.href)}
                                            className={cn(
                                                "text-[15px] transition-colors duration-200 whitespace-nowrap",
                                                isActive
                                                    ? "text-white font-medium"
                                                    : "text-[#e5e5e5] hover:text-[#b3b3b3] font-normal"
                                            )}
                                        >
                                            {link.label}
                                        </Link>
                                    );
                                })}
                            </nav>
                        </div>

                        {/* Right Section */}
                        <div className="flex items-center gap-2.5 sm:gap-4 md:gap-5">
                            <div className="hidden lg:flex items-center">
                                <InstallButton />
                            </div>

                            <button
                                onClick={() => setSearchOpen(true)}
                                className="p-1 text-white hover:opacity-80 transition-opacity"
                                aria-label="Open search"
                            >
                                <Search className="w-5 h-5 sm:w-6 sm:h-6 md:w-7 md:h-7" strokeWidth={2.5} />
                            </button>

                            {/* User Dropdown */}
                            <div className="relative flex items-center gap-2">
                                {!mounted ? (
                                    <div className="w-9 h-9 rounded-full bg-white/10" aria-hidden />
                                ) : userData ? (
                                    <>
                                    <button
                                        onClick={() => {
                                            setUserDropdownOpen(!userDropdownOpen);
                                            setSearchOpen(false);
                                        }}
                                        className="flex items-center gap-2"
                                    >
                                        <div className="relative">
                                            <NetflixAvatar name={userData?.name || 'User'} selectedIndex={userData?.preferences?.avatarIndex ?? null} size={36} />
                                            {userData?.role === 'admin' && (
                                                <div className="absolute -bottom-0.5 -right-0.5 w-3.5 h-3.5 bg-yellow-500 rounded-full flex items-center justify-center ring-2 ring-[#0a0a0a]">
                                                    <Star className="w-2 h-2 text-black fill-current" />
                                                </div>
                                            )}
                                        </div>
                                        <div className="w-0 h-0 border-l-[5px] border-l-transparent border-r-[5px] border-r-transparent border-t-[5px] border-t-white mt-1" />
                                    </button>

                                    <AnimatePresence>
                                    {userDropdownOpen && (
                                        <>
                                            <div
                                                className="fixed inset-0 z-30"
                                                onClick={() => setUserDropdownOpen(false)}
                                            />
                                            <motion.div
                                                className="absolute right-0 top-[40px] w-56 bg-black/90 border border-white/10 rounded shadow-2xl z-40 overflow-hidden backdrop-blur-md"
                                                initial={{ opacity: 0, scale: 0.92, y: -8 }}
                                                animate={{ opacity: 1, scale: 1, y: 0 }}
                                                exit={{ opacity: 0, scale: 0.92, y: -8 }}
                                                transition={{ duration: 0.15, ease: 'easeOut' }}
                                            >
                                            <div className="p-4 border-b border-white/10">
                                                    <p className="text-white font-semibold">{userData?.name || 'Minha Conta'}</p>
                                                    <p className="text-gray-400 text-sm">
                                                        {userData?.email
                                                            ? userData.email.slice(0, 2) + '***' + userData.email.slice(userData.email.indexOf('@'))
                                                            : 'usuario@email.com'}
                                                    </p>
                                                    {userData?.role === 'admin' && (
                                                        <p className="text-white font-bold text-xs mt-1">Administrador</p>
                                                    )}
                                                </div>
                                                <div className="py-2">
                                                    <Link href="/profile" className="w-full px-4 py-2.5 text-left text-gray-300 hover:text-white hover:bg-white/5 transition-colors flex items-center gap-3" onClick={() => setUserDropdownOpen(false)}>
                                                        <span aria-hidden>{renderUserIcon('Perfil')}</span>
                                                        <span>Perfil</span>
                                                    </Link>
                                                    <Link href="/settings" className="w-full px-4 py-2.5 text-left text-gray-300 hover:text-white hover:bg-white/5 transition-colors flex items-center gap-3" onClick={() => setUserDropdownOpen(false)}>
                                                        <span aria-hidden>{renderUserIcon('Configurações')}</span>
                                                        <span>Configurações</span>
                                                    </Link>
                                                    {/* Planos — desativado; descomente para reativar
                                                    <button className="w-full px-4 py-2.5 text-left text-gray-300 hover:text-white hover:bg-white/5 transition-colors flex items-center gap-3" onClick={() => setUserDropdownOpen(false)}>
                                                        <span aria-hidden>{renderUserIcon('Planos')}</span>
                                                        <span>Planos</span>
                                                    </button>
                                                    */}
                                                </div>
                                                <div className="border-t border-white/10 py-2">
                                                    <button
                                                        className="w-full px-4 py-2.5 text-left text-red-400 hover:text-red-300 hover:bg-white/5 transition-colors flex items-center gap-3"
                                                        onClick={async () => {
                                                            setUserDropdownOpen(false);
                                                            
                                                            try {
                                                                await fetch('/api/auth/logout', { method: 'POST' });
                                                            } catch (e) {
                                                                console.error(e);
                                                            }
                                                            
                                                            localStorage.removeItem('sb-session');
                                                            localStorage.removeItem('userBasicInfo');
                                                            localStorage.removeItem('userPreferences');
                                                            setUserData(null);
                                                            window.location.href = '/login';
                                                        }}
                                                    >
                                                        <span aria-hidden>{renderUserIcon('Sair')}</span>
                                                        <span>Sair</span>
                                                    </button>
                                                </div>
                                            </motion.div>
                                        </>
                                    )}
                                    </AnimatePresence>
                                    </>
                                ) : (
                                    <Link
                                        href="/login"
                                        className="bg-white text-black font-semibold px-3 py-1.5 sm:px-5 sm:py-2 rounded text-xs sm:text-sm md:text-base hover:bg-white/90 transition-colors whitespace-nowrap"
                                    >
                                        Fazer login
                                    </Link>
                                )}
                            </div>
                        </div>
                    </div>
                </div>

            </header>

            {/* Mobile bottom navigation bar — mesmo estilo do dropdown de perfil */}
            <nav
                className="md:hidden fixed bottom-0 left-0 right-0 z-[120] bg-black/90 border-t border-white/10 shadow-2xl backdrop-blur-md overflow-hidden"
                style={{ paddingBottom: 'env(safe-area-inset-bottom, 0px)' }}
                aria-label="Menu de seções"
            >
                <div className="flex items-stretch justify-between h-[60px] px-1">
                    {HEADER_ITEMS.map((link) => {
                        const isActive = isNavActive(link);
                        return (
                            <Link
                                key={link.label}
                                href={link.href}
                                onClick={(e) => handleNavClick(e, link.href)}
                                className={cn(
                                    'flex-1 flex flex-col items-center justify-center gap-0.5 min-w-0 px-0.5 transition-colors',
                                    isActive ? 'text-white' : 'text-gray-400 active:text-white'
                                )}
                            >
                                <span aria-hidden className="flex items-center justify-center">
                                    {renderIcon(link.label, isActive)}
                                </span>
                                <span
                                    className={cn(
                                        'text-[9px] leading-tight truncate max-w-full',
                                        isActive ? 'font-semibold text-white' : 'font-medium text-gray-400'
                                    )}
                                >
                                    {link.label}
                                </span>
                            </Link>
                        );
                    })}
                </div>
            </nav>

            <SearchOverlay
                isOpen={searchOpen}
                onClose={() => setSearchOpen(false)}
            />
        </>
    );
}
);

export default Header;
