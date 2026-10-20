import '../../../core/models/hanzi_character.dart';

/// Trạng thái của một nút chữ Hán trên lộ trình học (Learning Path).
enum WritingNodeState {
  /// Đã hoàn thành và ghi nhớ (xanh lá, có dấu tích).
  completed,

  /// Đang học - nút hiện tại người học cần tiếp tục (nổi bật, hiệu ứng pulse, biểu tượng bút chì).
  inProgress,

  /// Có thể bắt đầu học (sáng màu, chữ rõ).
  available,

  /// Chưa mở khóa (màu xám nhạt, có biểu tượng khóa).
  locked,
}

/// Nút chữ Hán trên lộ trình học tập zigzag.
class HanziPathNode {
  final HanziCharacter character;
  final int sectionId;
  final int hskLevel;
  final int indexInSection;
  final int globalIndex;
  final WritingNodeState state;
  final double bestScore;
  final int practiceCount;
  final bool isMastered;

  const HanziPathNode({
    required this.character,
    required this.sectionId,
    required this.hskLevel,
    required this.indexInSection,
    required this.globalIndex,
    required this.state,
    this.bestScore = 0.0,
    this.practiceCount = 0,
    this.isMastered = false,
  });

  HanziPathNode copyWith({
    HanziCharacter? character,
    int? sectionId,
    int? hskLevel,
    int? indexInSection,
    int? globalIndex,
    WritingNodeState? state,
    double? bestScore,
    int? practiceCount,
    bool? isMastered,
  }) {
    return HanziPathNode(
      character: character ?? this.character,
      sectionId: sectionId ?? this.sectionId,
      hskLevel: hskLevel ?? this.hskLevel,
      indexInSection: indexInSection ?? this.indexInSection,
      globalIndex: globalIndex ?? this.globalIndex,
      state: state ?? this.state,
      bestScore: bestScore ?? this.bestScore,
      practiceCount: practiceCount ?? this.practiceCount,
      isMastered: isMastered ?? this.isMastered,
    );
  }
}

/// Phần học (Section / Unit) chứa danh sách các chữ Hán thuộc chủ đề đó.
class HanziPathSection {
  final int id;
  final int hskLevel;
  final int sectionNumber;
  final String title;
  final String description;
  final List<HanziPathNode> nodes;
  final bool isUnlocked;

  const HanziPathSection({
    required this.id,
    required this.hskLevel,
    required this.sectionNumber,
    required this.title,
    required this.description,
    required this.nodes,
    required this.isUnlocked,
  });

  int get totalCount => nodes.length;

  int get completedCount =>
      nodes.where((n) => n.state == WritingNodeState.completed).length;

  double get progress =>
      totalCount == 0 ? 0.0 : (completedCount / totalCount).clamp(0.0, 1.0);

  bool get isCompleted => totalCount > 0 && completedCount >= totalCount;
}

/// Cấp độ HSK chứa danh sách các Section trên lộ trình.
class HanziPathHskLevel {
  final int level;
  final String name;
  final String description;
  final List<HanziPathSection> sections;
  final bool isUnlocked;

  const HanziPathHskLevel({
    required this.level,
    required this.name,
    required this.description,
    required this.sections,
    required this.isUnlocked,
  });

  int get totalCharacters =>
      sections.fold<int>(0, (sum, s) => sum + s.totalCount);

  int get completedCharacters =>
      sections.fold<int>(0, (sum, s) => sum + s.completedCount);

  double get progress => totalCharacters == 0
      ? 0.0
      : (completedCharacters / totalCharacters).clamp(0.0, 1.0);

  bool get isCompleted =>
      totalCharacters > 0 && completedCharacters >= totalCharacters;
}
