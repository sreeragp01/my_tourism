class User {
  final String id;
  final String email;
  final String? phone;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final List<String> roles;
  final bool isEmailVerified;
  final bool isPhoneVerified;

  const User({
    required this.id,
    required this.email,
    this.phone,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    this.roles = const ['CUSTOMER'],
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
  });

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isNotEmpty ? name : email.split('@').first;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      roles: (json['roles'] as List?)?.map((e) => e.toString()).toList() ?? const ['CUSTOMER'],
      isEmailVerified: json['is_email_verified'] == true,
      isPhoneVerified: json['is_phone_verified'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'phone': phone,
        'first_name': firstName,
        'last_name': lastName,
        'avatar_url': avatarUrl,
        'roles': roles,
        'is_email_verified': isEmailVerified,
        'is_phone_verified': isPhoneVerified,
      };
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final DateTime? refreshTokenExpiresAt;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.refreshTokenExpiresAt,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    DateTime? exp;
    if (json['refresh_token_expires_at'] != null) {
      try {
        exp = DateTime.parse(json['refresh_token_expires_at'].toString());
      } catch (_) {}
    }
    return AuthTokens(
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString() ?? '',
      refreshTokenExpiresAt: exp,
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'refresh_token_expires_at': refreshTokenExpiresAt?.toIso8601String(),
      };
}

class AuthResponse {
  final User user;
  final AuthTokens tokens;
  final Map<String, dynamic>? session;

  const AuthResponse({
    required this.user,
    required this.tokens,
    this.session,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    return AuthResponse(
      user: User.fromJson(data['user'] as Map<String, dynamic>),
      tokens: AuthTokens.fromJson(data['tokens'] as Map<String, dynamic>),
      session: data['session'] as Map<String, dynamic>?,
    );
  }
}
