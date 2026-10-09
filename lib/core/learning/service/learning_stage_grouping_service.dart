import 'dart:math' as math;
import '../../widgets/adventure_node.dart';
import '../../../screen/boss_battle/model/boss_battle_stage.dart';
import '../model/learning_stage_models.dart';

/// Service responsible for adaptively grouping raw curriculum data and user progress
/// into pedagogical Stages (Ải) with dynamic item counts.
class LearningStageGroupingService {
  const LearningStageGroupingService();

  /// Groups curriculum and progress data for a given Unit into dynamic learning stages.
  List<LearningStageViewModel> groupStagesForUnit({
    required String unitId,
    required String unitTitle,
    required int sectionNumber,
    required int unitNumber,
    required List<Map<String, dynamic>> rawWords,
    required List<Map<String, dynamic>> rawCharacters,
    required List<Map<String, dynamic>> rawChallenges,
    required List<Map<String, dynamic>> rawExamples,
    Map<String, dynamic>? rawBossStage,
    // User progress data
    Map<int, Map<String, dynamic>> wordProgress = const {},
    Map<int, Map<String, dynamic>> hanziProgress = const {},
    Map<int, Map<String, dynamic>> speakingProgress = const {},
    Map<String, Map<String, dynamic>> gameProgress = const {},
    Map<String, dynamic>? bossProgress,
  }) {
    final stages = <LearningStageViewModel>[];
    int stageOrder = 1;

    // -------------------------------------------------------------
    // 1. VOCABULARY STAGE(S)
    // -------------------------------------------------------------
    if (rawWords.isNotEmpty) {
      final vocabStages = _createVocabularyStages(
        unitId: unitId,
        unitTitle: unitTitle,
        startingOrder: stageOrder,
        rawWords: rawWords,
        wordProgress: wordProgress,
        gameProgress: gameProgress,
      );
      stages.addAll(vocabStages);
      stageOrder += vocabStages.length;
    }

    // -------------------------------------------------------------
    // 2. HANZI STAGE(S)
    // -------------------------------------------------------------
    if (rawCharacters.isNotEmpty) {
      final hanziStages = _createHanziStages(
        unitId: unitId,
        unitTitle: unitTitle,
        startingOrder: stageOrder,
        rawCharacters: rawCharacters,
        hanziProgress: hanziProgress,
      );
      stages.addAll(hanziStages);
      stageOrder += hanziStages.length;
    }

    // -------------------------------------------------------------
    // 3. LISTENING STAGE(S)
    // -------------------------------------------------------------
    final listeningChallenges = rawChallenges.where((c) {
      final type = '${c['type'] ?? ''}';
      final hasAudio = c['tts'] != null || c['slow_tts'] != null;
      return type == 'listenTap' || (hasAudio && type == 'select');
    }).toList();

    if (listeningChallenges.isNotEmpty) {
      final listeningStages = _createListeningStages(
        unitId: unitId,
        unitTitle: unitTitle,
        startingOrder: stageOrder,
        rawChallenges: listeningChallenges,
        gameProgress: gameProgress,
      );
      stages.addAll(listeningStages);
      stageOrder += listeningStages.length;
    }

    // -------------------------------------------------------------
    // 4. SENTENCE / GRAMMAR STAGE(S)
    // -------------------------------------------------------------
    final sentenceChallenges = rawChallenges.where((c) {
      final type = '${c['type'] ?? ''}';
      return type == 'translate' ||
          type == 'tapComplete' ||
          type == 'gapFill' ||
          type == 'orderTapComplete';
    }).toList();

    if (sentenceChallenges.isNotEmpty) {
      final sentenceStages = _createSentenceStages(
        unitId: unitId,
        unitTitle: unitTitle,
        startingOrder: stageOrder,
        rawChallenges: sentenceChallenges,
        gameProgress: gameProgress,
      );
      stages.addAll(sentenceStages);
      stageOrder += sentenceStages.length;
    }

    // -------------------------------------------------------------
    // 5. SPEAKING STAGE(S)
    // -------------------------------------------------------------
    if (rawExamples.isNotEmpty) {
      final speakingStages = _createSpeakingStages(
        unitId: unitId,
        unitTitle: unitTitle,
        startingOrder: stageOrder,
        rawExamples: rawExamples,
        speakingProgress: speakingProgress,
      );
      stages.addAll(speakingStages);
      stageOrder += speakingStages.length;
    }

    // -------------------------------------------------------------
    // 6. BOSS STAGE
    // -------------------------------------------------------------
    if (rawBossStage != null) {
      final bossStage = _createBossStage(
        unitId: unitId,
        unitTitle: unitTitle,
        stageOrder: stageOrder,
        sectionNumber: sectionNumber,
        unitNumber: unitNumber,
        rawBossStage: rawBossStage,
        bossProgress: bossProgress,
        previousStageIds: stages.map((s) => s.id).toList(),
      );
      stages.add(bossStage);
    }

    // -------------------------------------------------------------
    // 7. PREREQUISITES & UNLOCKING GRAPH
    // -------------------------------------------------------------
    return _applyUnlockAndPrerequisites(stages);
  }

