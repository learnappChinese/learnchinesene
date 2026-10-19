import 'package:get/get.dart';
import '../model/boss_battle_stage.dart';

class BossStageMapController extends GetxController {
  BossStageMapController({required this.loadStages});

  final Future<List<BossBattleStage>> Function() loadStages;
  late Future<List<BossBattleStage>> stages;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  void reload() {
    if (!isClosed) stages = loadStages();
  }
}
