import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/db_helper.dart';
import '../../../core/models/word.dart';
import '../model/review_item.dart';

abstract interface class ReviewRepository {
  Future<ReviewSummary> loadReviewSummary();
  Future<List<ReviewItem>> loadReviewItems(ReviewCategory category);
}

class SupabaseReviewRepository implements ReviewRepository {
  SupabaseReviewRepository({SupabaseClient? client, DbHelper? dbHelper})
      : _client = client ?? Supabase.instance.client,
        _dbHelper = dbHelper ?? DbHelper.instance;

  final SupabaseClient _client;
  final DbHelper _dbHelper;

  @override
  Future<ReviewSummary> loadReviewSummary() async {
    final userId = _client.auth.currentUser?.id;
    var wordsDue = 0;
    var listeningDue = 0;
    var speakingDue = 0;
    var hanziDue = 0;
    var cloudQueryFailed = false;

    if (userId != null) {
      try {
        final wordProgressRows = List<Map<String, dynamic>>.from(
          await _client
              .from('lexicon_user_progress')
              .select(
                  'word_id, wrong_count, mastered, next_review_at, listening_score')
              .eq('user_id', userId),
        );
        final now = DateTime.now().toUtc();
        for (final row in wordProgressRows) {
          final wrong = (row['wrong_count'] as num?)?.toInt() ?? 0;
          final mastered = row['mastered'] == true;
          final nextReview =
              DateTime.tryParse('${row['next_review_at'] ?? ''}');
          final isDue = wrong > 0 ||
              !mastered ||
              (nextReview != null && !nextReview.isAfter(now));
          if (isDue) wordsDue++;

          final listenScore =
              (row['listening_score'] as num?)?.toDouble() ?? 100.0;
          if (listenScore < 75 || wrong > 1) listeningDue++;
        }

        final speakingRows = List<Map<String, dynamic>>.from(await _client
            .from('lexicon_speaking_practice')
            .select('id, accuracy_score, pronunciation_score, tone_score')
            .eq('user_id', userId));
        speakingDue = speakingRows.where((row) {
          final accuracy = (row['accuracy_score'] as num?)?.toDouble() ?? 0.0;
          final pronunciation =
              (row['pronunciation_score'] as num?)?.toDouble() ?? 0.0;
          final tone = (row['tone_score'] as num?)?.toDouble() ?? 0.0;
          return accuracy < 80 || pronunciation < 70 || tone < 65;
        }).length;

        final hanziRows = List<Map<String, dynamic>>.from(
          await _client
              .from('lexicon_hanzi_progress')
              .select(
                  'character_id, best_score, practice_count, next_review_at')
              .eq('user_id', userId),
        );
        hanziDue = hanziRows.where((row) {
          final score = (row['best_score'] as num?)?.toDouble() ?? 0.0;
          final practices = (row['practice_count'] as num?)?.toInt() ?? 0;
          final nextReview =
              DateTime.tryParse('${row['next_review_at'] ?? ''}');
          return score < 85 ||
              practices < 3 ||
              (nextReview != null && !nextReview.isAfter(now));
        }).length;
      } catch (_) {
        cloudQueryFailed = true;
      }
    }

    if (userId == null || cloudQueryFailed) {
      final localWords = await _dbHelper.getReviewWords();
      wordsDue = localWords.length;
      listeningDue = localWords.where((word) => word.wrongCount > 1).length;
    }

    final totalDue = wordsDue + listeningDue + speakingDue + hanziDue;

    return ReviewSummary(
      totalDue: totalDue,
      wordsDue: wordsDue,
      listeningDue: listeningDue,
      speakingDue: speakingDue,
      hanziDue: hanziDue,
    );
  }

  @override
  Future<List<ReviewItem>> loadReviewItems(ReviewCategory category) async {
    switch (category) {
      case ReviewCategory.words:
        return _loadWordsReview();
      case ReviewCategory.listening:
        return _loadListeningReview();
      case ReviewCategory.speaking:
        return _loadSpeakingReview();
      case ReviewCategory.hanzi:
        return _loadHanziReview();
    }
  }

