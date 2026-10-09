import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/boss_battle_question.dart';
import '../model/boss_battle_stage.dart';

abstract class BossBattleQuestionSource {
  Future<List<BossBattleQuestion>> loadQuestionSeeds({
    int limit = 36,
    int? stageId,
  });

  Future<void> close();
}

class BossBattleRepository implements BossBattleQuestionSource {
  BossBattleRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<BossBattleStage>> loadStages() async {
    final rows = List<Map<String, dynamic>>.from(
      await _client.rpc('boss_stage_catalog'),
    );
    return rows
        .map(BossBattleStage.fromMap)
        .where((stage) => stage.id > 0 && stage.questionCount > 0)
        .toList(growable: false);
  }

  @override
  Future<List<BossBattleQuestion>> loadQuestionSeeds({
    int limit = 36,
    int? stageId,
  }) async {
    final response = stageId == null
        ? await _client.rpc(
            'random_boss_questions',
            params: {'p_limit': limit},
          )
        : await _client.rpc(
            'boss_stage_questions',
            params: {
              'p_stage_id': stageId,
              'p_limit': limit.clamp(3, 16),
            },
          );

    final rows = List<Map<String, dynamic>>.from(response);
    final questions = <BossBattleQuestion>[];

    for (final row in rows) {
      final id = '${row['id'] ?? ''}'.trim();
      final prompt = '${row['prompt'] ?? ''}'.trim();
      final decodedChoices = _asList(row['choices_text']);
      final decodedCorrect = _asList(row['choices_correct']);

      if (id.isEmpty ||
          prompt.isEmpty ||
          decodedChoices == null ||
          decodedCorrect == null ||
          decodedChoices.length != decodedCorrect.length) {
        continue;
      }

      final answers = <String>[];
      String? correctAnswer;

      for (var i = 0; i < decodedChoices.length; i++) {
        final answer = '${decodedChoices[i]}'.trim();
        if (answer.isEmpty || answers.contains(answer)) continue;
        answers.add(answer);

        final flag = decodedCorrect[i];
        final isCorrect = flag == true ||
            (flag is num && flag.toInt() == 1) ||
            '$flag' == '1';
        if (isCorrect) correctAnswer = answer;
      }

      if (answers.length < 2 ||
          correctAnswer == null ||
          !answers.contains(correctAnswer)) {
        continue;
      }

      questions.add(
        BossBattleQuestion(
          id: id,
          prompt: prompt,
          answers: answers,
          correctAnswer: correctAnswer,
          audioUrl: _cleanUrl(row['tts']),
          slowAudioUrl: _cleanUrl(row['slow_tts']),
        ),
      );
    }

    return questions;
  }

  static String? _cleanUrl(dynamic value) {
    final url = '${value ?? ''}'.trim();
    return url.isEmpty ? null : url;
  }

  static List<dynamic>? _asList(dynamic value) {
    if (value is List) return value;
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        return decoded is List ? decoded : null;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> close() async {}
}
