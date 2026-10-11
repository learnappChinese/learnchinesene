import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../auth/controller/auth_controller.dart';
import '../data/entitlement_repository.dart';
import '../model/user_entitlement.dart';

/// Single authoritative service for Premium & Entitlement access.
///
/// Features:
/// 1. Backed by Supabase authoritative database & server RPC.
/// 2. Automatically updates when AuthController user logs in, logs out, or switches account.
/// 3. Never leaks cached premium state from Account A to Account B or Guest.
/// 4. Provides reactive state for all feature gates (HSK levels, AI features).
class PremiumAccessService extends GetxService {
  PremiumAccessService({
    required EntitlementRepository repository,
    AuthController? authController,
  })  : _repository = repository,
        _authController = authController;

  final EntitlementRepository _repository;
  final AuthController? _authController;

  final currentEntitlement = Rxn<UserEntitlement>();
  final status = EntitlementStatus.free.obs;
  final isLoading = false.obs;

  StreamSubscription? _authSubscription;

  bool get isPremium => currentEntitlement.value?.isPremium ?? false;
  bool get isStandard => currentEntitlement.value?.isStandard ?? false;

  int get remainingDays => currentEntitlement.value?.remainingDays ?? 0;

  bool isLevelUnlocked(int level) {
    if (isPremium) return true;
    if (isStandard) return level <= 3;
    return level == 1; // Free users get only HSK 1
  }

  bool isFeatureUnlocked(String featureKey) {
    if (isPremium) return true;
    return false;
  }

  @override
  void onInit() {
    super.onInit();
    final auth = _authController ??
        (Get.isRegistered<AuthController>()
            ? Get.find<AuthController>()
            : null);
    if (auth != null) {
      _listenToAuthChanges(auth);
    }
  }

  void _listenToAuthChanges(AuthController auth) {
    // Refresh entitlement on initialization and when user changes
    _refreshForUser(auth.currentUser.value?.id);

    _authSubscription = auth.currentUser.listen((user) {
      _refreshForUser(user?.id);
    });
  }

  Future<void> _refreshForUser(String? userId) async {
    if (userId == null || userId.isEmpty) {
      // Guest or logged out: revert to clean Free entitlement
      currentEntitlement.value = null;
      status.value = EntitlementStatus.free;
      return;
    }

    isLoading.value = true;
    try {
      final entitlement = await _repository.fetchActiveEntitlement(userId);
      currentEntitlement.value = entitlement;
      if (entitlement != null && entitlement.isActive) {
        status.value = entitlement.status;
      } else {
        status.value = EntitlementStatus.free;
      }
    } catch (e) {
      debugPrint('Error refreshing entitlement for user $userId: $e');
      status.value = EntitlementStatus.free;
    } finally {
      isLoading.value = false;
    }
  }

  /// Manually force reload current user's entitlement
  Future<void> reload() async {
    final auth = _authController ??
        (Get.isRegistered<AuthController>()
            ? Get.find<AuthController>()
            : null);
    await _refreshForUser(auth?.currentUser.value?.id);
  }

  /// Verify and apply a purchase from Google Play or Apple App Store
  Future<UserEntitlement> verifyAndApplyPurchase({
    required String platform,
    required String productId,
    required String transactionId,
    required String purchaseToken,
    Map<String, dynamic>? rawPayload,
  }) async {
    status.value = EntitlementStatus.verifying;
    try {
      final verified = await _repository.verifyPurchase(
        platform: platform,
        productId: productId,
        transactionId: transactionId,
        purchaseToken: purchaseToken,
        rawPayload: rawPayload,
      );

      currentEntitlement.value = verified;
      status.value = verified.status;
      return verified;
    } catch (e) {
      status.value = EntitlementStatus.error;
      rethrow;
    }
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }
}
