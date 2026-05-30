import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/appwrite/appwrite_providers.dart';
import '../../../core/auth/jwt_service.dart';
import '../domain/app_user.dart';

/// Authentication backed by the Appwrite Account API (sessions + JWT), mirroring
/// the refetch.io web client.
class AuthRepository {
  AuthRepository(this._account, this._jwt);

  final Account _account;
  final JwtService _jwt;

  /// The currently signed-in user, or `null` when there is no active session.
  Future<AppUser?> currentUser() async {
    try {
      return AppUser.fromAccount(await _account.get());
    } on AppwriteException {
      return null;
    }
  }

  Future<AppUser> signIn(String email, String password) async {
    await _account.createEmailPasswordSession(email: email, password: password);
    _jwt.clear();
    return AppUser.fromAccount(await _account.get());
  }

  Future<AppUser> signUp(String name, String email, String password) async {
    await _account.create(
      userId: ID.unique(),
      email: email,
      password: password,
      name: name,
    );
    await _account.createEmailPasswordSession(email: email, password: password);
    _jwt.clear();
    return AppUser.fromAccount(await _account.get());
  }

  Future<void> signOut() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } on AppwriteException {
      // Session already gone — treat as success.
    }
    _jwt.clear();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(accountProvider),
    ref.watch(jwtServiceProvider),
  );
});
