import 'package:flutter_test/flutter_test.dart';
import 'package:refetch/features/thread/domain/comment.dart';

void main() {
  test('Comment.fromJson parses nested replies recursively', () {
    final comment = Comment.fromJson({
      'id': 'root',
      'author': 'alice',
      'text': 'top level',
      'timeAgo': '1 hour ago',
      'count': 3,
      'depth': 0,
      'replies': [
        {
          'id': 'child',
          'author': 'bob',
          'text': 'a reply',
          'timeAgo': '30 minutes ago',
          'count': 1,
          'depth': 1,
          'parentId': 'root',
          'replies': const [],
        },
      ],
    });

    expect(comment.id, 'root');
    expect(comment.count, 3);
    expect(comment.replies, hasLength(1));
    expect(comment.replies.first.id, 'child');
    expect(comment.replies.first.parentId, 'root');
    expect(comment.replies.first.replies, isEmpty);
  });

  test('Comment.listFromResponse reads the {comments: [...]} envelope', () {
    final comments = Comment.listFromResponse({
      'comments': [
        {'id': '1', 'replies': const []},
      ],
    });
    expect(comments, hasLength(1));
    expect(comments.first.author, 'anonymous');
  });
}
