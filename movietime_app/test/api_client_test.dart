import 'package:appflutter/services/api_client.dart';
import 'package:appflutter/services/auth_service.dart';
import 'package:appflutter/services/content_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('AuthService envia login para API do spotflix', () async {
    final service = AuthService(
      apiClient: ApiClient(
        baseUrl: 'https://spotflix.test',
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          expect(
            request.url.toString(),
            'https://spotflix.test/api/auth/login',
          );
          expect(request.body, contains('"email":"user@test.com"'));

          return http.Response(
            '{"user":{"id":1,"email":"user@test.com","name":"User","role":"client","avatarUrl":null,"preferences":null}}',
            200,
          );
        }),
      ),
    );

    final user = await service.login(
      email: 'user@test.com',
      password: 'secret',
    );

    expect(user.id, 1);
    expect(user.name, 'User');
  });

  test('ContentService le watchlist', () async {
    final service = ContentService(
      apiClient: ApiClient(
        baseUrl: 'https://spotflix.test',
        httpClient: MockClient((request) async {
          expect(request.method, 'GET');
          expect(
            request.url.toString(),
            'https://spotflix.test/api/watchlist?userId=7',
          );

          return http.Response(
            '{"items":[{"tmdb_id":123,"media_type":"movie","title":"Movie","poster_url":"poster.png","backdrop_url":null}]}',
            200,
          );
        }),
      ),
    );

    final items = await service.watchlist(7);

    expect(items, hasLength(1));
    expect(items.single.tmdbId, 123);
    expect(items.single.title, 'Movie');
  });

  test('ApiClient transforma erro JSON em ApiException', () async {
    final client = ApiClient(
      baseUrl: 'https://spotflix.test',
      httpClient: MockClient(
        (_) async => http.Response('{"error":"Falhou"}', 400),
      ),
    );

    expect(
      () => client.getJson('/api/auth/profile'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 400)
            .having((error) => error.message, 'message', 'Falhou'),
      ),
    );
  });
}
