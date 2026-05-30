import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:refetch/core/auth/jwt_service.dart';

class _MockAccount extends Mock implements Account {}

models.Jwt _jwt(String value) => models.Jwt(jwt: value);

void main() {
  late _MockAccount account;
  late JwtService service;

  setUp(() {
    account = _MockAccount();
    service = JwtService(account);
  });

  test('caches the token across calls within the TTL', () async {
    when(() => account.createJWT()).thenAnswer((_) async => _jwt('token-1'));

    final first = await service.getToken();
    final second = await service.getToken();

    expect(first, 'token-1');
    expect(second, 'token-1');
    verify(() => account.createJWT()).called(1);
  });

  test('forceRefresh mints a new token', () async {
    var calls = 0;
    when(() => account.createJWT()).thenAnswer((_) async {
      calls++;
      return _jwt('token-$calls');
    });

    expect(await service.getToken(), 'token-1');
    expect(await service.getToken(forceRefresh: true), 'token-2');
    verify(() => account.createJWT()).called(2);
  });

  test('returns null and stays uncached when there is no session', () async {
    when(() => account.createJWT()).thenThrow(AppwriteException('no session'));

    expect(await service.getToken(), isNull);

    // Next call retries (cache was cleared), still null.
    when(() => account.createJWT()).thenAnswer((_) async => _jwt('back'));
    expect(await service.getToken(), 'back');
  });

  test('clear drops the cached token', () async {
    when(() => account.createJWT()).thenAnswer((_) async => _jwt('token'));
    await service.getToken();

    service.clear();
    await service.getToken();

    verify(() => account.createJWT()).called(2);
  });
}
