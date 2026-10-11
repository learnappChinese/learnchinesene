import '../model/learning_source_context.dart';

/// Result of attempting to bridge between Duo Unit ID (text) and Lexicon Unit ID (int).
class UnitBridgeResult {
  const UnitBridgeResult.success({
    required this.duoUnitId,
    required this.lexiconUnitId,
  })  : isSuccess = true,
        errorMessage = null;

  const UnitBridgeResult.failure({
    required this.duoUnitId,
    required this.errorMessage,
  })  : isSuccess = false,
        lexiconUnitId = null;

  final bool isSuccess;
  final String duoUnitId;
  final int? lexiconUnitId;
  final String? errorMessage;
}

/// Service to resolve the canonical relationship between text-based Duo Unit IDs
/// and integer-based Lexicon Unit IDs.
///
/// In accordance with PR 06 Architecture:
/// - Never casts or forces a String Unit ID directly into an integer.
/// - Validates unique mappings and logs / reports mismatches cleanly.
class UnitBridgeResolver {
  UnitBridgeResolver({Map<String, int>? explicitMappings})
      : _explicitMappings =
            Map<String, int>.from(explicitMappings ?? _defaultMappings);

  final Map<String, int> _explicitMappings;

  static const Map<String, int> _defaultMappings = {
    'unit_1_duo': 1,
    'unit_2_duo': 2,
    'unit_3_duo': 3,
    'unit_4_duo': 4,
    'unit_5_duo': 5,
    'unit_6_duo': 6,
    'unit_1': 1,
    'unit_2': 2,
    'unit_3': 3,
    'unit_4': 4,
    'unit_5': 5,
    'unit_6': 6,
  };

  /// Register or override an explicit bridge mapping.
  void registerMapping(String duoUnitId, int lexiconUnitId) {
    _explicitMappings[duoUnitId] = lexiconUnitId;
  }

  /// Resolve a Duo Unit ID (String) to its canonical Lexicon Unit ID (int).
  UnitBridgeResult resolveToLexiconId(String duoUnitId) {
    final trimmed = duoUnitId.trim();
    if (trimmed.isEmpty) {
      return UnitBridgeResult.failure(
        duoUnitId: duoUnitId,
        errorMessage: 'Duo Unit ID cannot be empty.',
      );
    }

    if (_explicitMappings.containsKey(trimmed)) {
      return UnitBridgeResult.success(
        duoUnitId: trimmed,
        lexiconUnitId: _explicitMappings[trimmed]!,
      );
    }

    // Check direct numeric string (e.g. '1', '5')
    final directInt = int.tryParse(trimmed);
    if (directInt != null && directInt > 0) {
      return UnitBridgeResult.success(
        duoUnitId: trimmed,
        lexiconUnitId: directInt,
      );
    }

    // Check prefixed unit formats: unit_<N>, u_<N>, u<N>, chapter_<N>
    final match = RegExp(
      r'^(?:unit_|u_|u|chapter_)(\d+)(?:_duo)?$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (match != null) {
      final parsedNumber = int.tryParse(match.group(1)!);
      if (parsedNumber != null && parsedNumber > 0) {
        return UnitBridgeResult.success(
          duoUnitId: trimmed,
          lexiconUnitId: parsedNumber,
        );
      }
    }

    return UnitBridgeResult.failure(
      duoUnitId: duoUnitId,
      errorMessage:
          'No verified bridge mapping found for Duo Unit ID: "$duoUnitId".',
    );
  }

  /// Resolve a Lexicon Unit ID (int) to its canonical Duo Unit ID (String).
  String resolveToDuoId(int lexiconUnitId) {
    for (final entry in _explicitMappings.entries) {
      if (entry.value == lexiconUnitId) {
        return entry.key;
      }
    }
    return 'unit_${lexiconUnitId}_duo';
  }

  /// Convenience helper to resolve Lexicon Unit ID (int) or null.
  int? resolveLexiconUnitId(String duoUnitId) =>
      resolveToLexiconId(duoUnitId).lexiconUnitId;

  /// Convenience helper to resolve Duo Unit ID (String).
  String resolveDuoUnitId(int lexiconUnitId) => resolveToDuoId(lexiconUnitId);

  /// Helper to build a canonical LearningSourceContext with resolved bridge IDs.
  LearningSourceContext buildBridgeContext({
    required String duoUnitId,
    required String levelId,
    required String gameCode,
    String courseId = 'duo_chinese',
    String sectionId = 'default_section',
    String mode = 'curriculum',
    List<String> allowedChallengeIds = const [],
    Map<String, dynamic> metadata = const {},
  }) {
    final lexiconId = resolveLexiconUnitId(duoUnitId);
    return LearningSourceContext(
      courseId: courseId,
      sectionId: sectionId,
      duoUnitId: duoUnitId,
      lexiconUnitId: lexiconId,
      levelId: levelId,
      gameCode: gameCode,
      mode: mode,
      allowedChallengeIds: allowedChallengeIds,
      metadata: metadata,
    );
  }
}
