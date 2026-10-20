import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/database/app_database.dart';
import '../../../core/models/hanzi_character.dart';
import '../../../core/presentation/learning_presentation_mapper.dart';
import '../models/hanzi_path_models.dart';
import '../services/hanzi_stroke_cache.dart';

class HanziLearningPathController extends GetxController {
  final hskLevels = <HanziPathHskLevel>[].obs;
  final isLoading = true.obs;
  final errorMessage = RxnString();

  final totalXp = 0.obs;
  final currentStreak = 0.obs;
  final totalMasteredCount = 0.obs;

  final selectedHskFilter = 0.obs; // 0 = Tất cả, 1 = HSK 1, 2 = HSK 2...
  final currentNode = Rxn<HanziPathNode>();

  final scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    loadLearningPath();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  Future<void> loadLearningPath() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      if (AppDatabase.instance.isOpen) {
        totalXp.value = await AppDatabase.instance.getTotalXp();
        currentStreak.value = await AppDatabase.instance.getCurrentStreak();
        totalMasteredCount.value =
            await AppDatabase.instance.getTotalMasteredHanziCount();

        final rawData = await AppDatabase.instance.getHanziLearningPathRaw();
        final parsedLevels = _buildPathHierarchy(rawData);
        hskLevels.assignAll(parsedLevels);

        // Xác định node đang học gần nhất
        _identifyCurrentLearningNode();

        // Tải trước cache các nét chữ cho các chữ học gần nhất (tối đa 30 chữ để mượt mà)
        final prefetchChars = <HanziCharacter>[];
        for (final lvl in parsedLevels) {
          for (final sec in lvl.sections) {
            for (final n in sec.nodes) {
              if (prefetchChars.length < 30) {
                prefetchChars.add(n.character);
              }
            }
          }
        }
        HanziStrokeCache.instance.prefetch(prefetchChars);
      } else {
        errorMessage.value = 'Cơ sở dữ liệu cục bộ chưa sẵn sàng.';
      }
    } catch (e) {
      errorMessage.value = 'Không thể tải lộ trình học viết: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Làm mới lại tiến độ sau khi hoàn thành một bài viết chữ
  Future<void> refreshProgress() async {
    try {
      if (AppDatabase.instance.isOpen) {
        totalXp.value = await AppDatabase.instance.getTotalXp();
        currentStreak.value = await AppDatabase.instance.getCurrentStreak();
        totalMasteredCount.value =
            await AppDatabase.instance.getTotalMasteredHanziCount();

        final rawData = await AppDatabase.instance.getHanziLearningPathRaw();
        final parsedLevels = _buildPathHierarchy(rawData);
        hskLevels.assignAll(parsedLevels);
        _identifyCurrentLearningNode();
      }
    } catch (_) {}
  }

  List<HanziPathHskLevel> _buildPathHierarchy(
    List<Map<String, dynamic>> rawData,
  ) {
    final List<HanziPathHskLevel> result = [];
    int globalNodeIndex = 0;
    bool foundFirstInProgress = false;
    bool previousHskCompleted = true;

    for (int lvlIdx = 0; lvlIdx < rawData.length; lvlIdx++) {
      final lvlData = rawData[lvlIdx];
      final lvlMap = lvlData['level'] as Map<String, dynamic>;
      final lvlId = (lvlMap['id'] as num?)?.toInt() ?? (lvlIdx + 1);
      final lvlName = '${lvlMap['name'] ?? 'HSK $lvlId'}';
      final lvlDesc = '${lvlMap['description'] ?? 'Cấp độ $lvlId'}';
      final sectionsData =
          lvlData['sections'] as List<Map<String, dynamic>>? ?? [];

      final isHskUnlocked = lvlIdx == 0 || previousHskCompleted;
      bool previousSectionCompleted = true;
      final List<HanziPathSection> parsedSections = [];

      for (int secIdx = 0; secIdx < sectionsData.length; secIdx++) {
        final secData = sectionsData[secIdx];
        final unitMap = secData['unit'] as Map<String, dynamic>;
        final unitId = (unitMap['id'] as num?)?.toInt() ?? (secIdx + 1);
        final unitNumber =
            (unitMap['unit_number'] as num?)?.toInt() ?? (secIdx + 1);
        final rawTitle = '${unitMap['title'] ?? 'Bài $unitNumber'}';
        final sectionTitle =
            LearningPresentationMapper.unitTitle(rawTitle, unitNumber);
        final rawChars =
            secData['characters'] as List<Map<String, dynamic>>? ?? [];

        final isSectionUnlocked =
            isHskUnlocked && (secIdx == 0 || previousSectionCompleted);
        final List<HanziPathNode> parsedNodes = [];

        for (int charIdx = 0; charIdx < rawChars.length; charIdx++) {
          final cMap = rawChars[charIdx];
          final charObj = HanziCharacter.fromMap({
            'id': cMap['id'],
            'character': cMap['character'],
            'stroke_count': cMap['stroke_count'],
            'stroke_width': cMap['stroke_width'],
            'stroke_height': cMap['stroke_height'],
            'stroke_paths': cMap['stroke_paths'] ?? '',
            'pinyin': cMap['pinyin'] ?? '',
            'meaning': cMap['meaning_vi'] ?? '',
            'hsk_level_id': lvlId,
            'practice_count': cMap['practice_count'] ?? 0,
            'best_score': (cMap['best_score'] as num?)?.toDouble() ?? 0.0,
          });

          final practiceCount = (cMap['practice_count'] as num?)?.toInt() ?? 0;
          final bestScore = (cMap['best_score'] as num?)?.toDouble() ?? 0.0;
          final isMastered = cMap['is_mastered'] == 1 || bestScore >= 80.0;

          WritingNodeState state;
          if (!isSectionUnlocked) {
            state = WritingNodeState.locked;
          } else if (isMastered) {
            state = WritingNodeState.completed;
          } else if (!foundFirstInProgress) {
            state = WritingNodeState.inProgress;
            foundFirstInProgress = true;
          } else {
            // Các chữ còn lại trong section đã mở: 2 chữ tiếp theo là available, còn lại là locked tuần tự
            final prevCharCompleted = charIdx > 0 &&
                (parsedNodes[charIdx - 1].state == WritingNodeState.completed ||
                    parsedNodes[charIdx - 1].state ==
                        WritingNodeState.inProgress);
            state = prevCharCompleted
                ? WritingNodeState.available
                : WritingNodeState.locked;
          }

          final node = HanziPathNode(
            character: charObj,
            sectionId: unitId,
            hskLevel: lvlId,
            indexInSection: charIdx,
            globalIndex: globalNodeIndex++,
            state: state,
            bestScore: bestScore,
            practiceCount: practiceCount,
            isMastered: isMastered,
          );
          parsedNodes.add(node);
        }

        final section = HanziPathSection(
          id: unitId,
          hskLevel: lvlId,
          sectionNumber: unitNumber,
          title: sectionTitle,
          description: rawTitle,
          nodes: parsedNodes,
          isUnlocked: isSectionUnlocked,
        );
        parsedSections.add(section);
        previousSectionCompleted = section.isCompleted;
      }

      final hskLevel = HanziPathHskLevel(
        level: lvlId,
        name: lvlName,
        description: lvlDesc,
        sections: parsedSections,
        isUnlocked: isHskUnlocked,
      );
      result.add(hskLevel);
      previousHskCompleted = hskLevel.isCompleted;
    }

    return result;
  }

  void _identifyCurrentLearningNode() {
    for (final lvl in hskLevels) {
      for (final sec in lvl.sections) {
        for (final node in sec.nodes) {
          if (node.state == WritingNodeState.inProgress) {
            currentNode.value = node;
            return;
          }
        }
      }
    }
    // Nếu tất cả đã hoàn thành, chọn node cuối cùng
    for (final lvl in hskLevels.reversed) {
      for (final sec in lvl.sections.reversed) {
        if (sec.nodes.isNotEmpty) {
          currentNode.value = sec.nodes.last;
          return;
        }
      }
    }
  }

  void scrollToCurrentNode() {
    final node = currentNode.value;
    if (node == null || !scrollController.hasClients) return;

    final targetOffset = calculateApproximateOffsetForNode(node);
    scrollController.animateTo(
      targetOffset.clamp(0.0, scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  double calculateApproximateOffsetForNode(HanziPathNode target) {
    double offset = 0.0;
    for (final lvl in filteredHskLevels) {
      for (final sec in lvl.sections) {
        offset += 130.0; // Khoảng chiều cao banner Section
        final idx = sec.nodes.indexOf(target);
        if (idx != -1) {
          offset += idx * 126.0;
          return offset;
        } else {
          offset += sec.nodes.length * 126.0;
        }
      }
      offset += 100.0; // Milestone card
    }
    return offset;
  }

  void setHskFilter(int level) {
    selectedHskFilter.value = level;
  }

  List<HanziPathHskLevel> get filteredHskLevels {
    if (selectedHskFilter.value == 0) {
      return hskLevels;
    }
    return hskLevels
        .where((lvl) => lvl.level == selectedHskFilter.value)
        .toList();
  }
}
