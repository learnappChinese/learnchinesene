import 'package:get/get.dart';
import '../controller/unit_overview_controller.dart';

class UnitOverviewBinding extends Bindings {
  UnitOverviewBinding({
    this.unitId = 'sec_1_unit_1',
    this.unitTitle = '',
    this.sectionNumber = 1,
    this.unitNumber = 1,
  });

  final String unitId;
  final String unitTitle;
  final int sectionNumber;
  final int unitNumber;

  @override
  void dependencies() {
    Get.lazyPut<UnitOverviewController>(
      () => UnitOverviewController()
        ..unitId = unitId
        ..unitTitle = unitTitle
        ..sectionNumber = sectionNumber
        ..unitNumber = unitNumber,
    );
  }
}
