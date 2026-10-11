import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/user_entitlement.dart';

abstract class EntitlementRepository {
  Future<UserEntitlement?> fetchActiveEntitlement(String userId);

  Future<UserEntitlement> verifyPurchase({
    required String platform,
    required String productId,
    required String transactionId,
    required String purchaseToken,
    Map<String, dynamic>? rawPayload,
  });
}

class SupabaseEntitlementRepository implements EntitlementRepository {
  SupabaseEntitlementRepository({required SupabaseClient client})
      : _client = client;

  final SupabaseClient _client;

  @override
  Future<UserEntitlement?> fetchActiveEntitlement(String userId) async {
    try {
      final res = await _client.rpc('get_user_entitlement');
      if (res is List && res.isNotEmpty) {
        final data = Map<String, dynamic>.from(res.first as Map);
        return UserEntitlement.fromJson(data);
      } else if (res is Map) {
        return UserEntitlement.fromJson(Map<String, dynamic>.from(res));
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching active entitlement: $e');
      // Fallback query to app_user_entitlements with RLS
      try {
        final res = await _client
            .from('app_user_entitlements')
            .select()
            .eq('user_id', userId)
            .eq('status', 'active')
            .maybeSingle();

        if (res != null) {
          return UserEntitlement.fromJson(Map<String, dynamic>.from(res));
        }
      } catch (err) {
        debugPrint('Fallback entitlement query error: $err');
      }
      return null;
    }
  }

  @override
  Future<UserEntitlement> verifyPurchase({
    required String platform,
    required String productId,
    required String transactionId,
    required String purchaseToken,
    Map<String, dynamic>? rawPayload,
  }) async {
    try {
      final res = await _client.rpc('verify_app_store_purchase', params: {
        'p_platform': platform,
        'p_product_id': productId,
        'p_transaction_id': transactionId,
        'p_purchase_token': purchaseToken,
        'p_raw_data': rawPayload ?? {},
      });

      final data = Map<String, dynamic>.from(res as Map);
      if (data['success'] == true) {
        return UserEntitlement(
          userId: data['user_id']?.toString() ?? '',
          productId: data['product_id']?.toString() ?? productId,
          platform: platform,
          originalTransactionId: transactionId,
          status: EntitlementStatus.active,
          expiresAt: data['expires_at'] != null
              ? DateTime.tryParse(data['expires_at'].toString())
              : null,
          lastVerifiedAt: DateTime.now(),
        );
      } else {
        throw Exception(data['message'] ?? 'Xác minh giao dịch thất bại.');
      }
    } catch (e) {
      final message = e.toString();
      if (message.contains('transaction_already_claimed')) {
        throw Exception(
            'Giao dịch này đã được liên kết với một tài khoản khác. Vui lòng liên hệ hỗ trợ.');
      } else if (message.contains('authentication_required')) {
        throw Exception(
            'Vui lòng đăng nhập tài khoản trước khi thực hiện thanh toán.');
      } else if (message.contains('invalid_product_id')) {
        throw Exception('Gói dịch vụ không hợp lệ.');
      }
      rethrow;
    }
  }
}
