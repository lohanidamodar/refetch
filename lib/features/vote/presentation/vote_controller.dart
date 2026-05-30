import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/vote_repository.dart';
import '../domain/vote_state.dart';

/// Holds the live vote state for every resource currently on screen, keyed by
/// resource id.
///
/// Entries are seeded lazily: the UI falls back to a resource's own count when
/// no entry exists yet (see [VoteController.stateFor]). Voting applies an
/// optimistic update, then reconciles with the server response (or rolls back
/// on failure).
class VoteController extends Notifier<Map<String, VoteState>> {
  @override
  Map<String, VoteState> build() => const {};

  /// Seeds vote state for a batch of resources (e.g. after loading a feed page
  /// while signed in). Existing entries are overwritten with fresh data.
  void prime(Map<String, VoteState> votes) {
    if (votes.isEmpty) return;
    state = {...state, ...votes};
  }

  /// The known vote state for [resourceId], or [fallback] when none is tracked.
  VoteState stateFor(String resourceId, VoteState fallback) {
    return state[resourceId] ?? fallback;
  }

  Future<void> vote({
    required String resourceId,
    required String resourceType,
    required String voteType,
    required VoteState fallback,
  }) async {
    final previous = state[resourceId] ?? fallback;
    state = {...state, resourceId: _optimistic(previous, voteType)};

    try {
      final result = await ref
          .read(voteRepositoryProvider)
          .vote(
            resourceId: resourceId,
            resourceType: resourceType,
            voteType: voteType,
          );
      state = {...state, resourceId: result};
    } catch (_) {
      state = {...state, resourceId: previous};
      rethrow;
    }
  }

  /// Predicts the new vote state, matching the server's toggle semantics:
  /// clicking the active direction removes the vote; clicking the opposite
  /// direction flips it.
  VoteState _optimistic(VoteState current, String voteType) {
    final wasUp = current.isUp;
    final wasDown = current.isDown;
    var count = current.count;
    String? next;

    if (voteType == 'up') {
      if (wasUp) {
        count -= 1;
      } else if (wasDown) {
        count += 2;
        next = 'up';
      } else {
        count += 1;
        next = 'up';
      }
    } else {
      if (wasDown) {
        count += 1;
      } else if (wasUp) {
        count -= 2;
        next = 'down';
      } else {
        count -= 1;
        next = 'down';
      }
    }

    return VoteState(count: count, currentVote: next);
  }
}

final voteControllerProvider =
    NotifierProvider<VoteController, Map<String, VoteState>>(
      VoteController.new,
    );
