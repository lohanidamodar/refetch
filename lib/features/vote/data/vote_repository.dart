import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/vote_state.dart';

/// A resource to look up a vote for: a post or a comment.
typedef VoteResource = ({String id, String type});

/// Casts votes and reads vote state via the refetch.io REST API.
class VoteRepository {
  VoteRepository(this._api);

  final ApiClient _api;

  /// Casts (or toggles off) a vote. The server returns the resulting score and
  /// the user's resulting vote direction (`null` if the vote was removed).
  Future<VoteState> vote({
    required String resourceId,
    required String resourceType,
    required String voteType,
  }) async {
    final data =
        await _api.post(
              '/api/vote',
              body: {
                'resourceId': resourceId,
                'resourceType': resourceType,
                'voteType': voteType,
              },
            )
            as Map<String, dynamic>;

    return VoteState(
      count: data['newScore'] is num ? (data['newScore'] as num).toInt() : 0,
      currentVote: data['voteType'] as String?,
    );
  }

  /// Fetches the user's vote state for many resources at once.
  Future<Map<String, VoteState>> batch(List<VoteResource> resources) async {
    if (resources.isEmpty) return const {};

    final data =
        await _api.post(
              '/api/vote/batch',
              body: {
                'resources': resources
                    .map((r) => {'id': r.id, 'type': r.type})
                    .toList(),
              },
            )
            as Map<String, dynamic>;

    final voteMap = data['voteMap'];
    if (voteMap is! Map) return const {};

    return voteMap.map(
      (key, value) => MapEntry(
        key as String,
        VoteState.fromJson(value as Map<String, dynamic>),
      ),
    );
  }
}

final voteRepositoryProvider = Provider<VoteRepository>((ref) {
  return VoteRepository(ref.watch(apiClientProvider));
});
