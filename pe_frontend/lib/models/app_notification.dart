class NotificationActor {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? profilePicture;

  const NotificationActor({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.profilePicture,
  });

  String get displayName {
    final full = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return full.isNotEmpty ? full : email.split('@').first;
  }

  factory NotificationActor.fromJson(Map<String, dynamic> json) {
    return NotificationActor(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      profilePicture: json['profilePicture'] as String?,
    );
  }
}

class AppNotification {
  final String id;
  final String message;
  final String? type; // "comment", "postReaction", "commentReaction", "follow"
  final String? postId;
  final NotificationActor? actor;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.message,
    this.type,
    this.postId,
    this.actor,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    NotificationActor? actor;
    final actorRaw = json['profileNotifyId'];
    if (actorRaw is Map<String, dynamic>) {
      actor = NotificationActor.fromJson(actorRaw);
    }

    return AppNotification(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String?,
      postId: json['postId'] as String?,
      actor: actor,
      isRead: (json['isRead'] as num? ?? 0) != 0,
      createdAt: json['createAt'] != null
          ? DateTime.tryParse(json['createAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      message: message,
      type: type,
      postId: postId,
      actor: actor,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
