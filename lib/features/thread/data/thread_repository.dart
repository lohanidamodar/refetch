import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../feed/domain/post.dart';
import '../domain/comment.dart';

/// A post together with its (nested) comment tree.
class ThreadData {
  const ThreadData({required this.post, required this.comments});

  final Post post;
  final List<Comment> comments;
}

/// Reads a single thread and performs comment mutations against refetch.io.
class ThreadRepository {
  ThreadRepository(this._api);

  final ApiClient _api;

  /// Loads the post header and its nested comments concurrently.
  Future<ThreadData> load(String postId) async {
    final results = await Future.wait([
      _api.get('/api/posts/$postId'),
      _api.get('/api/comments', query: {'postId': postId}),
    ]);

    final postEnvelope = results[0] as Map<String, dynamic>;
    final post = Post.fromJson(postEnvelope['post'] as Map<String, dynamic>);
    final comments = Comment.listFromResponse(results[1]);

    return ThreadData(post: post, comments: comments);
  }

  Future<void> addComment({
    required String postId,
    required String text,
    required String userName,
    String? replyId,
  }) async {
    await _api.post(
      '/api/comments',
      body: {
        'postId': postId,
        'text': text,
        'userName': userName,
        'replyId': ?replyId,
      },
    );
  }

  Future<void> deleteComment(String commentId) async {
    await _api.delete('/api/comments/$commentId');
  }
}

final threadRepositoryProvider = Provider<ThreadRepository>((ref) {
  return ThreadRepository(ref.watch(apiClientProvider));
});
