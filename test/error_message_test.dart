import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refetch/core/network/api_exception.dart';
import 'package:refetch/core/network/error_message.dart';

void main() {
  test('surfaces ApiException message', () {
    expect(messageForError(const ApiException(400, 'Bad input')), 'Bad input');
  });

  test('surfaces AppwriteException message (the real auth reason)', () {
    final error = AppwriteException(
      'Invalid credentials. Please check the email and password.',
      401,
      'user_invalid_credentials',
    );
    expect(
      messageForError(error, fallback: 'Sign in failed.'),
      'Invalid credentials. Please check the email and password.',
    );
  });

  test('uses fallback when AppwriteException has no message', () {
    expect(
      messageForError(AppwriteException(), fallback: 'Sign in failed.'),
      'Sign in failed.',
    );
  });

  test('uses fallback for unknown errors', () {
    expect(
      messageForError(Exception('x'), fallback: 'Nope'),
      'Nope',
    );
    expect(messageForError(null, fallback: 'Nope'), 'Nope');
  });

  test('uses fallback when ApiException message is blank', () {
    expect(messageForError(const ApiException(500, '   '), fallback: 'Oops'), 'Oops');
  });
}
