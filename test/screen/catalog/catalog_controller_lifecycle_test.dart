import 'dart:async';

import 'package:flash_learn_chinese/core/database/db_helper.dart';
import 'package:flash_learn_chinese/core/models/hsk_level.dart';
import 'package:flash_learn_chinese/core/models/unit_model.dart';
import 'package:flash_learn_chinese/screen/hsk/controller/hsk_controller.dart';
import 'package:flash_learn_chinese/screen/unit/controller/unit_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Database implements DbHelper {
  final levels = Completer<List<HskLevel>>();
  final unitResponses = <int, Future<List<UnitModel>>>{};
  int metricCalls = 0;

  @override
  Future<List<HskLevel>> getHskLevels() => levels.future;

  @override
  Future<List<UnitModel>> getUnitsByLevel(int hskLevelId) =>
      unitResponses[hskLevelId] ?? Future.value([]);

  @override
  Future<Map<String, int>> getUnitMetrics(int unitId) async {
    metricCalls++;
    return {'words': 10, 'learned': 3};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() async => Get.reset());

  test('Completing a load after closing the HSK controller cannot update it',
      () async {
    final database = _Database();
    final controller =
        Get.put<HskController>(HskController(database: database));
    await Get.delete<HskController>();
    database.levels.complete([const HskLevel(id: 1, title: 'HSK 1', order: 1)]);
    await Future<void>.delayed(Duration.zero);
    expect(controller.isClosed, isTrue);
    expect(controller.levels, isEmpty);
    expect(controller.hasError.value, isFalse);
  });

  test('An older unit response cannot overwrite the selected level', () async {
    final database = _Database();
    final older = Completer<List<UnitModel>>();
    final newer = Completer<List<UnitModel>>();
    database.unitResponses.addAll({1: older.future, 2: newer.future});
    final controller =
        Get.put<UnitController>(UnitController(database: database));
    await Future<void>.delayed(Duration.zero);
    final firstLoad = controller.loadUnits(1);
    final secondLoad = controller.loadUnits(2);
    newer.complete([const UnitModel(id: 2, title: 'Bài mới', order: 1)]);
    await secondLoad;
    older.completeError(StateError('Old request failed'));
    await firstLoad;
    expect(controller.units.single.id, 2);
    expect(controller.hasError.value, isFalse);
    expect(controller.isLoading.value, isFalse);
  });

  test('Metrics survive UI rebuilds and refresh when the catalog reloads',
      () async {
    final database = _Database();
    final controller =
        Get.put<UnitController>(UnitController(database: database));
    await Future<void>.delayed(Duration.zero);
    final first = controller.metricsFor(1);
    final next = controller.metricsFor(1);
    expect(await first, {'words': 10, 'learned': 3});
    expect(await next, {'words': 10, 'learned': 3});
    expect(database.metricCalls, 1);
    await controller.loadUnits(1);
    await controller.metricsFor(1);
    expect(database.metricCalls, 2);
  });
}
