class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
    this.preferences,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'client',
      avatarUrl: json['avatarUrl']?.toString(),
      preferences: json['preferences'] is Map<String, dynamic>
          ? UserPreferences.fromJson(
              json['preferences'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  final int id;
  final String email;
  final String name;
  final String role;
  final String? avatarUrl;
  final UserPreferences? preferences;
}

class UserPreferences {
  const UserPreferences({
    this.avatarIndex,
    this.genres = const [],
    this.recommendationsUpdatedAt,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      avatarIndex: json['avatarIndex'] as int?,
      genres: switch (json['genres']) {
        final List<dynamic> value => value.map((item) => '$item').toList(),
        _ => const [],
      },
      recommendationsUpdatedAt: json['recommendationsUpdatedAt']?.toString(),
    );
  }

  final int? avatarIndex;
  final List<String> genres;
  final String? recommendationsUpdatedAt;
}
