import 'dart:async';
import 'dart:io' show Platform;
import 'package:flash_learn_chinese/core/services/iap_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/entitlement/service/premium_access_service.dart';

enum SubscriptionStatus {
  initial,
  loadingProducts,
  loadedProducts,
  purchasePending,
  purchaseVerifying,
  purchaseSuccess,
  purchaseError
}

const Set<String> _kProductIds = {'premium_package', 'standard_package'};

class SubscriptionController extends GetxController {
  SubscriptionController(
    this._iapService, {
    PremiumAccessService? premiumAccessService,
  }) : _premiumAccess = premiumAccessService ??
            (Get.isRegistered<PremiumAccessService>()
                ? Get.find<PremiumAccessService>()
                : null);

  final IAPService _iapService;
  final PremiumAccessService? _premiumAccess;

  final status = SubscriptionStatus.initial.obs;
  final products = <ProductDetails>[].obs;
  final errorMessage = RxnString();
  final selectedPackageIndex = 1.obs;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool get isPremium => _premiumAccess?.isPremium ?? false;
  bool get isStandard => _premiumAccess?.isStandard ?? false;

  String? get activeProductId =>
      _premiumAccess?.currentEntitlement.value?.productId;

  DateTime? get purchaseDate =>
      _premiumAccess?.currentEntitlement.value?.lastVerifiedAt;

  int get remainingDays => _premiumAccess?.remainingDays ?? 0;

  bool isLevelUnlocked(int level) {
    if (_premiumAccess != null) {
      return _premiumAccess.isLevelUnlocked(level);
    }
    return level == 1;
  }

  bool isFeatureUnlocked(String featureKey) {
    if (_premiumAccess != null) {
      return _premiumAccess.isFeatureUnlocked(featureKey);
    }
    return false;
  }

  ProductDetails? productFor(String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    _initIAP();
  }

  Future<void> _initIAP() async {
    // 1. Initialize connection
    await _iapService.initConnection();

    // 2. Listen to purchases stream
    _purchaseSubscription =
        _iapService.purchaseStream.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    });

    // 3. Fetch products from store
    await fetchStoreProducts();
  }

  Future<void> fetchStoreProducts() async {
    status.value = SubscriptionStatus.loadingProducts;
    try {
      final fetchedProducts = await _iapService.fetchProducts(_kProductIds);
      products.assignAll(fetchedProducts);
      status.value = SubscriptionStatus.loadedProducts;
    } catch (e) {
      errorMessage.value = e.toString();
      status.value = SubscriptionStatus.purchaseError;
    }
  }

  void selectPackage(int index) {
    selectedPackageIndex.value = index;
  }

  Future<void> subscribe(ProductDetails product) async {
    status.value = SubscriptionStatus.purchasePending;
    try {
      await _iapService.buyProduct(product);
      // The state will be updated via the purchase stream listener
    } catch (e) {
      errorMessage.value = e.toString();
      status.value = SubscriptionStatus.purchaseError;
      await Future.delayed(const Duration(seconds: 1));
      status.value = SubscriptionStatus.loadedProducts;
    }
  }

  Future<void> restorePurchases() async {
    status.value = SubscriptionStatus.purchaseVerifying;
    try {
      await _iapService.restorePurchases();
      if (_premiumAccess != null) {
        await _premiumAccess.reload();
      }
      status.value = SubscriptionStatus.purchaseSuccess;
    } catch (e) {
      errorMessage.value = e.toString();
      status.value = SubscriptionStatus.purchaseError;
      await Future.delayed(const Duration(seconds: 1));
      status.value = SubscriptionStatus.loadedProducts;
    }
  }

  void _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        status.value = SubscriptionStatus.purchasePending;
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        errorMessage.value = purchaseDetails.error?.message ?? 'Lỗi thanh toán';
        status.value = SubscriptionStatus.purchaseError;
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        status.value = SubscriptionStatus.loadedProducts;
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // PRODUCTION SECURITY: Server-Authoritative Verification
        status.value = SubscriptionStatus.purchaseVerifying;
        try {
          if (_premiumAccess != null) {
            String platform = 'android';
            try {
              if (Platform.isIOS) platform = 'ios';
            } catch (_) {}

            final transactionId = purchaseDetails.purchaseID ??
                purchaseDetails.verificationData.serverVerificationData;
            final token =
                purchaseDetails.verificationData.serverVerificationData;

            await _premiumAccess.verifyAndApplyPurchase(
              platform: platform,
              productId: purchaseDetails.productID,
              transactionId: transactionId,
              purchaseToken: token,
              rawPayload: {
                'transaction_date': purchaseDetails.transactionDate,
                'status': purchaseDetails.status.name,
              },
            );
          }
          status.value = SubscriptionStatus.purchaseSuccess;
        } catch (e) {
          debugPrint('Server purchase verification failed: $e');
          errorMessage.value = e.toString().replaceFirst('Exception: ', '');
          status.value = SubscriptionStatus.purchaseError;
        }
      }
    }
  }

  @override
  void onClose() {
    _purchaseSubscription?.cancel();
    super.onClose();
  }
}