  // ===============================================================
  // VOCABULARY GROUPING
  // ===============================================================
  List<LearningStageViewModel> _createVocabularyStages({
    required String unitId,
    required String unitTitle,
    required int startingOrder,
    required List<Map<String, dynamic>> rawWords,
    required Map<int, Map<String, dynamic>> wordProgress,
    required Map<String, Map<String, dynamic>> gameProgress,
  }) {
    final stages = <LearningStageViewModel>[];

    // Check if words span multiple topics or are > 12
    final hasMultipleTopics = rawWords
            .map((w) => w['topic_id'])
            .where((t) => t != null)
            .toSet()
            .length >
        1;

    List<List<Map<String, dynamic>>> groups;
    if (hasMultipleTopics && rawWords.length > 10) {
      // Group by topic
      final topicMap = <dynamic, List<Map<String, dynamic>>>{};
      for (final w in rawWords) {
        final topic = w['topic_id'] ?? 'general';
        topicMap.putIfAbsent(topic, () => []).add(w);
      }
      groups = topicMap.values.toList();
    } else if (rawWords.length > 12) {
      // Adaptive chunking based on natural size (~6-8 items per stage)
      final mid = (rawWords.length / 2).ceil();
      groups = [rawWords.sublist(0, mid), rawWords.sublist(mid)];
    } else {
      // Single cohesive stage
      groups = [rawWords];
    }

    for (int g = 0; g < groups.length; g++) {
      final wordGroup = groups[g];
      final currentOrder = startingOrder + g;
      final stageId = 'stage_${unitId}_vocab_${g + 1}';

      final items = <LearningStageItemViewModel>[];
      int completedCount = 0;
      double totalScore = 0.0;

      for (int i = 0; i < wordGroup.length; i++) {
        final w = wordGroup[i];
        final wordId = (w['id'] as num?)?.toInt() ?? (i + 1);
        final wordText = '${w['word'] ?? ''}';
        final pinyin = '${w['pinyin'] ?? ''}';
        final meaning = '${w['meaning_vi'] ?? w['meaning_en'] ?? ''}';

        final prog = wordProgress[wordId];
        final isWordLearned = prog != null &&
            (((prog['correct_count'] as num?)?.toInt() ?? 0) > 0 ||
                prog['is_completed'] == true ||
                ((prog['mastery'] as num?)?.toDouble() ?? 0.0) > 0.0);
        final isMastered = prog != null &&
            (prog['mastered'] == true ||
                ((prog['mastery'] as num?)?.toDouble() ?? 0.0) >= 0.9);

        final rawScore = (prog?['score'] as num?)?.toDouble();
        final rawMastery = (prog?['mastery'] as num?)?.toDouble();
        final score = isMastered
            ? 1.0
            : (rawScore != null
                ? (rawScore > 1.0 ? rawScore / 100.0 : rawScore)
                : (isWordLearned ? 0.8 : 0.0));
        final mastery = rawMastery ?? (isMastered ? 1.0 : (isWordLearned ? 0.6 : 0.0));

        final itemState = isMastered || isWordLearned
            ? AdventureNodeState.completed
            : AdventureNodeState.available;

        if (itemState == AdventureNodeState.completed) {
          completedCount++;
          totalScore += score;
        }

        items.add(
          LearningStageItemViewModel(
            id: 'item_${stageId}_$wordId',
            sourceId: '$wordId',
            type: 'word',
            order: i + 1,
            prompt: wordText,
            content: {
              'word': wordText,
              'pinyin': pinyin,
              'meaning': meaning,
              'tts_url': w['tts_url'],
            },
            state: itemState,
            score: score,
            mastery: mastery,
            isRequired: true,
          ),
        );
      }

      // Check game level progress fallback if word progress is empty
      final duoProg = gameProgress['learn_words'];
      if (completedCount == 0 && duoProg != null && duoProg['is_completed'] == true) {
        completedCount = items.length;
        totalScore = items.length * 1.0;
      }

      final isAllDone = completedCount >= items.length && items.isNotEmpty;
      final avgScore = items.isEmpty ? 0.0 : totalScore / items.length;
      final stars = isAllDone
          ? (avgScore >= 0.85 ? 3 : (avgScore >= 0.7 ? 2 : 1))
          : 0;

      final stageState = isAllDone
          ? (stars == 3 ? AdventureNodeState.perfect : AdventureNodeState.completed)
          : (completedCount > 0
              ? AdventureNodeState.inProgress
              : AdventureNodeState.available);

      final title = groups.length > 1
          ? 'Ải $currentOrder: Từ vựng phần ${g + 1}'
          : 'Ải $currentOrder: Từ vựng cốt lõi';

      stages.add(
        LearningStageViewModel(
          id: stageId,
          unitId: unitId,
          title: title,
          subtitle: 'Ghi nhớ ${items.length} từ vựng then chốt',
          activityType: LearningStageActivityType.vocabulary,
          learningObjective: 'Nhận biết và nhớ nghĩa từ vựng trong bài $unitTitle',
          items: items,
          completedItems: completedCount,
          state: stageState,
          mastery: avgScore,
          stars: stars,
          estimatedMinutes: math.max(2, (items.length * 0.5).round()),
          rewardPreview: '+${items.length * 2} XP • ⭐',
          prerequisiteIds: g > 0 ? ['stage_${unitId}_vocab_$g'] : const [],
        ),
      );
    }

    return stages;
  }

