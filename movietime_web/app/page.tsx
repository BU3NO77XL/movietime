'use client';

import { useState, useEffect, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import { motion } from 'framer-motion';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Movie } from '@/types/movie';
import HeroSection from '@/components/streaming/HeroSection';
import Carousel from '@/components/streaming/Carousel';
import BackdropCarousel from '@/components/streaming/BackdropCarousel';
import Top10Carousel from '@/components/streaming/Top10Carousel';
import PageSkeleton from '@/components/ui/PageSkeleton';
import MovieModal from '@/components/streaming/MovieModal';
import LoginRequiredModal from '@/components/streaming/LoginRequiredModal';
import { TMDBService } from '@/components/streaming/TMDBIntegration';
import { GENRE_NAME_TO_TMDB_ID } from '@/lib/genre-map';
import { toast } from 'sonner';
import { buildContinueWatchingItems, type WatchHistoryItem } from '@/lib/watch-history';
import { useUserRatings } from '@/hooks/useRatingAction';

export default function Home() {
  const router = useRouter();
  const queryClient = useQueryClient();
  const [selectedMovie, setSelectedMovie] = useState<Movie | null>(null);
  const [modalOpen, setModalOpen] = useState(false);
  const [loginModalOpen, setLoginModalOpen] = useState(false);
  const [continueWatching, setContinueWatching] = useState<Movie[]>([]);

  const [tmdbDataLoaded, setTmdbDataLoaded] = useState(false);
  const [carouselBackdrops, setCarouselBackdrops] = useState<Record<string, string | null>>({});
  const [userName, setUserName] = useState('');
  const [preferencesLoaded, setPreferencesLoaded] = useState(false);
  const [genreNames, setGenreNames] = useState<string[]>([]);
  const [recommendationsTimestamp, setRecommendationsTimestamp] = useState<string | null>(null);
  const [userId, setUserId] = useState<number | null>(() => {
    try {
      if (typeof window === 'undefined') return null;
      const stored = localStorage.getItem('userBasicInfo');
      return stored ? JSON.parse(stored).id : null;
    } catch { return null; }
  });

  // Busca perfil + preferências do banco via API
  useEffect(() => {
    let localId: number | null = null;
    try {
      const stored = localStorage.getItem('userBasicInfo');
      if (!stored) return;
      const local = JSON.parse(stored);
      setUserName(local.name || '');
      localId = local.id;
    } catch { /* silent */ }

    if (localId) {
        fetch(`/api/auth/profile?userId=${localId}`)
          .then((res) => res.ok ? res.json() : null)
          .then((data) => {
            if (data?.user) {
              setUserName(data.user.name || '');
              const prefs = data.user.preferences;
              if (prefs?.genres?.length) {
                setGenreNames(prefs.genres);
              }
              if (prefs?.recommendationsUpdatedAt) {
                setRecommendationsTimestamp(prefs.recommendationsUpdatedAt);
              }
            }
          })
          .catch(() => {});
      }
  }, []);

  useEffect(() => {
    const handleRequireLogin = () => setLoginModalOpen(true);
    window.addEventListener('requireLogin', handleRequireLogin);
    return () => window.removeEventListener('requireLogin', handleRequireLogin);
  }, []);

  // Check for requireLogin param from middleware redirect
  useEffect(() => {
    if (typeof window !== 'undefined') {
      const params = new URLSearchParams(window.location.search);
      if (params.get('requireLogin') === 'true') {
        setTimeout(() => window.dispatchEvent(new Event('requireLogin')), 100);
        // Clean URL
        window.history.replaceState({}, document.title, window.location.pathname);
      }
    }
  }, []);

  const { data: movies = [], isLoading } = useQuery({
    queryKey: ['movies'],
    queryFn: () => Promise.resolve<Movie[]>([]),
  });

  // Fetch TMDB data progressively on component mount
  useEffect(() => {
    const loadTMDBData = async () => {
      if (tmdbDataLoaded) return;

      const THREE_DAYS = 3 * 24 * 60 * 60 * 1000;
      const lastRefresh = parseInt(localStorage.getItem('lastCarouselRefresh') || '0');
      const needsRefresh = movies.length > 0 && (Date.now() - lastRefresh) > THREE_DAYS;
      // Só verifica filmes dos carrosséis (excluindo "Continue Assistindo" que pode ter genre:[])
      const carouselMovies = movies.filter((m: Movie) => m.category !== undefined && m.category !== 'personalized');
      const needsGenreRefresh = carouselMovies.length > 0 && carouselMovies.some((m: Movie) => !m.genre || m.genre.length === 0);

      if ((movies.length === 0 || needsGenreRefresh || needsRefresh) && !isLoading) {
        // Se for refresh (3 dias), limpa personalized e atualiza timestamp
        if (needsRefresh) {
          queryClient.setQueryData(['movies'], (old: Movie[] = []) => old.filter((m: Movie) => m.category === 'personalized'));
          localStorage.setItem('lastCarouselRefresh', String(Date.now()));
        } else if (needsGenreRefresh) {
          queryClient.setQueryData(['movies'], (old: Movie[] = []) => old.filter((m: Movie) => m.category === 'personalized'));
        }

        try {
          const [trendingToday, trending, topRated] = await Promise.all([
            TMDBService.fetchTrendingToday(),
            TMDBService.fetchTrending(),
            TMDBService.fetchTopRatedMovies()
          ]);

          const essentialMovies = [...trendingToday, ...trending, ...topRated];

          if (essentialMovies.length > 0) {
            queryClient.setQueryData(['movies'], (old: Movie[] = []) => [...old, ...essentialMovies as Movie[]]);
          }

          setTimeout(async () => {
            try {
              // Lote 1: conteúdo principal (4 endpoints)
              const [upcoming, top10, recommended, popularSeries] = await Promise.all([
                TMDBService.fetchUpcoming(),
                TMDBService.fetchTop10(),
                TMDBService.fetchRecommended(),
                TMDBService.fetchPopularSeries()
              ]);
              if ([...upcoming, ...top10, ...recommended, ...popularSeries].length > 0) {
                queryClient.setQueryData(['movies'], (old: Movie[] = []) => [...old, ...upcoming as Movie[], ...top10 as Movie[], ...recommended as Movie[], ...popularSeries as Movie[]]);
              }

              // Lote 2: gêneros (4 endpoints)
              await new Promise(r => setTimeout(r, 500));
              const [action, family, scifi, comedy] = await Promise.all([
                TMDBService.fetchActionMovies(),
                TMDBService.fetchFamilyMovies(),
                TMDBService.fetchSciFiMovies(),
                TMDBService.fetchComedyMovies()
              ]);
              if ([...action, ...family, ...scifi, ...comedy].length > 0) {
                queryClient.setQueryData(['movies'], (old: Movie[] = []) => [...old, ...action as Movie[], ...family as Movie[], ...scifi as Movie[], ...comedy as Movie[]]);
              }

              // Lote 3: mais gêneros + séries (4 endpoints)
              await new Promise(r => setTimeout(r, 500));
              const [romance, romanticComedy, horror, animation, topRatedSeries] = await Promise.all([
                TMDBService.fetchRomanceMovies(),
                TMDBService.fetchRomanticComedyMovies(),
                TMDBService.fetchHorrorMovies(),
                TMDBService.fetchAnimationMovies(),
                TMDBService.fetchTopRatedSeries()
              ]);
              if ([...romance, ...romanticComedy, ...horror, ...animation, ...topRatedSeries].length > 0) {
                queryClient.setQueryData(['movies'], (old: Movie[] = []) => [...old, ...romance as Movie[], ...romanticComedy as Movie[], ...horror as Movie[], ...animation as Movie[], ...topRatedSeries as Movie[]]);
              }

              const [topRatedBackdrop, upcomingBackdrop] = await Promise.all([
                TMDBService.getCarouselBackdrop('top_rated'),
                TMDBService.getCarouselBackdrop('coming_soon')
              ]);

              setCarouselBackdrops({
                top_rated: topRatedBackdrop,
                coming_soon: upcomingBackdrop
              });
            } catch (error) {
              console.error('Error loading additional TMDB data:', error);
            }
          }, 100);
        } catch (error) {
          console.error('Error loading TMDB data:', error);
          toast.error('Failed to load content from TMDB');
        }
        setTmdbDataLoaded(true);
      }
    };

    loadTMDBData();
  }, [movies.length, isLoading, queryClient, tmdbDataLoaded]);

  // Carrega filmes personalizados baseado nas preferências do banco
  useEffect(() => {
    const loadPersonalized = async () => {
      if (preferencesLoaded || genreNames.length === 0 || !userId) return;
      const genreIds = genreNames
        .map((g: string) => GENRE_NAME_TO_TMDB_ID[g])
        .filter((id: number | undefined): id is number => !!id);
      if (genreIds.length === 0) return;

      // Verifica cache de 48h pelo timestamp do banco
      const FORTY_EIGHT_HOURS = 48 * 60 * 60 * 1000;
      const lastUpdate = recommendationsTimestamp ? new Date(recommendationsTimestamp).getTime() : 0;
      const cacheValid = recommendationsTimestamp && (Date.now() - lastUpdate) < FORTY_EIGHT_HOURS;

      const existingMovies = queryClient.getQueryData<Movie[]>(['movies']) || [];
      const hasPersonalized = existingMovies.some((m) => m.category === 'personalized');

      if (cacheValid && hasPersonalized) {
        setPreferencesLoaded(true);
        return;
      }

      // Remove personalized antigos, busca novos
      queryClient.setQueryData(['movies'], (old: Movie[] = []) => old.filter((m) => m.category !== 'personalized'));

      const personalized = await TMDBService.fetchByGenreIds(genreIds);
      if (personalized.length > 0) {
        queryClient.setQueryData(['movies'], (old: Movie[] = []) => [...old, ...personalized as Movie[]]);
        // Atualiza timestamp no banco
        await fetch('/api/auth/recommendations', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ userId }),
        }).catch(() => {});
      }
      setPreferencesLoaded(true);
    };
    loadPersonalized();
  }, [queryClient, preferencesLoaded, genreNames, recommendationsTimestamp, userId]);

  // Watchlist do usuário vinda da API
  const { data: rawWatchlist, isFetched: watchlistFetched } = useQuery({
    queryKey: ['watchlist', userId],
    queryFn: () => fetch(`/api/watchlist?userId=${userId}`).then(r => r.json()),
    enabled: !!userId,
    staleTime: 60_000,
  });
  const watchlistData = rawWatchlist ?? { items: [] };
  const listReady = !userId || watchlistFetched;

  // Prefetch de ratings no cache (modal abre com estado correto sem flash)
  useUserRatings(userId);

  // Histórico de exibição para "Continue Assistindo"
  const { data: rawWatchHistory } = useQuery({
    queryKey: ['watchHistory', userId],
    queryFn: () => fetch(`/api/watch-history?userId=${userId}`).then(r => r.json()),
    enabled: !!userId,
    staleTime: 60_000,
    refetchOnMount: true,
    refetchOnWindowFocus: false,
  });

  useEffect(() => {
    const historyItems: WatchHistoryItem[] = rawWatchHistory?.items || [];
    if (historyItems.length === 0) {
      setContinueWatching([]);
      return;
    }
    const allMovies: Movie[] = movies || [];
    let cancelled = false;

    const initialMapped = buildContinueWatchingItems(historyItems as WatchHistoryItem[], allMovies);
    setContinueWatching(initialMapped);

    const fetchMissingDetails = async () => {
      const updated = await Promise.all(initialMapped.map(async (movie) => {
        if (movie.score != null && movie.rating != null && movie.year > 0 && movie.poster_url) {
          return movie;
        }
        try {
          const details = movie.type === 'series'
            ? await TMDBService.fetchSeriesDetails(Number(movie.tmdb_id))
            : await TMDBService.fetchMovieDetails(Number(movie.tmdb_id));
          if (!details) return movie;
          const voteAvg = (details as any).vote_average ?? (details as any).voteAverage;
          const yearVal = (details as any).first_air_date ? new Date((details as any).first_air_date).getFullYear() : ((details as any).release_date ? new Date((details as any).release_date).getFullYear() : movie.year);
          const posterPath = (details as any).poster_path || (details as any).posterUrl;
          const backdropPath = (details as any).backdrop_path || (details as any).backdropUrl;
          const posterUrl = posterPath ? (posterPath.startsWith('http') ? posterPath : `https://image.tmdb.org/t/p/w342${posterPath}`) : movie.poster_url;
          const backdropUrl = backdropPath ? (backdropPath.startsWith('http') ? backdropPath : `https://image.tmdb.org/t/p/w1280${backdropPath}`) : movie.backdrop_url;
          return {
            ...movie,
            poster_url: posterUrl || movie.poster_url,
            backdrop_url: backdropUrl || movie.backdrop_url,
            score: voteAvg != null ? parseFloat(Number(voteAvg).toFixed(1)) : movie.score,
            rating: details.ageRating || movie.rating,
            year: yearVal || movie.year,
            genre: details.genres?.length ? details.genres : movie.genre,
            total_episodes: (details as any).number_of_episodes,
            total_seasons: (details as any).number_of_seasons,
            season_episodes: (details as any).seasons?.find((s: any) => s.season_number === movie.season_number)?.episode_count || movie.season_episodes,
          };
        } catch {
          return movie;
        }
      }));
      if (!cancelled) {
        setContinueWatching(updated);
      }
    };

    fetchMissingDetails();
    return () => { cancelled = true; };
  }, [rawWatchHistory, movies]);

  const watchlistTmdbIds = useMemo(
    () => new Set(watchlistData.items.map((i: { tmdb_id: number }) => i.tmdb_id)),
    [watchlistData.items],
  );
  const selectedMovieInList = selectedMovie ? watchlistTmdbIds.has(Number(selectedMovie.tmdb_id)) : false;

  const addToListMutation = useMutation({
    mutationFn: (movie: Movie) =>
      fetch('/api/watchlist', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          userId,
          tmdbId: movie.tmdb_id,
          mediaType: movie.type,
          title: movie.title,
          posterUrl: movie.poster_url,
          backdropUrl: movie.backdrop_url,
        }),
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['watchlist', userId] });
      toast.success('Adicionado à sua lista!');
    },
  });

  const removeFromListMutation = useMutation({
    mutationFn: (movie: Movie) =>
      fetch('/api/watchlist', {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          userId,
          tmdbId: movie.tmdb_id,
          mediaType: movie.type,
        }),
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['watchlist', userId] });
      toast.success('Removido da sua lista!');
    },
  });

  const byCategory = useMemo(() => {
    const map: Record<string, Movie[]> = {};
    for (const m of movies as Movie[]) {
      const cat = m.category || 'unknown';
      if (!map[cat]) map[cat] = [];
      map[cat].push(m);
    }
    return map;
  }, [movies]);

  const personalizedMovies = byCategory.personalized || [];
  const trendingMovies = byCategory.trending || [];
  const topRatedMovies = byCategory.top_rated || [];
  const comingSoonMovies = byCategory.coming_soon || [];
  const recommendedMovies = byCategory.recommended || [];
  const top10Movies = byCategory.top_10 || [];
  const actionMovies = byCategory.action || [];
  const familyMovies = byCategory.family || [];
  const sciFiMovies = byCategory.scifi || [];
  const comedyMovies = byCategory.comedy || [];
  const romanceMovies = byCategory.romance || [];
  const romanticComedyMovies = byCategory.romantic_comedy || [];
  const horrorMovies = byCategory.horror || [];
  const animationMovies = byCategory.animation || [];
  const seriesPopularMovies = byCategory.series_popular || [];
  const seriesTopRatedMovies = byCategory.series_top_rated || [];

  const handleWatch = (movie: Movie) => {
    if (!userId) {
      setModalOpen(false);
      setLoginModalOpen(true);
      return;
    }
    const params = new URLSearchParams({ id: String(movie.id) });
    if (movie.rank) params.set('rank', String(movie.rank));
    if (movie.season_number) params.set('season', String(movie.season_number));
    if (movie.episode_number) params.set('episode', String(movie.episode_number));
    if (movie.tmdb_id) params.set('ref', String(movie.tmdb_id));
    if (movie.type) params.set('type', movie.type);
    router.push(`/watch?${params}`);
    setTimeout(() => setModalOpen(false), 100);
  };

  const handleMoreInfo = (movie: Movie) => {
    if (!movie.rank) {
      const top10Index = top10Movies.findIndex(m => m.tmdb_id && m.tmdb_id === movie.tmdb_id);
      if (top10Index >= 0) {
        movie = { ...movie, rank: top10Index + 1 };
      }
    }
    setSelectedMovie(movie);
    setModalOpen(true);
  };

  const handleAddToList = (movie: Movie) => {
    addToListMutation.mutate(movie);
  };

  const handleRemoveFromList = (movie: Movie) => {
    removeFromListMutation.mutate(movie);
  };

  if (movies.length === 0 || top10Movies.length === 0) {
    return <PageSkeleton />;
  }

  return (
    <motion.div
      className="min-h-screen bg-[#0a0a0a]"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.4, ease: 'easeOut' }}
    >
      {/* Hero + 1º carrossel no fluxo (logo abaixo de Assistir / Mais Informações) */}
      <HeroSection
        featuredMovies={top10Movies.slice(0, 10)}
        onWatch={handleWatch}
        onMoreInfo={handleMoreInfo}
        top10Ranks={Object.fromEntries(top10Movies.slice(0, 10).map((m, i) => [m.tmdb_id, i + 1]).filter(([id]) => id != null) as [number, number][])}
      >
        {continueWatching.length > 0 ? (
          <Carousel
            title="Recém assistidos"
            movies={continueWatching}
            onMovieClick={handleMoreInfo}
            maxItemsLoaded={continueWatching.length}
            className="!py-1 lg:!py-2"
          />
        ) : userId && personalizedMovies.length > 0 ? (
          <Carousel
            title="Para Você"
            movies={personalizedMovies}
            onMovieClick={handleMoreInfo}
            className="!py-1 lg:!py-2"
          />
        ) : trendingMovies.length > 0 ? (
          <Carousel
            title="Em Alta"
            movies={trendingMovies}
            onMovieClick={handleMoreInfo}
            className="!py-1 lg:!py-2"
          />
        ) : null}
      </HeroSection>

      {/* Demais carrosséis */}
      <div className="relative z-20 pb-12 space-y-5 -mt-2">
        {/* Para Você: só fora do hero se não for o 1º carrossel */}
        {continueWatching.length > 0 && userId && personalizedMovies.length > 0 && (
          <Carousel
            title="Para Você"
            movies={personalizedMovies}
            onMovieClick={handleMoreInfo}
          />
        )}

        {/* Em Alta: só fora do hero se não for o 1º carrossel */}
        {trendingMovies.length > 0 && (continueWatching.length > 0 || (userId && personalizedMovies.length > 0)) && (
          <Carousel
            title="Em Alta"
            movies={trendingMovies}
            onMovieClick={handleMoreInfo}
          />
        )}

        {top10Movies.length > 0 && (
          
          <Top10Carousel
            movies={top10Movies}
            onMovieClick={handleMoreInfo}
          />
          
        )}

        {comingSoonMovies.length > 0 && (
          
          <BackdropCarousel
            title="Em Breve"
            movies={comingSoonMovies}
            onMovieClick={handleMoreInfo}
            backdropUrl={carouselBackdrops.coming_soon}
          />
          
        )}

        {seriesPopularMovies.length > 0 && (
          
          <Carousel
            title="Séries Populares"
            movies={seriesPopularMovies}
            onMovieClick={handleMoreInfo}
          />
          
        )}

        {seriesTopRatedMovies.length > 0 && (
          
          <Carousel
            title="Melhores Séries"
            movies={seriesTopRatedMovies}
            onMovieClick={handleMoreInfo}
          />
          
        )}

        {comedyMovies.length > 0 && (
          
          <Carousel
            title="Comédia"
            movies={comedyMovies}
            onMovieClick={handleMoreInfo}
          />
          
        )}

        {romanceMovies.length > 0 && (
          
          <Carousel
            title="Romance"
            movies={romanceMovies}
            onMovieClick={handleMoreInfo}
          />
          
        )}

        {romanticComedyMovies.length > 0 && (
          
          <Carousel
            title="Comédia Romântica"
            movies={romanticComedyMovies}
            onMovieClick={handleMoreInfo}
          />
          
        )}

        {topRatedMovies.length > 0 && (
          
          <Carousel
            title="Mais Bem Avaliados"
            movies={topRatedMovies}
            onMovieClick={handleMoreInfo}
          />
          
        )}

        {familyMovies.length > 0 && (
          
          <Carousel
            title="Família"
            movies={familyMovies}
            onMovieClick={handleMoreInfo}
          />
          
        )}

        {horrorMovies.length > 0 && (
          
          <Carousel
            title="Terror"
            movies={horrorMovies}
            onMovieClick={handleMoreInfo}
          />
          
        )}

        {animationMovies.length > 0 && (
          
          <Carousel
            title="Animação"
            movies={animationMovies}
            onMovieClick={handleMoreInfo}
          />
          
        )}

        {sciFiMovies.length > 0 && (
          
          <Carousel
            title="Ficção Científica"
            movies={sciFiMovies}
            onMovieClick={handleMoreInfo}
          />
          
        )}

        {actionMovies.length > 0 && (
          
          <Carousel
            title="Ação"
            movies={actionMovies}
            onMovieClick={handleMoreInfo}
          />
          
        )}

        {recommendedMovies.length > 0 && (
          
          <Carousel
            title="Recomendados"
            movies={recommendedMovies}
            onMovieClick={handleMoreInfo}
          />
          
        )}

        {/* Show all movies if no categories */}
        {trendingMovies.length === 0 && topRatedMovies.length === 0 && movies.length > 0 && (
          <Carousel
            title="Todos os Filmes e Séries"
            movies={movies}
            onMovieClick={handleMoreInfo}
          />
        )}
      </div>

      {/* Movie Modal */}
      <MovieModal
        movie={selectedMovie}
        isOpen={modalOpen}
        onClose={() => setModalOpen(false)}
        onWatch={handleWatch}
        onAddToList={handleAddToList}
        isInWatchlist={selectedMovieInList}
        listReady={listReady}
        onRemoveFromList={handleRemoveFromList}
      />

      {/* Login Modal */}
      <LoginRequiredModal
        isOpen={loginModalOpen}
        onClose={() => setLoginModalOpen(false)}
      />
    </motion.div>
  );
}
