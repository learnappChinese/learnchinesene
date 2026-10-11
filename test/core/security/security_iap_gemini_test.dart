import 'dart:convert';
import 'package:flash_learn_chinese/core/ai/model/ai_gateway_exception.dart';
import 'package:flash_learn_chinese/core/entitlement/data/entitlement_repository.dart';
import 'package:flash_learn_chinese/core/entitlement/model/user_entitlement.dart';
import 'package:flash_learn_chinese/core/entitlement/service/premium_access_service.dart';
import 'package:flash_learn_chinese/core/services/gemini_service.dart';
import 'package:flash_learn_chinese/core/services/iap_service.dart';
import 'package:flash_learn_chinese/screen/subscription/controller/subscription_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class FakeEntitlementRepository implements EntitlementRepository {
  final Map<String, UserEntitlement> entitlementsByUser = {};
  bool throwOnVerify = false;
  String? verifyError;

  @override
  Future<UserEntitlement?> fetchActiveEntitlement(String userId) async {
    return entitlementsByUser[userId];
  }

  @override
  Future<UserEntitlement> verifyPurchase({
    required String platform,
    required String productId,
    required String transactionId,
    required String purchaseToken,
    Map<String, dynamic>? rawPayload,
  }) async {
    if (throwOnVerify) {
      throw Exception(verifyError ?? 'verification_failed');
    }

    final entitlement = UserEntitlement(
      userId: 'test-user',
      productId: productId,
      platform: platform,
      originalTransactionId: transactionId,
      status: EntitlementStatus.active,
      expiresAt: DateTime.now().add(const Duration(days: 365)),
      lastVerifiedAt: DateTime.now(),
    );
    entitlementsByUser['test-user'] = entitlement;
    return entitlement;
  }
}

class FakeIAPService extends IAPService {
  final _controller = GetStream<List<PurchaseDetails>>();

  @override
  bool get isAvailable => true;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<void> initConnection() async {}

  @override
  Future<List<ProductDetails>> fetchProducts(Set<String> productIds) async {
    return [
      ProductDetails(
        id: 'premium_package',
        title: 'Gói Cao Cấp',
        description: 'Mở khóa toàn bộ',
        price: '299.000 đ',
        rawPrice: 299000,
        currencyCode: 'VND',
      ),
      ProductDetails(
        id: 'standard_package',
        title: 'Gói Tiêu Chuẩn',
        description: 'Mở khóa cơ bản',
        price: '69.000 đ',
        rawPrice: 69000,
        currencyCode: 'VND',
      ),
    ];
  }

  void emitPurchase(PurchaseDetails details) {
    _controller.add([details]);
  }
}

