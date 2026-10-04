import 'core/services/iap_service.dart';
import 'features/subscription/controller/subscription_controller.dart';
import 'package:get/get.dart';

Future<void> init() async {
  Get.lazyPut(() => IAPService(), fenix: true);
  Get.lazyPut(() => SubscriptionController(Get.find<IAPService>()),
      fenix: true);
}
