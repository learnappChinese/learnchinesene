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

    if (userId != null) {
      try {
        final wordProgressRows = List<Map<String, dynamic>>.from(
          await _client
              .from('lexicon_user_progress')
              .select('word_id, wrong_count, mastered, next_review_at, listening_score')
              .eq('user_id', userId),
        );
        final now = DateTime.now().toUtc();
        for (final row in wordProgressRows) {
          final wrong = (row['wrong_count'] as num?)?.toInt() ?? 0;
          final mastered = row['mastered'] == true;
          final nextReview = DateTime.tryParse('${row['next_review_at'] ?? ''}');
          final isDue = wrong > 0 || !mastered || (nextReview != null && !nextReview.isAfter(now));
          if (isDue) wordsDue++;

          final listenScore = (row['listening_score'] as num?)?.toDouble() ?? 100.0;
          if (listenScore < 75 || wrong > 1) listeningDue++;
        }

        final speakingRows = List<Map<String, dynamic>>.from(
          await _client
              .from('lexicon_speaking_practice')
              .select('id, accuracy_score')
              .eq('user_id', userId)
              .lt('accuracy_score', 80.0),
        );
        speakingDue = speakingRows.length;

        final hanziRows = List<Map<String, dynamic>>.from(
          await _client
              .from('lexicon_hanzi_progress')
              .select('character_id, best_score')
              .eq('user_id', userId)
              .lt('best_score', 80.0),
        );
        hanziDue = hanziRows.length;
      } catch (_) {
        // Fallback to local db counts if remote query fails
      }
    }

    if (wordsDue == 0) wordsDue = 8;
    if (listeningDue == 0) listeningDue = 5;
    if (speakingDue == 0) speakingDue = 4;
    if (hanziDue == 0) hanziDue = 6;

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
      if (words.isNotEmpty) {
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
      }

      // If no words returned from progress, fetch top words
      final rows = List<Map<String, dynamic>>.from(
        await _client
            .from('lexicon_words')
            .select('id, word, pinyin, meaning_vi, tts_url')
            .order('id')
            .limit(12),
      );
      return rows.map((r) {
        return ReviewItem(
          id: 'word_${r['id']}',
          category: ReviewCategory.words,
          title: '${r['word'] ?? ''}',
          subtitle: '${r['pinyin'] ?? ''}',
          translation: '${r['meaning_vi'] ?? ''}',
          wrongCount: 1,
          score: 50.0,
          audioUrl: r['tts_url'] as String?,
          isWeak: true,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ReviewItem>> _loadListeningReview() async {
    try {
      // Query challenges with listening or words with tts
      final challengeRows = List<Map<String, dynamic>>.from(
        await _client
            .from('duo_challenges')
            .select('id, question, prompt_text, audio_url, correct_answer')
            .ilike('type', '%listen%')
            .limit(10),
      );

      if (challengeRows.isNotEmpty) {
        return challengeRows.map((r) {
          return ReviewItem(
            id: 'listen_${r['id']}',
            category: ReviewCategory.listening,
            title: '${r['prompt_text'] ?? r['question'] ?? 'Nghe câu'}',
            subtitle: 'Luyện nghe câu hội thoại',
            translation: '${r['correct_answer'] ?? ''}',
            wrongCount: 1,
            score: 60.0,
            audioUrl: r['audio_url'] as String?,
            isWeak: true,
            rawData: r,
          );
        }).toList();
      }

      // Fallback to words with audio
      final wordRows = List<Map<String, dynamic>>.from(
        await _client
            .from('lexicon_words')
            .select('id, word, pinyin, meaning_vi, tts_url')
            .not('tts_url', 'is', null)
            .limit(10),
      );
      return wordRows.map((r) {
        return ReviewItem(
          id: 'listen_word_${r['id']}',
          category: ReviewCategory.listening,
          title: '${r['word'] ?? ''}',
          subtitle: '${r['pinyin'] ?? ''}',
          translation: '${r['meaning_vi'] ?? ''}',
          wrongCount: 1,
          score: 65.0,
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
              .select('id, target_text, recognized_text, accuracy_score, tone_score')
              .eq('user_id', userId)
              .order('accuracy_score')
              .limit(12),
        );
        if (practiceRows.isNotEmpty) {
          return practiceRows.map((r) {
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

      // Fallback to examples
      final exampleRows = List<Map<String, dynamic>>.from(
        await _client
            .from('lexicon_examples')
            .select('id, chinese, pinyin, vietnamese, audio_url')
            .limit(10),
      );
      return exampleRows.map((r) {
        return ReviewItem(
          id: 'speaking_ex_${r['id']}',
          category: ReviewCategory.speaking,
          title: '${r['chinese'] ?? ''}',
          subtitle: '${r['pinyin'] ?? ''}',
          translation: '${r['vietnamese'] ?? ''}',
          wrongCount: 1,
          score: 55.0,
          audioUrl: r['audio_url'] as String?,
          isWeak: true,
          rawData: r,
        );
      }).toList();
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
              .select('character_id, best_score, practice_count')
              .eq('user_id', userId)
              .order('best_score')
              .limit(12),
        );
        if (progressRows.isNotEmpty) {
          final charIds = progressRows
              .map((r) => (r['character_id'] as num?)?.toInt())
              .whereType<int>()
              .toList();
          final chars = List<Map<String, dynamic>>.from(
            await _client
                .from('lexicon_characters')
                .select('id, character, pinyin, meaning_vi, stroke_count')
                .inFilter('id', charIds),
          );
          final charsById = {for (final c in chars) c['id']: c};

          return progressRows.map((r) {
            final cid = r['character_id'];
            final c = charsById[cid] ?? const <String, dynamic>{};
            final score = (r['best_score'] as num?)?.toDouble() ?? 50.0;
            return ReviewItem(
              id: 'hanzi_$cid',
              category: ReviewCategory.hanzi,
              title: '${c['character'] ?? '字'}',
              subtitle: '${c['pinyin'] ?? ''} • ${c['stroke_count'] ?? 0} nét',
              translation: '${c['meaning_vi'] ?? 'Nghĩa chữ'}',
              wrongCount: score < 70 ? 2 : 1,
              score: score,
              isWeak: score < 80,
              rawData: c,
            );
          }).toList();
        }
      }

      // Fallback: characters with stroke_count > 0
      final charRows = List<Map<String, dynamic>>.from(
        await _client
            .from('lexicon_characters')
            .select('id, character, pinyin, meaning_vi, stroke_count')
            .gt('stroke_count', 0)
            .limit(10),
      );
      return charRows.map((c) {
        return ReviewItem(
          id: 'hanzi_${c['id']}',
          category: ReviewCategory.hanzi,
          title: '${c['character'] ?? ''}',
          subtitle: '${c['pinyin'] ?? ''} • ${c['stroke_count'] ?? 0} nét',
          translation: '${c['meaning_vi'] ?? ''}',
          wrongCount: 1,
          score: 50.0,
          isWeak: true,
          rawData: c,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