  Future<List<ReviewItem>> _loadWordsReview() async {
    try {
      final words = await _dbHelper.getReviewWords();
      final sorted = List<Word>.from(words)
        ..sort((a, b) => b.wrongCount.compareTo(a.wrongCount));
      return sorted.map((w) {
        return ReviewItem(
          id: 'word_${w.id}',
          category: ReviewCategory.words,
          title: w.chinese,
          subtitle: w.pinyin,
          translation: w.vietnamese,
          wrongCount: w.wrongCount,
          score: (w.correctCount * 10.0).clamp(0, 100),
          audioUrl: w.ttsUrl,
          isWeak: w.wrongCount > 0,
          rawData: w,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ReviewItem>> _loadListeningReview() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        final local = (await _dbHelper.getReviewWords())
            .where((word) => word.ttsUrl.isNotEmpty)
            .toList()
          ..sort((a, b) => b.wrongCount.compareTo(a.wrongCount));
        return local.map((word) {
          return ReviewItem(
            id: 'listen_word_${word.id}',
            category: ReviewCategory.listening,
            title: word.chinese,
            subtitle: word.pinyin,
            translation: word.vietnamese,
            wrongCount: word.wrongCount,
            score: 0,
            audioUrl: word.ttsUrl,
            isWeak: true,
            rawData: word,
          );
        }).toList();
      }

      final weakProgress = List<Map<String, dynamic>>.from(
        await _client
            .from('lexicon_user_progress')
            .select('word_id, wrong_count, listening_score')
            .eq('user_id', userId)
            .order('listening_score')
            .limit(24),
      ).where((row) {
        final score = (row['listening_score'] as num?)?.toDouble() ?? 0;
        final wrong = (row['wrong_count'] as num?)?.toInt() ?? 0;
        return score < 75 || wrong > 1;
      }).toList();
      final wordIds = weakProgress
          .map((row) => (row['word_id'] as num?)?.toInt())
          .whereType<int>()
          .toList();
      if (wordIds.isEmpty) return const [];
      final wordRows = List<Map<String, dynamic>>.from(
        await _client
            .from('lexicon_words')
            .select('id, word, pinyin, meaning_vi, tts_url')
            .inFilter('id', wordIds),
      );
      final progressByWord = {
        for (final row in weakProgress) row['word_id']: row,
      };
      return wordRows.map((r) {
        final progress = progressByWord[r['id']];
        final score = (progress?['listening_score'] as num?)?.toDouble() ?? 0.0;
        return ReviewItem(
          id: 'listen_word_${r['id']}',
          category: ReviewCategory.listening,
          title: '${r['word'] ?? ''}',
          subtitle: '${r['pinyin'] ?? ''}',
          translation: '${r['meaning_vi'] ?? ''}',
          wrongCount: (progress?['wrong_count'] as num?)?.toInt() ?? 0,
          score: score,
          audioUrl: r['tts_url'] as String?,
          isWeak: true,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ReviewItem>> _loadSpeakingReview() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        final practiceRows = List<Map<String, dynamic>>.from(
          await _client
              .from('lexicon_speaking_practice')
              .select(
                  'id, target_text, recognized_text, accuracy_score, pronunciation_score, tone_score, fluency_score')
              .eq('user_id', userId)
              .order('accuracy_score')
              .limit(12),
        );
        final weakRows = practiceRows.where((row) {
          final accuracy = (row['accuracy_score'] as num?)?.toDouble() ?? 0.0;
          final pronunciation =
              (row['pronunciation_score'] as num?)?.toDouble() ?? 0.0;
          final tone = (row['tone_score'] as num?)?.toDouble() ?? 0.0;
          return accuracy < 80 || pronunciation < 70 || tone < 65;
        });
        if (weakRows.isNotEmpty) {
          return weakRows.map((r) {
            final acc = (r['accuracy_score'] as num?)?.toDouble() ?? 0.0;
            return ReviewItem(
              id: 'speaking_${r['id']}',
              category: ReviewCategory.speaking,
              title: '${r['target_text'] ?? ''}',
              subtitle: 'Độ chính xác: ${acc.round()}%',
              translation: 'Nói lại: ${r['recognized_text'] ?? ''}',
              wrongCount: acc < 70 ? 2 : 1,
              score: acc,
              isWeak: acc < 80,
              rawData: r,
            );
          }).toList();
        }
      }

      return const [];
    } catch (_) {
      return [];
    }
  }

  Future<List<ReviewItem>> _loadHanziReview() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        final progressRows = List<Map<String, dynamic>>.from(
          await _client
              .from('lexicon_hanzi_progress')
              .select(
                  'character_id, best_score, practice_count, next_review_at')
              .eq('user_id', userId)
              .order('best_score')
              .limit(12),
        );
        final now = DateTime.now().toUtc();
        final dueRows = progressRows.where((row) {
          final score = (row['best_score'] as num?)?.toDouble() ?? 0.0;
          final practices = (row['practice_count'] as num?)?.toInt() ?? 0;
          final nextReview =
              DateTime.tryParse('${row['next_review_at'] ?? ''}');
          return score < 85 ||
              practices < 3 ||
              (nextReview != null && !nextReview.isAfter(now));
        }).toList();
        if (dueRows.isNotEmpty) {
          final charIds = dueRows
              .map((r) => (r['character_id'] as num?)?.toInt())
              .whereType<int>()
              .toList();
          final chars = List<Map<String, dynamic>>.from(
            await _client
                .from('lexicon_characters')
                .select('id, character, stroke_count')
                .inFilter('id', charIds),
          );
          final charsById = {for (final c in chars) c['id']: c};
          final words = List<Map<String, dynamic>>.from(
            await _client
                .from('lexicon_words')
                .select('main_character_id, pinyin, meaning_vi')
                .inFilter('main_character_id', charIds),
          );
          final wordsByCharacter = <Object?, Map<String, dynamic>>{};
          for (final word in words) {
            wordsByCharacter.putIfAbsent(word['main_character_id'], () => word);
          }

          return dueRows.map((r) {
            final cid = r['character_id'];
            final c = charsById[cid] ?? const <String, dynamic>{};
            final word = wordsByCharacter[cid] ?? const <String, dynamic>{};
            final score = (r['best_score'] as num?)?.toDouble() ?? 50.0;
            return ReviewItem(
              id: 'hanzi_$cid',
              category: ReviewCategory.hanzi,
              title: '${c['character'] ?? '字'}',
              subtitle:
                  '${word['pinyin'] ?? ''} • ${c['stroke_count'] ?? 0} nét',
              translation: '${word['meaning_vi'] ?? 'Nghĩa chữ'}',
              wrongCount: score < 70 ? 2 : 1,
              score: score,
              isWeak: score < 80,
              rawData: c,
            );
          }).toList();
        }
      }

      return const [];
    } catch (_) {
      return [];
    }
  }
}
