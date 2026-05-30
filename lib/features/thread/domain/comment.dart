/// A comment on a post. The refetch.io `/api/comments` endpoint returns these
/// already nested via the `replies` field.
class Comment {
  const Comment({
    required this.id,
    required this.author,
    required this.text,
    required this.timeAgo,
    required this.count,
    required this.replies,
    required this.depth,
    this.userId,
    this.parentId,
  });

  final String id;
  final String author;
  final String text;
  final String timeAgo;
  final int count;
  final List<Comment> replies;
  final int depth;
  final String? userId;
  final String? parentId;

  factory Comment.fromJson(Map<String, dynamic> json) {
    final rawReplies = json['replies'];
    return Comment(
      id: json['id'] as String,
      author: (json['author'] ?? 'anonymous') as String,
      text: (json['text'] ?? '') as String,
      timeAgo: (json['timeAgo'] ?? '') as String,
      count: json['count'] is num ? (json['count'] as num).toInt() : 0,
      userId: json['userId'] as String?,
      parentId: json['parentId'] as String?,
      depth: json['depth'] is num ? (json['depth'] as num).toInt() : 0,
      replies: rawReplies is List
          ? rawReplies
                .map((e) => Comment.fromJson(e as Map<String, dynamic>))
                .toList(growable: false)
          : const [],
    );
  }

  static List<Comment> listFromResponse(dynamic data) {
    final list = data is Map ? data['comments'] : data;
    if (list is! List) return const [];
    return list
        .map((e) => Comment.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