class FakePurchaseDetails extends PurchaseDetails {
  FakePurchaseDetails({
    required super.productID,
    required super.status,
    String? purchaseID,
  }) : super(
          purchaseID: purchaseID ?? 'trans_123',
          verificationData: PurchaseVerificationData(
            localVerificationData: 'local_token',
            serverVerificationData: 'server_token',
            source: 'google_play',
          ),
          transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
        );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PR 05 — Entitlement Models & Policies', () {
    test('UserEntitlement evaluates active, premium, and standard correctly',
        () {
      final activePremium = UserEntitlement(
        userId: 'u1',
        productId: 'premium_package',
        platform: 'android',
        originalTransactionId: 'tx1',
        status: EntitlementStatus.active,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      expect(activePremium.isActive, isTrue);
      expect(activePremium.isPremium, isTrue);
      expect(activePremium.isStandard, isTrue);
      expect(activePremium.remainingDays, greaterThan(0));

      final activeStandard = UserEntitlement(
        userId: 'u1',
        productId: 'standard_package',
        platform: 'android',
        originalTransactionId: 'tx2',
        status: EntitlementStatus.active,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      expect(activeStandard.isActive, isTrue);
      expect(activeStandard.isPremium, isFalse);
      expect(activeStandard.isStandard, isTrue);

      final expired = UserEntitlement(
        userId: 'u1',
        productId: 'premium_package',
        platform: 'android',
        originalTransactionId: 'tx3',
        status: EntitlementStatus.expired,
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(expired.isActive, isFalse);
      expect(expired.isPremium, isFalse);
      expect(expired.remainingDays, equals(0));
    });

    test('UserEntitlement.free creates clean free state', () {
      final free = UserEntitlement.free('guest_user');
      expect(free.isActive, isFalse);
      expect(free.isPremium, isFalse);
      expect(free.status, equals(EntitlementStatus.free));
    });
  });

  group('PR 05 — PremiumAccessService & Account Switching', () {
    late FakeEntitlementRepository repo;
    late PremiumAccessService service;

    setUp(() {
      repo = FakeEntitlementRepository();
      service = PremiumAccessService(repository: repo);
    });

    test('Initializes with free entitlement for unauthenticated user', () {
      expect(service.isPremium, isFalse);
      expect(service.isStandard, isFalse);
      expect(service.status.value, equals(EntitlementStatus.free));
      expect(service.isLevelUnlocked(1), isTrue);
      expect(service.isLevelUnlocked(2), isFalse);
      expect(service.isFeatureUnlocked('ai_chat'), isFalse);
    });

    test('Verifying purchase updates reactive entitlement', () async {
      await service.verifyAndApplyPurchase(
        platform: 'android',
        productId: 'premium_package',
        transactionId: 'tx_abc',
        purchaseToken: 'tok_abc',
      );

      expect(service.isPremium, isTrue);
      expect(service.isStandard, isTrue);
      expect(service.status.value, equals(EntitlementStatus.active));
      expect(service.isLevelUnlocked(6), isTrue);
      expect(service.isFeatureUnlocked('ai_chat'), isTrue);
    });

    test(
        'Account switch: User A signs out and User B is not tainted with User A premium',
        () async {
      repo.entitlementsByUser['user_a'] = UserEntitlement(
        userId: 'user_a',
        productId: 'premium_package',
        platform: 'android',
        originalTransactionId: 'tx_a',
        status: EntitlementStatus.active,
        expiresAt: DateTime.now().add(const Duration(days: 100)),
      );

      // User A logs in
      final serviceWithAuth = PremiumAccessService(
        repository: repo,
      );

      // Simulate User A active
      repo.entitlementsByUser['user_a'];
      final verifiedA = await repo.fetchActiveEntitlement('user_a');
      serviceWithAuth.currentEntitlement.value = verifiedA;
      serviceWithAuth.status.value = EntitlementStatus.active;
      expect(serviceWithAuth.isPremium, isTrue);

      // User A signs out -> reverts to clean state
      serviceWithAuth.currentEntitlement.value = null;
      serviceWithAuth.status.value = EntitlementStatus.free;
      expect(serviceWithAuth.isPremium, isFalse);
      expect(serviceWithAuth.isStandard, isFalse);

      // User B logs in (has no entitlement in DB)
      final verifiedB = await repo.fetchActiveEntitlement('user_b');
      serviceWithAuth.currentEntitlement.value = verifiedB;
      serviceWithAuth.status.value = EntitlementStatus.free;
      expect(serviceWithAuth.isPremium, isFalse);
    });
  });

  group('PR 05 — Gemini AI Gateway & Error Sanitization', () {
    test('GeminiService routes through gateway and returns structured payload',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('gemini-ai-gateway'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['action'], equals('dictionary'));
        expect(body['payload']['word'], equals('你好'));

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'source_lang': 'zh',
              'target_lang': 'vi',
              'hanzi': '你好',
              'pinyin': 'nǐ hǎo',
              'vi_meaning': 'Xin chào',
              'examples': [],
              'grammar_notes': [],
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = GeminiService(client: mockClient);
      final result = await service.fetchDictionaryEntry('你好');

      expect(result['hanzi'], equals('你好'));
      expect(result['vi_meaning'], equals('Xin chào'));
    });

    test('GeminiService maps 429 quota_exceeded into typed AiGatewayException',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': 'quota_exceeded',
            'message': 'Bạn đã đạt giới hạn lượt sử dụng AI trong ngày.',
          }),
          429,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = GeminiService(client: mockClient);

      expect(
        () => service.fetchDictionaryEntry('测试'),
        throwsA(isA<AiGatewayException>().having(
          (e) => e.code,
          'code',
          equals(AiGatewayErrorCode.quotaExceeded),
        )),
      );
    });

    test(
        'GeminiService maps 403 premium_required into typed AiGatewayException',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': 'premium_required',
            'message': 'Tính năng này yêu cầu gói tài khoản Premium.',
          }),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = GeminiService(client: mockClient);

      expect(
        () => service.analyzeHskExamPerformance(
          level: 1,
          questionsAndAnswers: [],
          score: 10,
          totalQuestions: 20,
        ),
        throwsA(isA<AiGatewayException>().having(
          (e) => e.code,
          'code',
          equals(AiGatewayErrorCode.premiumRequired),
        )),
      );
    });

    test('GeminiService handles server offline or network timeout gracefully',
        () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });

      final service = GeminiService(client: mockClient);

      expect(
        () => service.fetchConversation(1, null),
        throwsA(isA<AiGatewayException>().having(
          (e) => e.code,
          'code',
          equals(AiGatewayErrorCode.aiTemporarilyUnavailable),
        )),
      );
    });
  });

  group('PR 05 — SubscriptionController & Server Verification', () {
    late FakeIAPService fakeIAP;
    late FakeEntitlementRepository fakeRepo;
    late PremiumAccessService premiumAccess;
    late SubscriptionController subController;

    setUp(() {
      fakeIAP = FakeIAPService();
      fakeRepo = FakeEntitlementRepository();
      premiumAccess = PremiumAccessService(repository: fakeRepo);
      subController = SubscriptionController(
        fakeIAP,
        premiumAccessService: premiumAccess,
      );
      subController.onInit();
    });

    test('Processes purchased event through server verification', () async {
      final purchase = FakePurchaseDetails(
        productID: 'premium_package',
        status: PurchaseStatus.purchased,
        purchaseID: 'trans_999',
      );

      fakeIAP.emitPurchase(purchase);

      // Allow microtask to process
      await Future.delayed(const Duration(milliseconds: 50));

      expect(subController.status.value,
          equals(SubscriptionStatus.purchaseSuccess));
      expect(subController.isPremium, isTrue);
      expect(subController.isLevelUnlocked(6), isTrue);
    });

    test('Handles server verification failure safely without granting premium',
        () async {
      fakeRepo.throwOnVerify = true;
      fakeRepo.verifyError =
          'Giao dịch này đã được liên kết với một tài khoản khác.';

      final purchase = FakePurchaseDetails(
        productID: 'premium_package',
        status: PurchaseStatus.purchased,
        purchaseID: 'trans_already_used',
      );

      fakeIAP.emitPurchase(purchase);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(
          subController.status.value, equals(SubscriptionStatus.purchaseError));
      expect(subController.errorMessage.value,
          contains('liên kết với một tài khoản khác'));
      expect(subController.isPremium, isFalse);
    });
  });
}
