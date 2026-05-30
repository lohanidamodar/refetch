import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/thread_repository.dart';

/// Loads a single thread (post + nested comments) by post id.
///
/// Invalidate `threadProvider(postId)` after a comment mutation to refresh.
final threadProvider = FutureProvider.family<ThreadData, String>((
  ref,
  postId,
) async {
  return ref.read(threadRepositoryProvider).load(postId);
});
