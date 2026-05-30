import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../appwrite/appwrite_providers.dart';

/// Mints and caches short-lived Appwrite JWTs used to authenticate calls to the
/// refetch.io REST API.
///
/// Mirrors the web client, which caches the JWT for 15 minutes before minting a
/// fresh one.
class JwtService {
  JwtService(this._account);

  final Account _account;
  static const Duration _ttl = Duration(minutes: 15);

  String? _cached;
  DateTime? _expiresAt;

  /// Returns a valid JWT, minting a new one when the cache is empty or expired.
  ///
  /// Returns `null` when no session exists (the user is signed out).
  Future<String?> getToken({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final cached = _cached;
    final expiry = _expiresAt;
    if (!forceRefresh &&
        cached != null &&
        expiry != null &&
        now.isBefore(expiry)) {
      return cached;
    }

    try {
      final jwt = await _account.createJWT();
      _cached = jwt.jwt;
      _expiresAt = now.add(_ttl);
      return _cached;
    } on AppwriteException {
      clear();
      return null;
    }
  }

  /// Drops the cached token (on sign-in/out, or after a 401).
  void clear() {
    _cached = null;
    _expiresAt = null;
  }
}

final jwtServiceProvider = Provider<JwtService>((ref) {
  return JwtService(ref.watch(accountProvider));
});