  // ===============================================================
  // HANZI GROUPING
  // ===============================================================
  List<LearningStageViewModel> _createHanziStages({
    required String unitId,
    required String unitTitle,
    required int startingOrder,
    required List<Map<String, dynamic>> rawCharacters,
    required Map<int, Map<String, dynamic>> hanziProgress,
  }) {
    final stages = <LearningStageViewModel>[];

    // Split characters if > 10 for reasonable cognitive load
    List<List<Map<String, dynamic>>> groups;
    if (rawCharacters.length > 10) {
      // Sort by stroke count if available
      final sorted = List<Map<String, dynamic>>.from(rawCharacters)
        ..sort((a, b) {
          final sA = (a['stroke_count'] as num?)?.toInt() ?? 0;
          final sB = (b['stroke_count'] as num?)?.toInt() ?? 0;
          return sA.compareTo(sB);
        });
      final mid = (sorted.length / 2).ceil();
      groups = [sorted.sublist(0, mid), sorted.sublist(mid)];
    } else {
      groups = [rawCharacters];
    }

    for (int g = 0; g < groups.length; g++) {
      final charGroup = groups[g];
      final currentOrder = startingOrder + g;
      final stageId = 'stage_${unitId}_hanzi_${g + 1}';

      final items = <LearningStageItemViewModel>[];
      int completedCount = 0;
      double totalScore = 0.0;

      for (int i = 0; i < charGroup.length; i++) {
        final c = charGroup[i];
        final charId = (c['id'] as num?)?.toInt() ?? (i + 1);
        final charText = '${c['character'] ?? ''}';
        final strokes = (c['stroke_count'] as num?)?.toInt() ?? 0;

        final prog = hanziProgress[charId];
        final practiceCount =
            prog != null ? (prog['practice_count'] as num?)?.toInt() ?? 0 : 0;
        final bestScore =
            prog != null ? (prog['best_score'] as num?)?.toDouble() ?? 0.0 : 0.0;

        final isCharDone = practiceCount > 0 || bestScore >= 0.7;
        final itemState = isCharDone
            ? AdventureNodeState.completed
            : AdventureNodeState.available;

        if (isCharDone) {
          completedCount++;
          totalScore += bestScore > 0 ? bestScore : 0.85;
        }

        items.add(
          LearningStageItemViewModel(
            id: 'item_${stageId}_$charId',
            sourceId: '$charId',
            type: 'character',
            order: i + 1,
            prompt: charText,
            content: {
              'character': charText,
              'stroke_count': strokes,
              'stroke_paths': c['stroke_paths'],
              'radical_id': c['radical_id'],
            },
            state: itemState,
            score: bestScore,
            mastery: isCharDone ? (bestScore > 0 ? bestScore : 0.8) : 0.0,
            isRequired: true,
          ),
        );
      }

      final isAllDone = completedCount >= items.length && items.isNotEmpty;
      final avgScore = items.isEmpty ? 0.0 : totalScore / items.length;
      final stars = isAllDone
          ? (avgScore >= 0.85 ? 3 : (avgScore >= 0.7 ? 2 : 1))
          : 0;

      final stageState = isAllDone
          ? (stars == 3 ? AdventureNodeState.perfect : AdventureNodeState.completed)
          : (completedCount > 0
              ? AdventureNodeState.inProgress
              : AdventureNodeState.available);

      final title = groups.length > 1
          ? 'Ải $currentOrder: Chữ Hán nhóm ${g + 1}'
          : 'Ải $currentOrder: Nhận diện chữ Hán';

      stages.add(
        LearningStageViewModel(
          id: stageId,
          unitId: unitId,
          title: title,
          subtitle: 'Luyện viết và ghi nhớ ${items.length} chữ Hán',
          activityType: LearningStageActivityType.hanzi,
          learningObjective: 'Nắm vững quy tắc nét và thứ tự viết chữ Hán',
          items: items,
          completedItems: completedCount,
          state: stageState,
          mastery: avgScore,
          stars: stars,
          estimatedMinutes: math.max(3, (items.length * 0.75).round()),
          rewardPreview: '+${items.length * 3} XP • ⭐',
        ),
      );
    }

    return stages;
  }

