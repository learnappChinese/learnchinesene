import 'package:supabase_flutter/supabase_flutter.dart';

enum UserAuthStatus {
  initializing,
  guest,
  authenticating,
  authenticated,
  restoringSession,
  migratingGuestData,
  authError,
  signingOut,
}

class AppAuthUser {
  const AppAuthUser({
    required this.id,
    this.email,
    this.displayName,
    this.isGuest = false,
    this.createdAt,
  });

  final String id;
  final String? email;
  final String? displayName;
  final bool isGuest;
  final DateTime? createdAt;

  factory AppAuthUser.fromSupabaseUser(User user) {
    final meta = user.userMetadata ?? <String, dynamic>{};
    return AppAuthUser(
      id: user.id,
      email: user.email,
      displayName: meta['display_name'] as String? ??
          meta['full_name'] as String? ??
          user.email?.split('@').first,
      isGuest: false,
      createdAt: DateTime.tryParse(user.createdAt),
    );
  }

  factory AppAuthUser.guest({String? guestId}) {
    return AppAuthUser(
      id: guestId ?? 'guest',
      email: null,
      displayName: 'Khách lãng du',
      isGuest: true,
      createdAt: DateTime.now(),
    );
  }

  AppAuthUser copyWith({
    String? id,
    String? email,
    String? displayName,
    bool? isGuest,
    DateTime? createdAt,
  }) {
    return AppAuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isGuest: isGuest ?? this.isGuest,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'display_name': displayName,
        'is_guest': isGuest,
        'created_at': createdAt?.toIso8601String(),
      };
}
