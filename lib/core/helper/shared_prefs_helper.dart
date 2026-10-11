import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  static const String _kActiveProductId = 'activeProductId';
  static const String _kPurchaseDate = 'purchaseDate';

  static Future<void> saveSubscriptionStatus(
      String productId, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kActiveProductId, productId);
    await prefs.setInt(_kPurchaseDate, date.millisecondsSinceEpoch);
  }

  static Future<String?> getActiveProductId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kActiveProductId);
  }

  static Future<DateTime?> getPurchaseDate() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getInt(_kPurchaseDate);
    if (savedDate != null) {
      return DateTime.fromMillisecondsSinceEpoch(savedDate);
    }
    return null;
  }

  static Future<void> clearSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kActiveProductId);
    await prefs.remove(_kPurchaseDate);
  }
}