  // ===============================================================
  // LISTENING GROUPING
  // ===============================================================
  List<LearningStageViewModel> _createListeningStages({
    required String unitId,
    required String unitTitle,
    required int startingOrder,
    required List<Map<String, dynamic>> rawChallenges,
    required Map<String, Map<String, dynamic>> gameProgress,
  }) {
    final stages = <LearningStageViewModel>[];

    // Group challenges by session if multiple sessions exist
    final sessionMap = <int, List<Map<String, dynamic>>>{};
    for (final c in rawChallenges) {
      final sessId = (c['session_id'] as num?)?.toInt() ?? 1;
      sessionMap.putIfAbsent(sessId, () => []).add(c);
    }

    final sessionEntries = sessionMap.entries.toList();
    // Cap stage item count to ~6-10 per stage so rings stay clear
    final groups = <List<Map<String, dynamic>>>[];
    for (final entry in sessionEntries) {
      final list = entry.value;
      if (list.length > 12) {
        final mid = (list.length / 2).ceil();
        groups.add(list.sublist(0, mid));
        groups.add(list.sublist(mid));
      } else {
        groups.add(list);
      }
    }

    for (int g = 0; g < groups.length; g++) {
      final chalGroup = groups[g];
      final currentOrder = startingOrder + g;
      final stageId = 'stage_${unitId}_listen_${g + 1}';

      final items = <LearningStageItemViewModel>[];
      int completedCount = 0;

      final duoProg = gameProgress['listen_select'];
      final isGamePassed = duoProg != null && duoProg['is_completed'] == true;
      final currentIndex =
          duoProg != null ? (duoProg['current_index'] as num?)?.toInt() ?? 0 : 0;

      for (int i = 0; i < chalGroup.length; i++) {
        final c = chalGroup[i];
        final chalId = '${c['id'] ?? (i + 1)}';
        final prompt = '${c['prompt'] ?? 'Luyện nghe câu'}';

        final isItemDone = isGamePassed || i < currentIndex;
        final itemState = isItemDone
            ? AdventureNodeState.completed
            : AdventureNodeState.available;

        if (isItemDone) completedCount++;

        items.add(
          LearningStageItemViewModel(
            id: 'item_${stageId}_$chalId',
            sourceId: chalId,
            type: 'listenTap',
            order: i + 1,
            prompt: prompt,
            content: {
              'tts': c['tts'],
              'slow_tts': c['slow_tts'],
              'choices_text': c['choices_text'],
              'solutions': c['solutions'],
            },
            state: itemState,
            score: isItemDone ? 1.0 : 0.0,
            mastery: isItemDone ? 1.0 : 0.0,
            isRequired: true,
          ),
        );
      }

      final isAllDone = completedCount >= items.length && items.isNotEmpty;
      final stars = isAllDone ? 3 : 0;
      final stageState = isAllDone
          ? AdventureNodeState.perfect
          : (completedCount > 0
              ? AdventureNodeState.inProgress
              : AdventureNodeState.available);

      final title = groups.length > 1
          ? 'Ải $currentOrder: Luyện nghe đợt ${g + 1}'
          : 'Ải $currentOrder: Luyện nghe phản xạ';

      stages.add(
        LearningStageViewModel(
          id: stageId,
          unitId: unitId,
          title: title,
          subtitle: 'Nghe và nhận biết ${items.length} mẫu âm thanh',
          activityType: LearningStageActivityType.listening,
          learningObjective: 'Phát triển phản xạ nghe hiểu cho bài $unitTitle',
          items: items,
          completedItems: completedCount,
          state: stageState,
          mastery: isAllDone ? 1.0 : 0.0,
          stars: stars,
          estimatedMinutes: math.max(2, (items.length * 0.4).round()),
          rewardPreview: '+${items.length * 2} XP • ⭐',
        ),
      );
    }

    return stages;
  }

