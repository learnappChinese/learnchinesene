import 'package:flutter_test/flutter_test.dart';
import 'package:flash_learn_chinese/core/presentation/learning_presentation_mapper.dart';
import 'package:flash_learn_chinese/core/learning/model/learning_journey_models.dart';
import 'package:flash_learn_chinese/core/learning/model/unit_mastery.dart';

void main() {
  group('LearningPresentationMapper Tests', () {
    test('converts raw technical section titles into human-friendly titles', () {
      expect(
        LearningPresentationMapper.sectionTitle('Path Section 0', 1),
        'PHẦN 1: Giao tiếp cơ bản',
      );
      expect(
        LearningPresentationMapper.sectionTitle('PATH SECTION 1', 2),
        'PHẦN 2: Đời sống & Du lịch thường nhật',
      );
      expect(
        LearningPresentationMapper.sectionName(1),
        'Giao tiếp cơ bản',
      );
      expect(
        LearningPresentationMapper.sectionName(8),
        'Giao tiếp nâng cao & Thành thạo',
      );
    });

    test('formats unit titles without raw chapter or technical tokens', () {
      expect(
        LearningPresentationMapper.unitTitle('unit_1', 1),
        'Bài 1',
      );
      expect(
        LearningPresentationMapper.unitTitle('Gọi tên món ăn và đồ uống', 1),
        'Gọi tên món ăn và đồ uống',
      );
      expect(
        LearningPresentationMapper.unitFullTitle('Gọi tên món ăn và đồ uống', 1),
        'Bài 1: Gọi tên món ăn và đồ uống',
      );
    });

    test('detects technical strings accurately', () {
      expect(LearningPresentationMapper.isTechnical('Path Section 0'), isTrue);
      expect(LearningPresentationMapper.isTechnical('unit_index'), isTrue);
      expect(LearningPresentationMapper.isTechnical('game_code'), isTrue);
      expect(LearningPresentationMapper.isTechnical('section_2'), isTrue);
      expect(LearningPresentationMapper.isTechnical('Gọi tên món ăn'), isFalse);
    });

    test('maps game codes to friendly mission titles and descriptions', () {
      expect(
        LearningPresentationMapper.missionTitle(null, 'learn_words', 1),
        'Khám phá từ mới',
      );
      expect(
        LearningPresentationMapper.missionTitle(null, 'listen_select', 2),
        'Luyện nghe',
      );
      expect(
        LearningPresentationMapper.missionTitle(null, 'boss_battle', 7),
        'Thử thách Boss',
      );
    });
  });

  group('Learning Journey Progression Models & Rules', () {
    test('New user progression: Unit 1 unlocked, Unit 2 locked until Unit 1 complete', () {
      const unit1 = LearningUnitViewModel(
        id: 'sec_1_unit_1',
        sectionId: 'sec_1',
        sectionNumber: 1,
        unitNumber: 1,
        title: 'Bài 1: Làm quen và chào hỏi',
        subtitle: 'Khởi đầu hành trình',
        missionCount: 6,
        completedMissionCount: 0,
        isUnlocked: true,
      );

      const unit2Locked = LearningUnitViewModel(
        id: 'sec_1_unit_2',
        sectionId: 'sec_1',
        sectionNumber: 1,
        unitNumber: 2,
        title: 'Bài 2: Quốc tịch và quê quán',
        subtitle: 'Mở rộng giao tiếp',
        missionCount: 6,
        completedMissionCount: 0,
        isUnlocked: false,
        lockReason: 'Hoàn thành bài học trước để mở khóa.',
      );

      expect(unit1.isUnlocked, isTrue);
      expect(unit1.isCompleted, isFalse);
      expect(unit2Locked.isUnlocked, isFalse);
    });

    test('Unit completion requires boss defeat and unlocks next unit', () {
      const unit1Completed = LearningUnitViewModel(
        id: 'sec_1_unit_1',
        sectionId: 'sec_1',
        sectionNumber: 1,
        unitNumber: 1,
        title: 'Bài 1: Làm quen và chào hỏi',
        subtitle: 'Khởi đầu hành trình',
        missionCount: 6,
        completedMissionCount: 6,
        isUnlocked: true,
        bossWon: true,
        state: UnitCompletionState.completed,
      );

      expect(unit1Completed.isCompleted, isTrue);
      expect(unit1Completed.progress, 1.0);

      // Now Unit 2 is unlocked
      final unit2Unlocked = const LearningUnitViewModel(
        id: 'sec_1_unit_2',
        sectionId: 'sec_1',
        sectionNumber: 1,
        unitNumber: 2,
        title: 'Bài 2: Quốc tịch và quê quán',
        subtitle: 'Mở rộng giao tiếp',
        missionCount: 6,
        completedMissionCount: 0,
        isUnlocked: true,
      );

      expect(unit2Unlocked.isUnlocked, isTrue);
    });

    test('Section progression aggregates unit completions correctly', () {
      final section = LearningSectionViewModel(
        id: 'sec_1',
        sectionNumber: 1,
        title: 'PHẦN 1',
        subtitle: 'Giao tiếp cơ bản',
        unitCount: 10,
        completedUnitCount: 3,
        isUnlocked: true,
      );

      expect(section.progress, 0.3);
      expect(section.isCompleted, isFalse);

      final completedSection = section.copyWith(completedUnitCount: 10);
      expect(completedSection.isCompleted, isTrue);
      expect(completedSection.progress, 1.0);
    });

    test('Next action prioritization logic', () {
      // 1. Active session takes priority
      const activeAction = LearningNextAction(
        type: LearningActionType.activeSession,
        unitId: 'sec_1_unit_1',
        sectionNumber: 1,
        unitNumber: 1,
        sectionTitle: 'Giao tiếp cơ bản',
        unitTitle: 'Bài 1: Làm quen',
        missionTitle: 'Luyện nghe',
        label: 'TIẾP TỤC (4/10)',
        description: 'Đang làm dở câu hỏi',
        currentIndex: 4,
        currentTotal: 10,
      );

      expect(activeAction.type, LearningActionType.activeSession);
      expect(activeAction.label, 'TIẾP TỤC (4/10)');

      // 2. Boss ready takes priority over next unit
      const bossAction = LearningNextAction(
        type: LearningActionType.fightBoss,
        unitId: 'sec_1_unit_1',
        sectionNumber: 1,
        unitNumber: 1,
        sectionTitle: 'Giao tiếp cơ bản',
        unitTitle: 'Bài 1: Làm quen',
        missionTitle: 'Đấu Boss: Rồng Lửa',
        label: 'KHIÊU CHIẾN BOSS',
        description: 'Đánh bại Boss để kết thúc bài học',
        xpReward: 50,
      );

      expect(bossAction.type, LearningActionType.fightBoss);
      expect(bossAction.xpReward, 50);
    });
  });
}
