import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class IAPService {
  IAPService({InAppPurchase? inAppPurchase})
      : _inAppPurchaseInstance = inAppPurchase;

  InAppPurchase? _inAppPurchaseInstance;
  InAppPurchase get _inAppPurchase =>
      _inAppPurchaseInstance ??= InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Stream controller to broadcast purchase updates to Cubits/Blocs
  final _purchaseStreamController =
      StreamController<List<PurchaseDetails>>.broadcast();
  Stream<List<PurchaseDetails>> get purchaseStream =>
      _purchaseStreamController.stream;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  Future<void> initConnection() async {
    try {
      _isAvailable = await _inAppPurchase.isAvailable();
    } catch (e) {
      debugPrint('IAP is not available or mock environment: $e');
      _isAvailable = false;
      return;
    }

    if (_isAvailable) {
      final purchaseUpdated = _inAppPurchase.purchaseStream;
      _subscription = purchaseUpdated.listen(
        (purchaseDetailsList) {
          _purchaseStreamController.add(purchaseDetailsList);
          _handlePurchaseUpdates(purchaseDetailsList);
        },
        onDone: () {
          _subscription?.cancel();
        },
        onError: (error) {
          debugPrint('IAP Purchase Stream Error: $error');
        },
      );
    } else {
      debugPrint('IAP is not available on this device.');
    }
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Handled by UI/Cubit (showing loading indicator)
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('IAP Error: ${purchaseDetails.error}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          // Deliver product and verify receipt with server.
        }

        // Complete the purchase so that the store knows it was delivered.
        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<List<ProductDetails>> fetchProducts(Set<String> productIds) async {
    if (!_isAvailable) return [];

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(productIds);

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Products not found on store: ${response.notFoundIDs}');
    }

    if (response.error != null) {
      debugPrint('Error fetching products: ${response.error?.message}');
      return [];
    }

    return response.productDetails;
  }

  Future<void> buyProduct(ProductDetails product) async {
    if (!_isAvailable) throw Exception('Store is not available');

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    if (!_isAvailable) throw Exception('Store is not available');
    await _inAppPurchase.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
    _purchaseStreamController.close();
  }
}
