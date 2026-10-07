import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screen/home/controller/home_controller.dart';
import 'screen/home/data/home_journey_repository.dart';
import 'screen/splash/controller/splash_controller.dart';
import 'core/services/gemini_service.dart';
import 'core/services/history_service.dart';
import 'core/backend/supabase_service.dart';
import 'core/services/iap_service.dart';
import 'screen/subscription/controller/subscription_controller.dart';

void initDI() {
  Get.lazyPut<SupabaseClient>(() => Supabase.instance.client, fenix: true);
  Get.lazyPut(() => SupabaseService(Get.find<SupabaseClient>()), fenix: true);
  Get.lazyPut(() => http.Client(), fenix: true);
  Get.lazyPut(() => GeminiService(client: Get.find<http.Client>()),
      fenix: true);
  Get.lazyPut(() => HistoryService(), fenix: true);
  Get.lazyPut(() => SplashController(), fenix: true);
  Get.lazyPut<HomeJourneyRepository>(() => CloudHomeJourneyRepository(),
      fenix: true);
  Get.lazyPut(
    () => HomeController(
      journeyRepository: Get.find<HomeJourneyRepository>(),
    ),
    fenix: true,
  );
  Get.lazyPut(() => IAPService(), fenix: true);
  Get.lazyPut(() => SubscriptionController(Get.find<IAPService>()),
      fenix: true);
  Get.lazyPut(() => IAPService(), fenix: true);
  Get.lazyPut(() => SubscriptionController(Get.find<IAPService>()),
      fenix: true);
}
