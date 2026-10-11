import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../database/db_helper.dart';
import '../data/learning_progress_repository.dart';
import '../model/unit_mastery.dart';

class SkillMasteryProfile {
  const SkillMasteryProfile({
    this.overall = 0.0,
    this.vocabulary = 0.0,
    this.listening = 0.0,
    this.speaking = 0.0,
    this.hanzi = 0.0,
    this.sentence = 0.0,
  });

  final double overall;
  final double vocabulary;
  final double listening;
  final double speaking;
  final double hanzi;
  final double sentence;

  int get overallPercent => (overall * 100).round().clamp(0, 100);
  int get vocabularyPercent => (vocabulary * 100).round().clamp(0, 100);
  int get listeningPercent => (listening * 100).round().clamp(0, 100);
  int get speakingPercent => (speaking * 100).round().clamp(0, 100);
  int get hanziPercent => (hanzi * 100).round().clamp(0, 100);
  int get sentencePercent => (sentence * 100).round().clamp(0, 100);
}

abstract interface class LearningMasteryService {
  Future<SkillMasteryProfile> getOverallSkillMastery({String? currentUnitId});
}

class DefaultLearningMasteryService implements LearningMasteryService {
  DefaultLearningMasteryService({
    SupabaseClient? client,
    LearningProgressRepository? progressRepository,
  })  : _client = client,
        _progressRepo = progressRepository ??
            SupabaseLearningProgressRepository(client: client);

  final SupabaseClient? _client;
  final LearningProgressRepository _progressRepo;

  SupabaseClient? get _activeClient {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<SkillMasteryProfile> getOverallSkillMastery({
    String? currentUnitId,
  }) async {
    double vocabScore = 0.0;
    double listenScore = 0.0;
    double speakScore = 0.0;
    double hanziScore = 0.0;
    double sentScore = 0.0;
    int dataPoints = 0;

    // 1. Try unit mastery if unitId given
    if (currentUnitId != null && currentUnitId.isNotEmpty) {
      try {
        final unitMastery = await _progressRepo.fetchUnitMastery(currentUnitId);
        if (unitMastery.vocabulary != null) {
          vocabScore += unitMastery.vocabulary!;
          dataPoints++;
        }
        if (unitMastery.listening != null) {
          listenScore += unitMastery.listening!;
          dataPoints++;
        }
        if (unitMastery.speaking != null) {
          speakScore += unitMastery.speaking!;
          dataPoints++;
        }
        if (unitMastery.hanzi != null) {
          hanziScore += unitMastery.hanzi!;
          dataPoints++;
        }
      } catch (e) {
        debugPrint('[LearningMasteryService] fetchUnitMastery failed: $e');
      }
    }

    // 2. Supplement / fallback from DB stats
    try {
      final dbStats = await DbHelper.instance.getStats();
      final learned = (dbStats['learned'] as num?)?.toDouble() ?? 0;
      final mastered = (dbStats['mastered'] as num?)?.toDouble() ?? 0;
      final speakingAvg = (dbStats['speakingAverage'] as num?)?.toDouble() ?? 0;
      final correct = (dbStats['correct'] as num?)?.toDouble() ?? 0;
      final wrong = (dbStats['wrong'] as num?)?.toDouble() ?? 0;

      final totalQuestions = correct + wrong;
      final accuracy = totalQuestions > 0 ? (correct / totalQuestions) : 0.0;

      if (vocabScore == 0 && learned > 0) {
        vocabScore = (mastered / learned).clamp(0.0, 1.0);
        if (vocabScore == 0) vocabScore = (learned / 50.0).clamp(0.0, 0.85);
      }
      if (speakScore == 0 && speakingAvg > 0) {
        speakScore = (speakingAvg / 100.0).clamp(0.0, 1.0);
      }
      if (listenScore == 0 && accuracy > 0) {
        listenScore = (accuracy * 0.95).clamp(0.0, 1.0);
      }
      if (sentScore == 0 && accuracy > 0) {
        sentScore = (accuracy * 0.90).clamp(0.0, 1.0);
      }
      if (hanziScore == 0 && learned > 0) {
        hanziScore = (mastered / 30.0).clamp(0.0, 0.90);
      }
    } catch (e) {
      debugPrint('[LearningMasteryService] getStats failed: $e');
    }

    // Ensure fallback non-zero reasonable baselines if user has any progress
    final values = [vocabScore, listenScore, speakScore, hanziScore, sentScore];
    final activeValues = values.where((v) => v > 0).toList();
    final double overall = activeValues.isNotEmpty
        ? activeValues.reduce((a, b) => a + b) / activeValues.length
        : 0.0;

    return SkillMasteryProfile(
      overall: overall.clamp(0.0, 1.0),
      vocabulary: vocabScore.clamp(0.0, 1.0),
      listening: listenScore.clamp(0.0, 1.0),
      speaking: speakScore.clamp(0.0, 1.0),
      hanzi: hanziScore.clamp(0.0, 1.0),
      sentence: sentScore.clamp(0.0, 1.0),
    );
  }
}
