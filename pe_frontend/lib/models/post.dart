class PostAuthor {
  final String id;
  final String email;
  final String displayName;
  final String avatarUrl;

  const PostAuthor({
    required this.id,
    required this.email,
    required this.displayName,
    required this.avatarUrl,
  });

  factory PostAuthor.fromJson(Map<String, dynamic> json) => PostAuthor(
    id: json['id'] as String? ?? '',
    email: json['email'] as String? ?? '',
    displayName: json['displayName'] as String? ?? 'User',
    avatarUrl: json['avatarUrl'] as String? ?? '',
  );
}

class PostReactionItem {
  final String type;
  final int count;

  const PostReactionItem({required this.type, required this.count});

  factory PostReactionItem.fromJson(Map<String, dynamic> json) =>
      PostReactionItem(
        type: json['type'] as String? ?? 'like',
        count: json['count'] as int? ?? 0,
      );
}

class PostReactionSummary {
  final int total;
  final String? myReaction;
  final List<PostReactionItem> items;

  const PostReactionSummary({
    required this.total,
    required this.myReaction,
    required this.items,
  });

  factory PostReactionSummary.fromJson(Map<String, dynamic> json) =>
      PostReactionSummary(
        total: json['total'] as int? ?? 0,
        myReaction: json['myReaction'] as String?,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => PostReactionItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PostComment {
  final String id;
  final String content;
  final String imageUrl;
  final DateTime createdAt;
  final PostAuthor author;
  final PostReactionSummary reactions;
  final List<PostComment> replies;

  const PostComment({
    required this.id,
    required this.content,
    required this.imageUrl,
    required this.createdAt,
    required this.author,
    required this.reactions,
    required this.replies,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) => PostComment(
    id: json['id'] as String? ?? '',
    content: json['content'] as String? ?? '',
    imageUrl: json['imageUrl'] as String? ?? '',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    author: PostAuthor.fromJson(
      (json['author'] as Map<String, dynamic>? ?? <String, dynamic>{}),
    ),
    reactions: PostReactionSummary.fromJson(
      (json['reactions'] as Map<String, dynamic>? ?? <String, dynamic>{}),
    ),
    replies: (json['replies'] as List<dynamic>? ?? [])
        .map((e) => PostComment.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class Post {
  final String id;
  final String content;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PostAuthor author;
  final List<PostComment> comments;
  final PostReactionSummary reactions;

  const Post({
    required this.id,
    required this.content,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
    required this.comments,
    required this.reactions,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    id: json['id'] as String? ?? '',
    content: json['content'] as String? ?? '',
    imageUrl: json['imageUrl'] as String? ?? '',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    author: PostAuthor.fromJson(
      (json['author'] as Map<String, dynamic>? ?? <String, dynamic>{}),
    ),
    comments: (json['comments'] as List<dynamic>? ?? [])
        .map((e) => PostComment.fromJson(e as Map<String, dynamic>))
        .toList(),
    reactions: PostReactionSummary.fromJson(
      (json['reactions'] as Map<String, dynamic>? ?? <String, dynamic>{}),
    ),
  );
}
