import 'dart:convert';

import 'package:appflutter/screens/mylist.dart';
import 'package:appflutter/services/api_client.dart';
import 'package:appflutter/services/auth_service.dart';
import 'package:appflutter/services/content_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _trendingJson = {
  'results': [
    {
      'id': 119051,
      'name': 'Grey\'s Anatomy',
      'first_air_date': '2005-03-27',
      'poster_path': '/daSFAm3U5JmjG9HtZ9HfNtNpQBq.jpg',
      'backdrop_path': '/mwn0gH4rx8A0pXlOVKr3Zf5yXWM.jpg',
    },
    {
      'id': 1396,
      'name': 'Breaking Bad',
      'first_air_date': '2008-01-20',
      'poster_path': '/ztkUQFLlC19CCMYHWcqoH9rR6ld.jpg',
      'backdrop_path': '/3nI4wRM9flULAQBFKVtMxYVzsud.jpg',
    },
    {
      'id': 60735,
      'name': 'The Flash',
      'first_air_date': '2014-10-07',
      'poster_path': '/lJA2RCMfsWoskdQIOFv0Ah95uDw.jpg',
      'backdrop_path': '/7GDiMq2wjCv6C0vyZfPz0v4yH6R.jpg',
    },
  ],
};

MockClient _mockClient() {
  return MockClient((request) async {
    final path = request.url.path;
    if (path == '/api/auth/profile') {
      return http.Response(
        jsonEncode({
          'user': {
            'id': 1,
            'email': 'a@b.c',
            'name': 'Teste',
            'role': 'client',
            'listName': 'Minha lista',
          },
        }),
        200,
      );
    }
    if (path == '/api/watchlist' || path == '/api/watch-history') {
      return http.Response(
        jsonEncode({
          'listName': 'Minha lista',
          'items': [
            for (var i = 1; i <= 3; i++)
              {
                'tmdb_id': 100 + i,
                'media_type': 'tv',
                'title': 'Série Teste $i',
                'poster_url': '/poster$i.jpg',
              },
          ],
        }),
        200,
      );
    }
    if (path.startsWith('/api/content/')) {
      return http.Response(jsonEncode(_trendingJson), 200);
    }
    return http.Response('not found', 404);
  });
}

void main() {
  Future<void> pumpAtSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(const MaterialApp(home: MyListScreen()));
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> pumpAtSizeWithData(WidgetTester tester, Size size) async {
    final client = _mockClient();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      MaterialApp(
        home: MyListScreen(
          authService: AuthService(apiClient: ApiClient(httpClient: client)),
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

  testWidgets('MyList no overflow at design 390x844', (tester) async {
    await pumpAtSize(tester, const Size(390, 844));
    expect(tester.takeException(), isNull);
  });

  testWidgets('MyList no overflow at small phone 320x568', (tester) async {
    await pumpAtSize(tester, const Size(320, 568));
    expect(tester.takeException(), isNull);
  });

  testWidgets('MyList no overflow at large phone 412x915', (tester) async {
    await pumpAtSize(tester, const Size(412, 915));
    expect(tester.takeException(), isNull);
  });

  testWidgets('MyList with featured carousel no overflow at design 390x844',
      (tester) async {
    await pumpAtSizeWithData(tester, const Size(390, 844));
    expect(tester.takeException(), isNull);
  });

  testWidgets('MyList with featured carousel no overflow at small 320x568',
      (tester) async {
    await pumpAtSizeWithData(tester, const Size(320, 568));
    expect(tester.takeException(), isNull);
  });

  testWidgets('MyList with featured carousel no overflow at large 412x915',
      (tester) async {
    await pumpAtSizeWithData(tester, const Size(412, 915));
    expect(tester.takeException(), isNull);
  });
}