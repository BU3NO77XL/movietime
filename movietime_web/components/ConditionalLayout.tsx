'use client';

import { Suspense } from 'react';
import { usePathname } from 'next/navigation';
import Header from '@/components/streaming/Header';
import Footer from '@/components/streaming/Footer';

export default function ConditionalLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const isAuthPage = pathname?.startsWith('/login') || pathname?.startsWith('/signup');
  // Espaço para a barra inferior de seções no mobile (exceto auth)
  const needsBottomNavPad = !isAuthPage;

  return (
    <>
      {!isAuthPage && (
        <Suspense fallback={null}>
          <Header />
        </Suspense>
      )}
      <div className={needsBottomNavPad ? 'pb-[calc(60px+env(safe-area-inset-bottom,0px))] md:pb-0' : undefined}>
        <main>{children}</main>
        {!isAuthPage && <Footer />}
      </div>
    </>
  );
}
