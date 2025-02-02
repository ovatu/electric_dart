import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:electricsql/src/auth/insecure.dart';
import 'package:test/test.dart';

void main() {
  test('insecureAuthToken generates expected token', () async {
    final token = insecureAuthToken({'sub': 'dummy-user'});

    final claims = JWT.decode(token).payload as Map<String, Object?>;
    expect(claims, {'sub': 'dummy-user'});
  });

  test('insecureAuthToken supports non-latin characters', () async {
    final token = insecureAuthToken({'sub': '⚡'});

    final claims = JWT.decode(token).payload as Map<String, Object?>;
    expect(claims, {'sub': '⚡'});
  });
}
