enum WritingPathNodeState {
  completed,
  current,
  available,
  locked,
  unavailable,
}

class WritingHskCatalogItem {
  const WritingHskCatalogItem({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.sectionCount,
    required this.mappedCharacterCount,
  });

  final int id;
  final String name;
  final int sortOrder;
  final int sectionCount;
  final int mappedCharacterCount;

  factory WritingHskCatalogItem.fromMap(Map<String, dynamic> map) {
    return WritingHskCatalogItem(
      id: (map['hsk_level_id'] as num?)?.toInt() ?? 0,
      name: '${map['name'] ?? 'HSK'}',
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      sectionCount: (map['section_count'] as num?)?.toInt() ?? 0,
      mappedCharacterCount:
          (map['mapped_character_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class WritingCharacterProgress {
  const WritingCharacterProgress({
    this.practiceCount = 0,
    this.bestScore = 0,
    this.lastScore = 0,
    this.nextReviewAt,
  });

  final int practiceCount;
  final double bestScore;
  final double lastScore;
  final DateTime? nextReviewAt;

  bool get hasPracticed => practiceCount > 0 || bestScore > 0;
}

class WritingPathNode {
  const WritingPathNode({
    required this.hskLevelId,
    required this.sectionId,
    required this.sectionTitle,
    required this.sectionOrder,
    required this.nodeOrder,
    required this.characterId,
    required this.character,
    required this.strokeCount,
    required this.strokeWidth,
    required this.strokeHeight,
    required this.strokePaths,
    required this.metadataQuality,
    required this.contextWordId,
    required this.contextWord,
    this.characterPinyin,
    this.characterMeaningVi,
    this.contextPinyin,
    this.contextMeaningVi,
    this.sourceRow,
    this.progress = const WritingCharacterProgress(),
    this.state = WritingPathNodeState.locked,
    this.lockReason,
  });

  final int hskLevelId;
  final int sectionId;
  final String sectionTitle;
  final int sectionOrder;
  final int nodeOrder;
  final int characterId;
  final String character;
  final String? characterPinyin;
  final String? characterMeaningVi;
  final int contextWordId;
  final String contextWord;
  final String? contextPinyin;
  final String? contextMeaningVi;
  final int? sourceRow;
  final int strokeCount;
  final double strokeWidth;
  final double strokeHeight;
  final String strokePaths;
  final String metadataQuality;
  final WritingCharacterProgress progress;
  final WritingPathNodeState state;
  final String? lockReason;

  bool get hasStrokeData => strokeCount > 0 && strokePaths.trim().isNotEmpty;
  bool get hasCharacterMetadata =>
      characterPinyin?.trim().isNotEmpty == true &&
      characterMeaningVi?.trim().isNotEmpty == true;

  String? get displayPinyin =>
      characterPinyin?.trim().isNotEmpty == true ? characterPinyin : null;
  String? get displayMeaning =>
      characterMeaningVi?.trim().isNotEmpty == true
          ? characterMeaningVi
          : null;

  WritingPathNode copyWith({
    WritingCharacterProgress? progress,
    WritingPathNodeState? state,
    String? lockReason,
  }) {
    return WritingPathNode(
      hskLevelId: hskLevelId,
      sectionId: sectionId,
      sectionTitle: sectionTitle,
      sectionOrder: sectionOrder,
      nodeOrder: nodeOrder,
      characterId: characterId,
      character: character,
      characterPinyin: characterPinyin,
      characterMeaningVi: characterMeaningVi,
      contextWordId: contextWordId,
      contextWord: contextWord,
      contextPinyin: contextPinyin,
      contextMeaningVi: contextMeaningVi,
      sourceRow: sourceRow,
      strokeCount: strokeCount,
      strokeWidth: strokeWidth,
      strokeHeight: strokeHeight,
      strokePaths: strokePaths,
      metadataQuality: metadataQuality,
      progress: progress ?? this.progress,
      state: state ?? this.state,
      lockReason: lockReason,
    );
  }

  factory WritingPathNode.fromMap(Map<String, dynamic> map) {
    return WritingPathNode(
      hskLevelId: (map['hsk_level_id'] as num?)?.toInt() ?? 0,
      sectionId: (map['section_id'] as num?)?.toInt() ?? 0,
      sectionTitle: '${map['section_title'] ?? 'Section'}',
      sectionOrder: (map['section_order'] as num?)?.toInt() ?? 0,
      nodeOrder: (map['node_order'] as num?)?.toInt() ?? 0,
      characterId: (map['character_id'] as num?)?.toInt() ?? 0,
      character: '${map['character'] ?? ''}',
      characterPinyin: map['character_pinyin']?.toString(),
      characterMeaningVi: map['character_meaning_vi']?.toString(),
      contextWordId: (map['context_word_id'] as num?)?.toInt() ?? 0,
      contextWord: '${map['context_word'] ?? ''}',
      contextPinyin: map['context_pinyin']?.toString(),
      contextMeaningVi: map['context_meaning_vi']?.toString(),
      sourceRow: (map['source_row'] as num?)?.toInt(),
      strokeCount: (map['stroke_count'] as num?)?.toInt() ?? 0,
      strokeWidth: (map['stroke_width'] as num?)?.toDouble() ?? 110,
      strokeHeight: (map['stroke_height'] as num?)?.toDouble() ?? 110,
      strokePaths: '${map['stroke_paths'] ?? ''}',
      metadataQuality: '${map['metadata_quality'] ?? 'unknown'}',
    );
  }
}

class WritingPathSection {
  const WritingPathSection({
    required this.id,
    required this.title,
    required this.order,
    required this.nodes,
    required this.unlocked,
  });

  final int id;
  final String title;
  final int order;
  final List<WritingPathNode> nodes;
  final bool unlocked;

  int get completedCount => nodes
      .where((node) => node.state == WritingPathNodeState.completed)
      .length;
  int get requiredCount => nodes.where((node) => node.hasStrokeData).length;
  int get metadataIssueCount => nodes
      .where((node) => !node.hasStrokeData || !node.hasCharacterMetadata)
      .length;
  bool get completed =>
      requiredCount > 0 && completedCount >= requiredCount;
}

class WritingHskPath {
  const WritingHskPath({
    required this.catalog,
    required this.sections,
  });

  final WritingHskCatalogItem catalog;
  final List<WritingPathSection> sections;

  int get completedCount =>
      sections.fold(0, (sum, section) => sum + section.completedCount);
  int get requiredCount =>
      sections.fold(0, (sum, section) => sum + section.requiredCount);
  bool get completed =>
      requiredCount > 0 && completedCount >= requiredCount;
}
