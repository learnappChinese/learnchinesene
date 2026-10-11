/// Canonical skill taxonomy and activity type mapping.
///
/// Ensures a unified relation between:
/// Game Code -> Activity Type -> Skill Mastery -> Unit Progress -> Boss Unlock -> Next Unit.
abstract final class LearningSkillTaxonomy {
  /// All 11 supported Duo game codes in the curriculum.
  static const Set<String> supportedGameCodes = <String>{
    'learn_words',
    'select_answer',
    'match_pairs',
    'word_connect',
    'listen_select',
    'translate',
    'gap_fill',
    'tap_complete',
    'sentence_order',
    'dialogue',
    'speaking',
  };

  /// Canonical mapping from gameCode to server-authoritative activityType.
  static const Map<String, String> gameCodeToActivityType = <String, String>{
    'learn_words': 'vocabulary',
    'select_answer': 'vocabulary',
    'match_pairs': 'vocabulary',
    'word_connect': 'vocabulary',
    'translate': 'vocabulary',
    'gap_fill': 'vocabulary',
    'tap_complete': 'vocabulary',
    'sentence_order': 'vocabulary',
    'listen_select': 'listening',
    'dialogue': 'dialogue',
    'speaking': 'speaking',
  };

  /// Canonical mapping from gameCode to primary skill bucket in unit mastery.
  ///
  /// Maps each activity into the 4 supported core buckets:
  /// - 'vocabulary' (vocab recognition, association, contextual sentence construction)
  /// - 'listening' (audio selection, dialogue comprehension)
  /// - 'speaking' (pronunciation, tone, oral practice)
  /// - 'hanzi' (character stroke order, writing)
  static const Map<String, String> gameCodeToSkillBucket = <String, String>{
    'learn_words': 'vocabulary',
    'select_answer': 'vocabulary',
    'match_pairs': 'vocabulary',
    'word_connect': 'vocabulary',
    'translate': 'vocabulary',
    'gap_fill': 'vocabulary',
    'tap_complete': 'vocabulary',
    'sentence_order': 'vocabulary',
    'listen_select': 'listening',
    'dialogue': 'listening',
    'speaking': 'speaking',
  };

  /// Resolve activity type for a given Duo game code.
  static String activityTypeForGameCode(String gameCode) {
    return gameCodeToActivityType[gameCode] ?? 'vocabulary';
  }

  /// Resolve primary skill bucket for an activity and optional game code.
  ///
  /// Safely resolves historical 'game_mission' rows based on their game_code
  /// metadata without losing progress or requiring schema mutation.
  static String skillBucketFor({
    required String activityType,
    String? gameCode,
  }) {
    final normalizedActivity = activityType.toLowerCase().trim();
    if (normalizedActivity == 'hanzi') return 'hanzi';
    if (normalizedActivity == 'speaking') return 'speaking';
    if (normalizedActivity == 'listening') return 'listening';
    if (normalizedActivity == 'dialogue') return 'listening';
    if (normalizedActivity == 'vocabulary') return 'vocabulary';

    if (normalizedActivity == 'game_mission') {
      final code = (gameCode ?? '').toLowerCase().trim();
      return gameCodeToSkillBucket[code] ?? 'vocabulary';
    }

    return 'vocabulary';
  }
}
