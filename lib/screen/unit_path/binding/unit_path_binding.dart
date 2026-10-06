import 'package:get/get.dart';

import '../controller/unit_path_controller.dart';
import '../data/unit_learning_repository.dart';

class UnitPathBinding extends Bindings {
  UnitPathBinding({required this.unitId});

  final String unitId;

  @override
  void dependencies() {
    Get.lazyPut<UnitLearningRepository>(
      () => UnitLearningRepository(),
    );
    Get.lazyPut<UnitPathController>(
      () => UnitPathController(
        unitId: unitId,
        repository: Get.find<UnitLearningRepository>(),
      ),
    );
  }
}
