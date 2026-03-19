class User {
  final String id;
  final String email;
  final String coins;
  final String roleName;
  final bool isActive;
  final String dateOfBirth;
  final int followCounts;
  final int followerCount;
  final String lastLogin;
  final String createdAt;

  const User({
    required this.id,
    required this.email,
    required this.coins,
    required this.roleName,
    required this.isActive,
    required this.dateOfBirth,
    required this.followCounts,
    required this.followerCount,
    required this.lastLogin,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final roleId = json['roleID'];
    final roleName = roleId is Map ? (roleId['name'] as String? ?? '') : '';
    return User(
      id: json['_id'] as String,
      email: json['email'] as String,
      coins: json['coins']?.toString() ?? '0',
      roleName: roleName,
      isActive: json['isActive'] as bool? ?? false,
      dateOfBirth: json['dateOfBirth'] as String? ?? '',
      followCounts: json['followCounts'] as int? ?? 0,
      followerCount: json['followerCount'] as int? ?? 0,
      lastLogin: json['lastLogin'] as String? ?? '',
      createdAt: json['CreateAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'email': email,
        'coins': coins,
        'roleName': roleName,
        'isActive': isActive,
        'dateOfBirth': dateOfBirth,
        'followCounts': followCounts,
        'followerCount': followerCount,
        'lastLogin': lastLogin,
        'CreateAt': createdAt,
      };
}
