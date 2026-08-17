import 'dart:convert';

import 'package:appflutter/screens/home_search.dart';
import 'package:appflutter/services/api_client.dart';
import 'package:appflutter/services/content_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _genresJson = {
  'genres': [
    {'id': 28, 'name': 'A\u00e7\u00e3o'},
    {'id': 878, 'name': 'Sci-Fi'},
    {'id': 35, 'name': 'Com\u00e9dia'},
    {'id': 10749, 'name': 'Romance'},
  ],
};

const _trendingJson = {
  'results': [
    {
      'id': 1,
      'media_type': 'movie',
      'title': 'Dune',
      'poster_path': '/dune.jpg',
      'backdrop_path': '/dune.jpg',
      'release_date': '2021-09-15',
      'vote_average': 8.0,
      'genre_ids': [878, 12],
    },
    {
      'id': 2,
      'media_type': 'tv',
      'name': 'Severance',
      'first_air_date': '2022-02-18',
      'vote_average': 8.7,
      'genre_ids': [18, 9648],
    },
    {
      'id': 3,
      'media_type': 'movie',
      'title': 'The Gorge',
      'release_date': '2025-02-14',
      'vote_average': 6.7,
      'genre_ids': [28, 878],
    },
  ],
};

const _trendingPersonJson = {
  'results': [
    {'id': 11, 'name': 'Tom Hanks', 'profile_path': '/hanks.jpg'},
  ],
};

const _searchMultiJson = {
  'results': [
    {
      'id': 1,
      'media_type': 'movie',
      'title': 'Dune',
      'poster_path': '/dune.jpg',
      'release_date': '2021-09-15',
      'vote_average': 8.0,
      'genre_ids': [878],
    },
    {
      'id': 2,
      'media_type': 'tv',
      'name': 'Dune: Prophecy',
      'first_air_date': '2024-11-17',
      'vote_average': 7.6,
      'genre_ids': [18],
    },
  ],
};

const _searchPersonJson = {
  'results': [
    {'id': 11, 'name': 'Tom Hanks', 'profile_path': '/hanks.jpg'},
  ],
};

const _creditsJson = {
  'cast': [
    {'id': 101, 'name': 'Timoth\u00e9e Chalamet', 'profile_path': '/tim.jpg'},
    {'id': 102, 'name': 'Zendaya', 'profile_path': '/zen.jpg'},
  ],
};

MockClient _mockClient() {
  return MockClient((request) async {
    final path = request.url.path;
    if (path.startsWith('/api/content/genre/')) {
      return http.Response(jsonEncode(_genresJson), 200);
    }
    if (path.startsWith('/api/content/trending/person/')) {
      return http.Response(jsonEncode(_trendingPersonJson), 200);
    }
    if (path.startsWith('/api/content/trending/')) {
      return http.Response(jsonEncode(_trendingJson), 200);
    }
    if (path == '/api/content/search/multi') {
      return http.Response(jsonEncode(_searchMultiJson), 200);
    }
    if (path == '/api/content/movie/1/credits') {
      return http.Response(jsonEncode(_creditsJson), 200);
    }
    if (path == '/api/content/search/person') {
      return http.Response(jsonEncode(_searchPersonJson), 200);
    }
    return http.Response('not found', 404);
  });
}

void main() {
  Future<void> pumpAtSize(WidgetTester tester, Size size) async {
    final client = _mockClient();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      MaterialApp(
        home: HomeSearchScreen(
          contentService: ContentService(
            apiClient: ApiClient(httpClient: client),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  testWidgets('Home search no overflow at design 390x844', (tester) async {
    await pumpAtSize(tester, const Size(390, 844));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home search no overflow at small phone 320x568', (tester) async {
    await pumpAtSize(tester, const Size(320, 568));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home search filters by query and category', (tester) async {
    await pumpAtSize(tester, const Size(390, 844));

    expect(find.text('Buscar'), findsOneWidget);
    expect(find.text('Artistas, Filmes, Séries ...'), findsOneWidget);

    expect(find.text('Tudo'), findsOneWidget);
    expect(find.text('Filmes'), findsOneWidget);
    expect(find.text('Séries'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home_search_settings_filter')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Escolha a categoria'), findsOneWidget);
    expect(find.text('Sci-Fi'), findsOneWidget);
    await tester.tap(find.text('Sci-Fi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Filmes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Grade'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Lista'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Dune');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Timoth\u00e9e Chalamet'), findsOneWidget);
    expect(find.text('Nenhum resultado encontrado'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}