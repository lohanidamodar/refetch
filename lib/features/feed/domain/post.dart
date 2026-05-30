import 'dart:convert';

/// A feed item (a submitted link or "show" post) as returned by the refetch.io
/// `/api/posts`, `/api/mines`, and `/api/posts/{id}` endpoints.
class Post {
  const Post({
    required this.id,
    required this.title,
    required this.domain,
    required this.count,
    required this.author,
    required this.countComments,
    this.timeAgo,
    this.description,
    this.tldr,
    this.userId,
    this.link,
    this.type,
    this.readingTime,
    this.currentVote,
  });

  final String id;
  final String title;
  final String domain;
  final int count;
  final String author;
  final int countComments;

  /// Pre-formatted "x hours ago" string from the API (field `daysAgo`).
  final String? timeAgo;
  final String? description;
  final String? tldr;
  final String? userId;
  final String? link;

  /// `'link'` or `'show'`.
  final String? type;
  final int? readingTime;

  /// `'up'`, `'down'`, or `null`. Only populated on auth-aware endpoints.
  final String? currentVote;

  bool get isShow => type == 'show';

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      title: (json['title'] ?? '') as String,
      domain: (json['domain'] ?? '') as String,
      count: _asInt(json['count']),
      author: (json['author'] ?? 'anonymous') as String,
      countComments: _asInt(json['countComments']),
      timeAgo: json['daysAgo'] as String?,
      description: json['description'] as String?,
      tldr: json['tldr'] as String?,
      userId: json['userId'] as String?,
      link: json['link'] as String?,
      type: json['type'] as String?,
      readingTime: json['readingTime'] == null
          ? null
          : _asInt(json['readingTime']),
      currentVote: json['currentVote'] as String?,
    );
  }

  static int _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  /// Parses a `{ "posts": [...] }` envelope (or a bare list) into [Post]s.
  static List<Post> listFromResponse(dynamic data) {
    final list = data is Map ? data['posts'] : data;
    if (list is! List) return const [];
    return list
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  String toString() => 'Post(${jsonEncode({'id': id, 'title': title})})';
}
