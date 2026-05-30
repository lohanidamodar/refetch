import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

/// Submits new posts (links or "show" posts) via the refetch.io REST API.
class SubmitRepository {
  SubmitRepository(this._api);

  final ApiClient _api;

  Future<void> submit({
    required String title,
    required String type,
    String? url,
    String? description,
  }) async {
    await _api.post(
      '/api/submit',
      body: {
        'title': title,
        'type': type,
        if (url != null && url.isNotEmpty) 'url': url,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
  }
}

final submitRepositoryProvider = Provider<SubmitRepository>((ref) {
  return SubmitRepository(ref.watch(apiClientProvider));
});
