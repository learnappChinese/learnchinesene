enum EntitlementStatus {
  free,
  purchasing,
  pending,
  verifying,
  active,
  gracePeriod,
  expired,
  revoked,
  error;

  static EntitlementStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return EntitlementStatus.active;
      case 'grace_period':
        return EntitlementStatus.gracePeriod;
      case 'expired':
        return EntitlementStatus.expired;
      case 'revoked':
        return EntitlementStatus.revoked;
      case 'pending':
        return EntitlementStatus.pending;
      case 'verifying':
        return EntitlementStatus.verifying;
      case 'purchasing':
        return EntitlementStatus.purchasing;
      case 'error':
        return EntitlementStatus.error;
      default:
        return EntitlementStatus.free;
    }
  }

  String toDbString() {
    switch (this) {
      case EntitlementStatus.active:
        return 'active';
      case EntitlementStatus.gracePeriod:
        return 'grace_period';
      case EntitlementStatus.expired:
        return 'expired';
      case EntitlementStatus.revoked:
        return 'revoked';
      case EntitlementStatus.pending:
        return 'pending';
      default:
        return 'free';
    }
  }
}

class UserEntitlement {
  const UserEntitlement({
    required this.userId,
    required this.productId,
    required this.platform,
    required this.originalTransactionId,
    required this.status,
    this.expiresAt,
    this.lastVerifiedAt,
    this.rawPayload = const {},
  });

  final String userId;
  final String productId;
  final String platform;
  final String originalTransactionId;
  final EntitlementStatus status;
  final DateTime? expiresAt;
  final DateTime? lastVerifiedAt;
  final Map<String, dynamic> rawPayload;

  bool get isActive {
    if (status != EntitlementStatus.active &&
        status != EntitlementStatus.gracePeriod) {
      return false;
    }
    if (expiresAt != null && expiresAt!.isBefore(DateTime.now())) {
      return false;
    }
    return true;
  }

  bool get isExpired =>
      status == EntitlementStatus.expired ||
      (expiresAt != null && expiresAt!.isBefore(DateTime.now()));

  bool get isPremium => isActive && productId == 'premium_package';
  bool get isStandard =>
      isActive &&
      (productId == 'standard_package' || productId == 'premium_package');

  int get remainingDays {
    if (expiresAt == null) return 0;
    final diff = expiresAt!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  factory UserEntitlement.fromJson(Map<String, dynamic> json) {
    return UserEntitlement(
      userId: json['user_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      platform: json['platform']?.toString() ?? 'android',
      originalTransactionId: json['original_transaction_id']?.toString() ?? '',
      status: EntitlementStatus.fromString(json['status']?.toString()),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
      lastVerifiedAt: json['last_verified_at'] != null
          ? DateTime.tryParse(json['last_verified_at'].toString())
          : null,
      rawPayload: json['raw_payload'] is Map<String, dynamic>
          ? json['raw_payload'] as Map<String, dynamic>
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'product_id': productId,
      'platform': platform,
      'original_transaction_id': originalTransactionId,
      'status': status.toDbString(),
      'expires_at': expiresAt?.toIso8601String(),
      'last_verified_at': lastVerifiedAt?.toIso8601String(),
      'raw_payload': rawPayload,
    };
  }

  static UserEntitlement free(String userId) {
    return UserEntitlement(
      userId: userId,
      productId: '',
      platform: 'manual',
      originalTransactionId: '',
      status: EntitlementStatus.free,
    );
  }
}
