import 'learning_source_context.dart';

/// Single item within a composed learning session.
class ComposedChallengeItem {
  const ComposedChallengeItem({
    required this.id,
    required this.type,
    required this.payload,
    required this.unitId,
    required this.orderIndex,
  });

  final String id;
  final String type;
  final dynamic payload;
  final String unitId;
  final int orderIndex;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'payload': payload,
      'unit_id': unitId,
      'order_index': orderIndex,
    };
  }

  factory ComposedChallengeItem.fromJson(Map<String, dynamic> json) {
    return ComposedChallengeItem(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      payload: json['payload'],
      unitId: json['unit_id'] as String? ?? '',
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Fully composed, bounded, and ordered learning session.
class ComposedLearningSession {
  const ComposedLearningSession({
    required this.sessionId,
    required this.sourceContext,
    required this.items,
    this.targetBudget = 8,
    this.currentIndex = 0,
    this.score = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.isResumed = false,
    required this.startedAt,
    this.completedAt,
    this.metadata = const {},
  });

  /// Stable attempt / session identifier.
  final String sessionId;

  /// Canonical source context for this session.
  final LearningSourceContext sourceContext;

  /// Strict bounded, ordered challenges.
  final List<ComposedChallengeItem> items;

  /// Target question budget for this session (e.g. 5-10).
  final int targetBudget;

  /// Current progress index (0-based).
  final int currentIndex;

  /// Accumulated score.
  final int score;

  /// Accumulated correct count.
  final int correctCount;

  /// Accumulated wrong count.
  final int wrongCount;

  /// True if this session was restored from an active session snapshot.
  final bool isResumed;

  /// Timestamp when the attempt was initially started.
  final DateTime startedAt;

  /// Timestamp when completed.
  final DateTime? completedAt;

  /// Extensible metadata.
  final Map<String, dynamic> metadata;

  int get totalItems => items.length;
  int get remainingItems =>
      (items.length - currentIndex).clamp(0, items.length);
  bool get isFinished => currentIndex >= items.length && items.isNotEmpty;
  List<String> get challengeIds => items.map((e) => e.id).toList();

  ComposedLearningSession copyWith({
    String? sessionId,
    LearningSourceContext? sourceContext,
    List<ComposedChallengeItem>? items,
    int? targetBudget,
    int? currentIndex,
    int? score,
    int? correctCount,
    int? wrongCount,
    bool? isResumed,
    DateTime? startedAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ComposedLearningSession(
      sessionId: sessionId ?? this.sessionId,
      sourceContext: sourceContext ?? this.sourceContext,
      items: items ?? this.items,
      targetBudget: targetBudget ?? this.targetBudget,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      isResumed: isResumed ?? this.isResumed,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toSnapshot() {
    return {
      'session_id': sessionId,
      'source_context': sourceContext.toJson(),
      'items': items.map((e) => e.toJson()).toList(),
      'challenge_ids': challengeIds,
      'current_index': currentIndex,
      'score': score,
      'correct_count': correctCount,
      'wrong_count': wrongCount,
      'target_budget': targetBudget,
      'is_resumed': isResumed,
      'started_at': startedAt.toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toSnapshot();

  factory ComposedLearningSession.fromJson(
    Map<String, dynamic> json, {
    List<ComposedChallengeItem>? items,
  }) {
    return ComposedLearningSession(
      sessionId: json['session_id'] as String? ?? '',
      sourceContext: json['source_context'] != null
          ? LearningSourceContext.fromJson(
              Map<String, dynamic>.from(json['source_context'] as Map))
          : const LearningSourceContext(
              courseId: '',
              duoUnitId: '',
              levelId: '',
              gameCode: '',
            ),
      items: items ??
          (json['items'] is List
              ? (json['items'] as List)
                  .map((e) => ComposedChallengeItem.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList()
              : const []),
      targetBudget: (json['target_budget'] as num?)?.toInt() ?? 8,
      currentIndex: (json['current_index'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toInt() ?? 0,
      correctCount: (json['correct_count'] as num?)?.toInt() ?? 0,
      wrongCount: (json['wrong_count'] as num?)?.toInt() ?? 0,
      isResumed: json['is_resumed'] as bool? ?? false,
      startedAt: DateTime.tryParse(json['started_at']?.toString() ?? '') ??
          DateTime.now(),
      completedAt: DateTime.tryParse(json['completed_at']?.toString() ?? ''),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }
}