  // ===============================================================
  // SENTENCE / GRAMMAR GROUPING
  // ===============================================================
  List<LearningStageViewModel> _createSentenceStages({
    required String unitId,
    required String unitTitle,
    required int startingOrder,
    required List<Map<String, dynamic>> rawChallenges,
    required Map<String, Map<String, dynamic>> gameProgress,
  }) {
    final stages = <LearningStageViewModel>[];

    // Chunk challenges gracefully (~6-8 items per stage)
    const targetSize = 8;
    final groups = <List<Map<String, dynamic>>>[];
    for (int i = 0; i < rawChallenges.length; i += targetSize) {
      final end = math.min(i + targetSize, rawChallenges.length);
      groups.add(rawChallenges.sublist(i, end));
      // Cap at 2 stages for sentences per unit so progression is balanced
      if (groups.length == 2 && end < rawChallenges.length) {
        // Fold remaining into second group if small, or break cleanly
        break;
      }
    }

    for (int g = 0; g < groups.length; g++) {
      final chalGroup = groups[g];
      final currentOrder = startingOrder + g;
      final stageId = 'stage_${unitId}_sentence_${g + 1}';

      final items = <LearningStageItemViewModel>[];
      int completedCount = 0;

      final duoProg = gameProgress['translate'] ?? gameProgress['gap_fill'];
      final isGamePassed = duoProg != null && duoProg['is_completed'] == true;
      final currentIndex =
          duoProg != null ? (duoProg['current_index'] as num?)?.toInt() ?? 0 : 0;

      for (int i = 0; i < chalGroup.length; i++) {
        final c = chalGroup[i];
        final chalId = '${c['id'] ?? (i + 1)}';
        final prompt = '${c['prompt'] ?? 'Ghép câu hoàn chỉnh'}';

        final isItemDone = isGamePassed || i < currentIndex;
        final itemState = isItemDone
            ? AdventureNodeState.completed
            : AdventureNodeState.available;

        if (isItemDone) completedCount++;

        items.add(
          LearningStageItemViewModel(
            id: 'item_${stageId}_$chalId',
            sourceId: chalId,
            type: '${c['type'] ?? 'translate'}',
            order: i + 1,
            prompt: prompt,
            content: {
              'tokens_text': c['tokens_text'],
              'choices_text': c['choices_text'],
              'solutions': c['solutions'],
            },
            state: itemState,
            score: isItemDone ? 1.0 : 0.0,
            mastery: isItemDone ? 1.0 : 0.0,
            isRequired: true,
          ),
        );
      }

      final isAllDone = completedCount >= items.length && items.isNotEmpty;
      final stars = isAllDone ? 3 : 0;
      final stageState = isAllDone
          ? AdventureNodeState.perfect
          : (completedCount > 0
              ? AdventureNodeState.inProgress
              : AdventureNodeState.available);

      final title = groups.length > 1
          ? 'Ải $currentOrder: Ghép & dịch câu ${g + 1}'
          : 'Ải $currentOrder: Cấu trúc câu & Dịch';

      stages.add(
        LearningStageViewModel(
          id: stageId,
          unitId: unitId,
          title: title,
          subtitle: 'Hoàn thành ${items.length} câu ngữ pháp ứng dụng',
          activityType: LearningStageActivityType.sentence,
          learningObjective: 'Sử dụng mẫu câu chuẩn xác trong ngữ cảnh',
          items: items,
          completedItems: completedCount,
          state: stageState,
          mastery: isAllDone ? 1.0 : 0.0,
          stars: stars,
          estimatedMinutes: math.max(3, (items.length * 0.5).round()),
          rewardPreview: '+${items.length * 2} XP • ⭐',
        ),
      );
    }

    return stages;
  }

