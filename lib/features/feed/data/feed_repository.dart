import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/post.dart';

/// The four feed views, matching the web app's tabs.
enum FeedTab {
  top('Top'),
  latest('New'),
  show('Show'),
  mines('Mines');

  const FeedTab(this.label);

  /// Title shown in the tab bar.
  final String label;

  /// Whether this tab requires an authenticated user.
  bool get requiresAuth => this == FeedTab.mines;

  /// `sortType` query value for `/api/posts` (null for the auth-gated Mines tab,
  /// which uses a dedicated endpoint).
  String? get sortType => switch (this) {
    FeedTab.top => 'score',
    FeedTab.latest => 'new',
    FeedTab.show => 'show',
    FeedTab.mines => null,
  };
}

/// Reads paginated feed pages from the refetch.io REST API.
class FeedRepository {
  FeedRepository(this._api);

  final ApiClient _api;

  Future<List<Post>> fetch(
    FeedTab tab, {
    required int limit,
    required int offset,
  }) async {
    final query = {'limit': '$limit', 'offset': '$offset'};

    if (tab == FeedTab.mines) {
      final data = await _api.get('/api/mines', query: query, auth: true);
      return Post.listFromResponse(data);
    }

    final data = await _api.get(
      '/api/posts',
      query: {'sortType': tab.sortType!, ...query},
    );
    return Post.listFromResponse(data);
  }
}

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(ref.watch(apiClientProvider));
});
