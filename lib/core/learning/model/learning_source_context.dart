abstract final class LearningMode {
  static const String duoMission = 'curriculum';
  static const String reviewSession = 'review';
  static const String practice = 'practice';
  static const String boss = 'boss';
}

/// Canonical source context for any learning activity in the adventure.
///
/// Ensures clear data ownership boundaries:
/// - Distinguishes between text-based Duo Unit ID and integer-based Lexicon Unit ID.
/// - Carries curriculum provenance: course, section, unit, level, gameCode, and mode.
/// - Prevents runners and widgets from guessing learning sources by parsing screen titles or indices.
class LearningSourceContext {
  const LearningSourceContext({
    required this.courseId,
    this.sectionId = 'default_section',
    required this.duoUnitId,
    this.lexiconUnitId,
    required this.levelId,
    required this.gameCode,
    this.mode = 'curriculum',
    this.allowedChallengeIds = const [],
    this.metadata = const {},
  });

  /// Canonical course / world identifier (e.g. 'course_hsk1', 'hsk_1').
  final String courseId;

  /// Section identifier within the course (e.g. 'section_1').
  final String sectionId;

  /// Canonical Duo Unit identifier in text format (e.g. 'unit_1_duo').
  final String duoUnitId;

  /// Optional Lexicon Unit identifier in integer format (e.g. 1).
  final int? lexiconUnitId;

  /// Stage / Level identifier (e.g. 'level_1_1').
  final String levelId;

  /// Canonical game or activity code (e.g. 'select_answer', 'learn_words', 'dialogue').
  final String gameCode;

  /// Learning mode: 'curriculum', 'practice', 'review', 'boss'.
  final String mode;

  /// Bounded provenance challenge IDs strictly allowed for this session.
  final List<String> allowedChallengeIds;

  /// Additional extensible contextual data.
  final Map<String, dynamic> metadata;

  bool get isCurriculum => mode == 'curriculum';
  bool get isBoss => mode == 'boss';
  bool get isPractice => mode == 'practice';
  bool get isReview => mode == 'review';

  LearningSourceContext copyWith({
    String? courseId,
    String? sectionId,
    String? duoUnitId,
    int? lexiconUnitId,
    String? levelId,
    String? gameCode,
    String? mode,
    List<String>? allowedChallengeIds,
    Map<String, dynamic>? metadata,
  }) {
    return LearningSourceContext(
      courseId: courseId ?? this.courseId,
      sectionId: sectionId ?? this.sectionId,
      duoUnitId: duoUnitId ?? this.duoUnitId,
      lexiconUnitId: lexiconUnitId ?? this.lexiconUnitId,
      levelId: levelId ?? this.levelId,
      gameCode: gameCode ?? this.gameCode,
      mode: mode ?? this.mode,
      allowedChallengeIds: allowedChallengeIds ?? this.allowedChallengeIds,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'course_id': courseId,
      'section_id': sectionId,
      'duo_unit_id': duoUnitId,
      if (lexiconUnitId != null) 'lexicon_unit_id': lexiconUnitId,
      'level_id': levelId,
      'game_code': gameCode,
      'mode': mode,
      if (allowedChallengeIds.isNotEmpty)
        'allowed_challenge_ids': allowedChallengeIds,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  factory LearningSourceContext.fromJson(Map<String, dynamic> json) {
    return LearningSourceContext(
      courseId: json['course_id']?.toString() ?? '',
      sectionId: json['section_id']?.toString() ?? '',
      duoUnitId: json['duo_unit_id']?.toString() ?? '',
      lexiconUnitId: json['lexicon_unit_id'] is num
          ? (json['lexicon_unit_id'] as num).toInt()
          : int.tryParse(json['lexicon_unit_id']?.toString() ?? ''),
      levelId: json['level_id']?.toString() ?? '',
      gameCode: json['game_code']?.toString() ?? '',
      mode: json['mode']?.toString() ?? 'curriculum',
      allowedChallengeIds: json['allowed_challenge_ids'] is List
          ? (json['allowed_challenge_ids'] as List)
              .map((e) => e.toString())
              .toList()
          : const [],
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : const {},
    );
  }

  @override
  String toString() =>
      'LearningSourceContext(duoUnitId: $duoUnitId, levelId: $levelId, gameCode: $gameCode, mode: $mode)';
}
