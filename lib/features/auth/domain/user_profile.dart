class UserProfile {
  final String id;
  final String? displayName;
  final String? avatarUrl;

  /// The email address of the account, when the provider exposes one.
  final String? email;

  /// The identity provider the account was created with (`email`, `google`).
  final String authProvider;

  /// Whether the email address has been confirmed by the backend.
  final bool emailVerified;

  final String preferredCurrency;
  final String locale;
  final String themePreference;
  final int weekStartsOn;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    this.displayName,
    this.avatarUrl,
    this.email,
    this.authProvider = 'email',
    this.emailVerified = false,
    this.preferredCurrency = 'USD',
    this.locale = 'en_US',
    this.themePreference = 'system',
    this.weekStartsOn = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? avatarUrl,
    String? email,
    String? authProvider,
    bool? emailVerified,
    String? preferredCurrency,
    String? locale,
    String? themePreference,
    int? weekStartsOn,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      email: email ?? this.email,
      authProvider: authProvider ?? this.authProvider,
      emailVerified: emailVerified ?? this.emailVerified,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      locale: locale ?? this.locale,
      themePreference: themePreference ?? this.themePreference,
      weekStartsOn: weekStartsOn ?? this.weekStartsOn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'email': email,
        'auth_provider': authProvider,
        'email_verified': emailVerified,
        'preferred_currency': preferredCurrency,
        'locale': locale,
        'theme_preference': themePreference,
        'week_starts_on': weekStartsOn,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      email: json['email'] as String?,
      authProvider: json['auth_provider'] as String? ?? 'email',
      emailVerified: json['email_verified'] as bool? ?? false,
      preferredCurrency: json['preferred_currency'] as String? ?? 'USD',
      locale: json['locale'] as String? ?? 'en_US',
      themePreference: json['theme_preference'] as String? ?? 'system',
      weekStartsOn: (json['week_starts_on'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
