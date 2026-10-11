import 'package:flutter_test/flutter_test.dart';
import 'package:flash_learn_chinese/core/learning/service/learning_mastery_service.dart';
import 'package:flash_learn_chinese/core/learning/model/unit_mastery.dart';
import 'package:flash_learn_chinese/core/learning/data/learning_progress_repository.dart';
import 'package:flash_learn_chinese/core/learning/model/learning_activity_submission.dart';
import 'package:flash_learn_chinese/core/learning/model/learning_result.dart';

class _FakeProgressRepo implements LearningProgressRepository {
  @override
  Future<UnitMastery> fetchUnitMastery(String unitId) async {
    return const UnitMastery(
      vocabulary: 0.85,
      listening: 0.70,
      speaking: 0.90,
      hanzi: 0.60,
    );
  }

  @override
  Future<LearningResult> completeActivity(
      LearningActivitySubmission submission) async {
    throw UnimplementedError();
  }

  @override
  Future<void> startAttempt(LearningActivitySubmission submission) async {}

  @override
  Future<void> abandonAttempt(String attemptId,
      {Map<String, dynamic> metadata = const {}}) async {}

  @override
  Future<List<Map<String, dynamic>>> fetchAttemptHistory(
          {int limit = 50}) async =>
      [];

  @override
  Future<List<Map<String, dynamic>>> fetchXpHistory({int limit = 50}) async =>
      [];

  @override
  Future<void> migrateGuestProgressToCloud() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SkillMasteryProfile', () {
    test('computes percentage properties accurately clamped to 0-100', () {
      const profile = SkillMasteryProfile(
        overall: 0.756,
        vocabulary: 0.85,
        listening: 0.604,
        speaking: 0.90,
        hanzi: 0.50,
        sentence: 0.70,
      );

      expect(profile.overallPercent, 76);
      expect(profile.vocabularyPercent, 85);
      expect(profile.listeningPercent, 60);
      expect(profile.speakingPercent, 90);
      expect(profile.hanziPercent, 50);
      expect(profile.sentencePercent, 70);
    });

    test('clamps boundary values', () {
      const profile = SkillMasteryProfile(
        overall: 1.2,
        vocabulary: -0.1,
      );
      expect(profile.overallPercent, 100);
      expect(profile.vocabularyPercent, 0);
    });
  });

  group('DefaultLearningMasteryService', () {
    test('retrieves mastery with unit id', () async {
      final service = DefaultLearningMasteryService(
        progressRepository: _FakeProgressRepo(),
      );

      final result =
          await service.getOverallSkillMastery(currentUnitId: 'unit-1');
      expect(result.vocabulary, closeTo(0.85, 0.01));
      expect(result.listening, closeTo(0.70, 0.01));
      expect(result.speaking, closeTo(0.90, 0.01));
      expect(result.hanzi, closeTo(0.60, 0.01));
      expect(result.overall, greaterThan(0.7));
    });
  });
}
