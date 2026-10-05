import 'dart:math' as math;

const int defaultPracticeRoundCount = 10;

enum HanziPracticeMode {
  guidedTrace,
  completeRemaining,
  faintCharacter,
  startPointOnly,
  fromScratch,
}

class HanziPracticeRoundConfig {
  final int roundNumber;
  final HanziPracticeMode mode;
  final int prefilledStrokeCount;
  final double guideOpacity;
  final bool showCurrentStroke;
  final bool showStartPoint;
  final bool showDirectionArrow;
  final bool allowHideGuide;

  const HanziPracticeRoundConfig({
    required this.roundNumber,
    required this.mode,
    this.prefilledStrokeCount = 0,
    this.guideOpacity = 0.0,
    this.showCurrentStroke = false,
    this.showStartPoint = false,
    this.showDirectionArrow = false,
    this.allowHideGuide = true,
  });
}

class HanziRoundResult {
  final int roundNumber;
  final HanziPracticeMode mode;
  final int drawnStrokeCount;
  final int attemptCount;
  final double score;
  final int durationMilliseconds;

  const HanziRoundResult({
    required this.roundNumber,
    required this.mode,
    required this.drawnStrokeCount,
    required this.attemptCount,
    required this.score,
    required this.durationMilliseconds,
  });
}

int calculatePrefilledStrokeCount({
  required int strokeCount,
  required double ratio,
}) {
  if (strokeCount <= 1) {
    return 0;
  }

  return (strokeCount * ratio).floor().clamp(1, strokeCount - 1);
}

List<HanziPracticeRoundConfig> generateRoundConfigs(int strokeCount) {
  return [
    // Round 1: guidedTrace, full guide, orange hint, start point and direction arrow
    HanziPracticeRoundConfig(
      roundNumber: 1,
      mode: HanziPracticeMode.guidedTrace,
      prefilledStrokeCount: 0,
      guideOpacity: 0.35,
      showCurrentStroke: true,
      showStartPoint: true,
      showDirectionArrow: true,
      allowHideGuide: true,
    ),
    // Round 2: guidedTrace, fainter guide, orange hint, start point, no arrow
    HanziPracticeRoundConfig(
      roundNumber: 2,
      mode: HanziPracticeMode.guidedTrace,
      prefilledStrokeCount: 0,
      guideOpacity: 0.15,
      showCurrentStroke: true,
      showStartPoint: true,
      showDirectionArrow: false,
      allowHideGuide: true,
    ),
    // Round 3: completeRemaining, 1 stroke prefilled
    HanziPracticeRoundConfig(
      roundNumber: 3,
      mode: HanziPracticeMode.completeRemaining,
      prefilledStrokeCount: strokeCount <= 1 ? 0 : 1,
      guideOpacity: 0.15,
      showCurrentStroke: true,
      showStartPoint: true,
      showDirectionArrow: false,
      allowHideGuide: true,
    ),
    // Round 4: completeRemaining, 25% strokes prefilled
    HanziPracticeRoundConfig(
      roundNumber: 4,
      mode: HanziPracticeMode.completeRemaining,
      prefilledStrokeCount:
          calculatePrefilledStrokeCount(strokeCount: strokeCount, ratio: 0.25),
      guideOpacity: 0.15,
      showCurrentStroke: true,
      showStartPoint: true,
      showDirectionArrow: false,
      allowHideGuide: true,
    ),
    // Round 5: completeRemaining, 50% strokes prefilled
    HanziPracticeRoundConfig(
      roundNumber: 5,
      mode: HanziPracticeMode.completeRemaining,
      prefilledStrokeCount:
          calculatePrefilledStrokeCount(strokeCount: strokeCount, ratio: 0.50),
      guideOpacity: 0.15,
      showCurrentStroke: true,
      showStartPoint: true,
      showDirectionArrow: false,
      allowHideGuide: true,
    ),
    // Round 6: faintCharacter, very faint character template, no prefilled, no orange highlight
    HanziPracticeRoundConfig(
      roundNumber: 6,
      mode: HanziPracticeMode.faintCharacter,
      prefilledStrokeCount: 0,
      guideOpacity: 0.08,
      showCurrentStroke: false,
      showStartPoint: false,
      showDirectionArrow: false,
      allowHideGuide: true,
    ),
    // Round 7: faintCharacter, even fainter, only start point of current stroke shown
    HanziPracticeRoundConfig(
      roundNumber: 7,
      mode: HanziPracticeMode.faintCharacter,
      prefilledStrokeCount: 0,
      guideOpacity: 0.03,
      showCurrentStroke: false,
      showStartPoint: true,
      showDirectionArrow: false,
      allowHideGuide: true,
    ),
    // Round 8: startPointOnly, no character template, start point and arrow shown
    HanziPracticeRoundConfig(
      roundNumber: 8,
      mode: HanziPracticeMode.startPointOnly,
      prefilledStrokeCount: 0,
      guideOpacity: 0.0,
      showCurrentStroke: false,
      showStartPoint: true,
      showDirectionArrow: true,
      allowHideGuide: false,
    ),
    // Round 9: fromScratch, blank board, draw from memory, no hint, start point or guide
    HanziPracticeRoundConfig(
      roundNumber: 9,
      mode: HanziPracticeMode.fromScratch,
      prefilledStrokeCount: 0,
      guideOpacity: 0.0,
      showCurrentStroke: false,
      showStartPoint: false,
      showDirectionArrow: false,
      allowHideGuide: false,
    ),
    // Round 10: fromScratch, final test, blank board, strict validation
    HanziPracticeRoundConfig(
      roundNumber: 10,
      mode: HanziPracticeMode.fromScratch,
      prefilledStrokeCount: 0,
      guideOpacity: 0.0,
      showCurrentStroke: false,
      showStartPoint: false,
      showDirectionArrow: false,
      allowHideGuide: false,
    ),
  ];
}
