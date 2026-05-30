import 'package:flutter_test/flutter_test.dart';
import 'package:refetch/features/feed/domain/post.dart';

void main() {
  group('Post.fromJson', () {
    test('parses a full feed item', () {
      final post = Post.fromJson({
        'id': 'abc',
        'title': 'Hello',
        'domain': 'example.com',
        'count': 42,
        'author': 'jane',
        'countComments': 7,
        'daysAgo': '2 hours ago',
        'link': 'https://example.com/x',
        'type': 'link',
        'readingTime': 5,
        'currentVote': 'up',
      });

      expect(post.id, 'abc');
      expect(post.title, 'Hello');
      expect(post.count, 42);
      expect(post.countComments, 7);
      expect(post.timeAgo, '2 hours ago');
      expect(post.readingTime, 5);
      expect(post.currentVote, 'up');
      expect(post.isShow, isFalse);
    });

    test('applies sensible defaults for missing fields', () {
      final post = Post.fromJson({'id': 'only-id'});
      expect(post.title, '');
      expect(post.count, 0);
      expect(post.countComments, 0);
      expect(post.author, 'anonymous');
      expect(post.readingTime, isNull);
      expect(post.currentVote, isNull);
    });

    test('coerces numeric strings/doubles to int', () {
      final post = Post.fromJson({'id': 'x', 'count': 3.0, 'countComments': 2});
      expect(post.count, 3);
      expect(post.countComments, 2);
    });
  });

  group('Post.listFromResponse', () {
    test('reads the {posts: [...]} envelope', () {
      final posts = Post.listFromResponse({
        'posts': [
          {'id': '1', 'title': 'a'},
          {'id': '2', 'title': 'b'},
        ],
      });
      expect(posts, hasLength(2));
      expect(posts.first.id, '1');
    });

    test('returns empty for unexpected shapes', () {
      expect(Post.listFromResponse(null), isEmpty);
      expect(Post.listFromResponse({'nope': true}), isEmpty);
    });
  });
}
