import 'dart:async';
import 'package:flash_learn_chinese/core/helper/shared_prefs_helper.dart';
import 'package:flash_learn_chinese/core/services/iap_service.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

enum SubscriptionStatus {
  initial,
  loadingProducts,
  loadedProducts,
  purchasePending,
  purchaseSuccess,
  purchaseError
}

const Set<String> _kProductIds = {'premium_package', 'standard_package'};

class SubscriptionController extends GetxController {
  final IAPService _iapService;

  SubscriptionController(this._iapService);

  final status = SubscriptionStatus.initial.obs;
  final products = <ProductDetails>[].obs;
  final errorMessage = RxnString();
  final selectedPackageIndex = 1.obs;
  final activeProductId = RxnString();
  final purchaseDate = Rxn<DateTime>();

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool get isPremium => activeProductId.value == 'premium_package';
  bool get isStandard =>
      activeProductId.value == 'standard_package' ||
      activeProductId.value == 'premium_package';

  bool isLevelUnlocked(int level) {
    if (isPremium) return true;
    if (isStandard) return level <= 3;
    return level == 1; // Free users get only HSK 1
  }

  bool isFeatureUnlocked(String featureKey) {
    if (isPremium) return true;
    // Premium features (AI Chat, HSK Exam with AI, AI Lessons) require premium
    return false;
  }

  int get remainingDays {
    if (purchaseDate.value == null || activeProductId.value == null) return 0;

    // Gói cao cấp: 1 năm (365 ngày), Gói tiêu chuẩn: 1 tháng (30 ngày)
    final durationDays = activeProductId.value == 'premium_package' ? 365 : 30;

    final expiryDate = purchaseDate.value!.add(Duration(days: durationDays));
    final diff = expiryDate.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
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
    _loadSubscriptionStatus();
    _initIAP();
  }

  Future<void> _loadSubscriptionStatus() async {
    final savedProductId = await SharedPrefsHelper.getActiveProductId();
    final savedDate = await SharedPrefsHelper.getPurchaseDate();
    if (savedProductId != null) {
      activeProductId.value = savedProductId;
      if (savedDate != null) {
        purchaseDate.value = savedDate;
      } else {
        purchaseDate.value = DateTime.now();
      }
    }
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
      // Revert to loaded state after showing error
      await Future.delayed(const Duration(seconds: 1));
      status.value = SubscriptionStatus.loadedProducts;
    }
  }

  Future<void> restorePurchases() async {
    status.value = SubscriptionStatus.purchasePending;
    try {
      await _iapService.restorePurchases();
    } catch (e) {
      errorMessage.value = e.toString();
      status.value = SubscriptionStatus.purchaseError;
      await Future.delayed(const Duration(seconds: 1));
      status.value = SubscriptionStatus.loadedProducts;
    }
  }

  DateTime _parseDate(String? transactionDate) {
    if (transactionDate == null) return DateTime.now();
    try {
      final milliseconds = int.parse(transactionDate);
      return DateTime.fromMillisecondsSinceEpoch(milliseconds);
    } catch (e) {
      return DateTime.now();
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        status.value = SubscriptionStatus.purchasePending;
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        errorMessage.value = purchaseDetails.error?.message ?? 'Lỗi thanh toán';
        status.value = SubscriptionStatus.purchaseError;
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        // Handle when user closes the payment dialog natively
        status.value = SubscriptionStatus.loadedProducts;
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        activeProductId.value = purchaseDetails.productID;
        final date = _parseDate(purchaseDetails.transactionDate);
        purchaseDate.value = date;
        status.value = SubscriptionStatus.purchaseSuccess;
        _saveSubscriptionStatus(purchaseDetails.productID, date);
      }
    }
  }

  Future<void> _saveSubscriptionStatus(String productId, DateTime date) async {
    await SharedPrefsHelper.saveSubscriptionStatus(productId, date);
  }

  @override
  void onClose() {
    _purchaseSubscription?.cancel();
    super.onClose();
  }
}