  // ===============================================================
  // SPEAKING GROUPING
  // ===============================================================
  List<LearningStageViewModel> _createSpeakingStages({
    required String unitId,
    required String unitTitle,
    required int startingOrder,
    required List<Map<String, dynamic>> rawExamples,
    required Map<int, Map<String, dynamic>> speakingProgress,
  }) {
    // Select 5-8 representative examples for speaking session
    final speakingExamples = rawExamples.take(8).toList();
    if (speakingExamples.isEmpty) return const [];

    final stageId = 'stage_${unitId}_speaking_1';
    final items = <LearningStageItemViewModel>[];
    int completedCount = 0;
    double totalScore = 0.0;

    for (int i = 0; i < speakingExamples.length; i++) {
      final ex = speakingExamples[i];
      final exId = (ex['id'] as num?)?.toInt() ?? (i + 1);
      final sentenceCn = '${ex['sentence_cn'] ?? ''}';
      final sentencePinyin = '${ex['sentence_pinyin'] ?? ''}';
      final sentenceVi = '${ex['sentence_vi'] ?? ''}';

      final prog = speakingProgress[exId];
      final accuracy =
          prog != null ? (prog['accuracy_score'] as num?)?.toDouble() ?? 0.0 : 0.0;

      final isPassed = accuracy >= 0.7;
      final itemState = isPassed
          ? AdventureNodeState.completed
          : AdventureNodeState.available;

      if (isPassed) {
        completedCount++;
        totalScore += accuracy;
      }

      items.add(
        LearningStageItemViewModel(
          id: 'item_${stageId}_$exId',
          sourceId: '$exId',
          type: 'speaking',
          order: i + 1,
          prompt: sentenceCn,
          content: {
            'sentence_cn': sentenceCn,
            'sentence_pinyin': sentencePinyin,
            'sentence_vi': sentenceVi,
          },
          state: itemState,
          score: accuracy,
          mastery: accuracy,
          // Speaking can be optional for unit completion if config says so,
          // but here we mark it as part of comprehensive mastery
          isRequired: false,
        ),
      );
    }

    final isAllDone = completedCount >= items.length && items.isNotEmpty;
    final avgScore = items.isEmpty ? 0.0 : totalScore / items.length;
    final stars = isAllDone
        ? (avgScore >= 0.85 ? 3 : (avgScore >= 0.7 ? 2 : 1))
        : 0;

    final stageState = isAllDone
        ? (stars == 3 ? AdventureNodeState.perfect : AdventureNodeState.completed)
        : (completedCount > 0
            ? AdventureNodeState.inProgress
            : AdventureNodeState.available);

    return [
      LearningStageViewModel(
        id: stageId,
        unitId: unitId,
        title: 'Ải $startingOrder: Luyện phát âm & Nói',
        subtitle: 'Thực hành ${items.length} câu giao tiếp thực tế',
        activityType: LearningStageActivityType.speaking,
        learningObjective: 'Phát âm chuẩn xác thanh điệu và ngữ điệu',
        items: items,
        completedItems: completedCount,
        state: stageState,
        mastery: avgScore,
        stars: stars,
        estimatedMinutes: math.max(3, (items.length * 0.6).round()),
        rewardPreview: '+${items.length * 3} XP • ⭐',
        isRequired: false, // Optional bonus stage!
      ),
    ];
  }

  // ===============================================================
  // BOSS STAGE
  // ===============================================================
  LearningStageViewModel _createBossStage({
    required String unitId,
    required String unitTitle,
    required int stageOrder,
    required int sectionNumber,
    required int unitNumber,
    required Map<String, dynamic> rawBossStage,
    Map<String, dynamic>? bossProgress,
    required List<String> previousStageIds,
  }) {
    final bossId = (rawBossStage['id'] as num?)?.toInt() ?? 1;
    final bossName = '${rawBossStage['boss_name'] ?? 'Thần Thú Bảo Vệ'}';
    final questionCount =
        (rawBossStage['question_count'] as num?)?.toInt() ?? 8;
    final bossHp = (rawBossStage['boss_hp'] as num?)?.toInt() ?? 100;
    final playerHp = (rawBossStage['player_hp'] as num?)?.toInt() ?? 100;
    final difficulty = (rawBossStage['difficulty'] as num?)?.toInt() ?? 1;

    final bossStageData = BossBattleStage(
      id: bossId,
      unitId: unitId,
      stageOrder: stageOrder,
      sectionNumber: sectionNumber,
      unitNumber: unitNumber,
      title: 'Đại chiến $bossName',
      questionCount: questionCount,
      difficulty: difficulty,
      bossName: bossName,
      bossHp: bossHp,
      playerHp: playerHp,
      themeCode: '${rawBossStage['theme_code'] ?? 'bambooVillage'}',
    );

    final isBossBeaten =
        bossProgress != null && bossProgress['completed'] == true;
    final bossStars =
        bossProgress != null ? (bossProgress['stars'] as num?)?.toInt() ?? 0 : 0;

    // Items for boss reflect the boss HP / question encounters
    final items = List.generate(
      questionCount,
      (idx) => LearningStageItemViewModel(
        id: 'item_boss_${bossId}_${idx + 1}',
        sourceId: '${idx + 1}',
        type: 'boss_round',
        order: idx + 1,
        prompt: 'Hiệp ${idx + 1}: Thử thách $bossName',
        state: isBossBeaten
            ? AdventureNodeState.completed
            : AdventureNodeState.available,
        isRequired: true,
      ),
    );

    return LearningStageViewModel(
      id: 'stage_${unitId}_boss',
      unitId: unitId,
      title: 'Ải $stageOrder: Cổng Boss $bossName',
      subtitle: 'Đối đầu $bossName ($questionCount thử thách quyết định)',
      activityType: LearningStageActivityType.boss,
      learningObjective: 'Tổng hợp toàn bộ kiến thức bài học để chiến thắng Boss',
      items: items,
      completedItems: isBossBeaten ? items.length : 0,
      state: isBossBeaten
          ? AdventureNodeState.completed
          : AdventureNodeState.locked,
      mastery: isBossBeaten ? 1.0 : 0.0,
      stars: bossStars,
      estimatedMinutes: 5,
      rewardPreview: 'Rương báu • +50 XP • ⭐⭐⭐',
      prerequisiteIds: previousStageIds,
      isRequired: true,
      bossStage: bossStageData,
    );
  }

  // ===============================================================
  // UNLOCK GRAPH & DEPENDENCY RESOLUTION
  // ===============================================================
  List<LearningStageViewModel> _applyUnlockAndPrerequisites(
    List<LearningStageViewModel> stages,
  ) {
    if (stages.isEmpty) return const [];

    final resolved = <LearningStageViewModel>[];

    for (int i = 0; i < stages.length; i++) {
      final stage = stages[i];

      final prereqIds = stage.prerequisiteIds.isNotEmpty
          ? stage.prerequisiteIds
          : (i > 0 ? [stages[i - 1].id] : const <String>[]);

      // Boss unlocking condition: all required stages before it must be completed
      if (stage.activityType == LearningStageActivityType.boss) {
        final allRequiredBeforeDone = resolved
            .where((s) => s.isRequired)
            .every((s) => s.isCompleted);

        final bossState = stage.isCompleted
            ? (stage.stars == 3
                ? AdventureNodeState.perfect
                : AdventureNodeState.completed)
            : (allRequiredBeforeDone
                ? AdventureNodeState.available
                : AdventureNodeState.locked);

        resolved.add(stage.copyWith(
          state: bossState,
          prerequisiteIds: prereqIds,
        ));
        continue;
      }

      // Normal stage unlocking:
      // First stage is always available if not completed.
      // Next stage is available if its prerequisites are completed.
      AdventureNodeState resolvedState = stage.state;

      if (!stage.isCompleted && stage.state != AdventureNodeState.inProgress) {
        if (i == 0) {
          resolvedState = AdventureNodeState.available;
        } else {
          final arePrereqsDone = prereqIds.isEmpty ||
              prereqIds.every(
                  (pid) => resolved.any((s) => s.id == pid && s.isCompleted));
          resolvedState = arePrereqsDone
              ? AdventureNodeState.available
              : AdventureNodeState.locked;
        }
      }

      resolved.add(stage.copyWith(
        state: resolvedState,
        prerequisiteIds: prereqIds,
      ));
    }

    return resolved;
  }
}
