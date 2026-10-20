import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/learning/model/learning_source_context.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/widgets/adventure_quest_banner.dart';
import '../../../core/widgets/learning_scene_background.dart';
import '../../../core/widgets/learning_scaffold.dart';
import '../../../core/widgets/panda_companion.dart';
import '../controller/writing_learning_path_controller.dart';
import '../models/writing_path_models.dart';
import '../services/writing_learning_path_repository.dart';
import '../widget/hsk_writing_section_banner.dart';
import '../widget/writing_path_node.dart';
import 'hanzi_writing_screen.dart';

class WritingLearningPathPage extends StatefulWidget {
  const WritingLearningPathPage({
    super.key,
    this.sourceContext,
  });

  final LearningSourceContext? sourceContext;

  static bool get enabled => WritingLearningPathRepository.previewEnabled;

  @override
  State<WritingLearningPathPage> createState() =>
      _WritingLearningPathPageState();
}

class _WritingLearningPathPageState extends State<WritingLearningPathPage> {
  static int _controllerSequence = 0;
  late final String _controllerTag;
  late final WritingLearningPathController controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controllerTag = 'writing-path-${_controllerSequence++}';
    controller =
        Get.put(WritingLearningPathController(), tag: _controllerTag);
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    Get.delete<WritingLearningPathController>(tag: _controllerTag);
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent - position.pixels < 700) {
      controller.loadNextHsk();
    }
  }

  Future<void> _openNode(WritingPathNode node) async {
    if (node.state == WritingPathNodeState.locked ||
        node.state == WritingPathNodeState.unavailable) {
      await _showLockedNode(node);
      return;
    }
    await _showNodePreview(node);
  }

  Future<void> _showLockedNode(WritingPathNode node) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                node.character,
                style: const TextStyle(
                  fontSize: 58,
                  fontFamily: 'FZKaiTiPinyin',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Icon(
                node.state == WritingPathNodeState.unavailable
                    ? Icons.warning_amber_rounded
                    : Icons.lock_rounded,
                color: const Color(0xFF94A3B8),
              ),
              const SizedBox(height: 8),
              Text(
                node.lockReason ?? 'Bài viết chữ này chưa thể bắt đầu.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showNodePreview(WritingPathNode node) async {
    final completed = node.state == WritingPathNodeState.completed;
    final standaloneMetadata = node.hasCharacterMetadata;
    final action = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                node.character,
                style: const TextStyle(
                  fontFamily: 'FZKaiTiPinyin',
                  fontSize: 68,
                  fontWeight: FontWeight.w700,
                  color: GameVisualTokens.templeWood,
                ),
              ),
              if (standaloneMetadata) ...[
                Text(
                  node.displayPinyin!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GameVisualTokens.crimsonDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  node.displayMeaning!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15),
                ),
              ] else ...[
                const Text(
                  'Chưa có pinyin/nghĩa riêng đã kiểm duyệt cho chữ này.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Xuất hiện trong từ: ${node.contextWord}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (node.contextPinyin?.trim().isNotEmpty == true)
                  Text(node.contextPinyin!),
                if (node.contextMeaningVi?.trim().isNotEmpty == true)
                  Text(
                    node.contextMeaningVi!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
              ],
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.brush_rounded,
                    text: '${node.strokeCount} nét',
                  ),
                  _InfoChip(
                    icon: Icons.star_rounded,
                    text: node.progress.practiceCount == 0
                        ? 'Chưa luyện'
                        : 'Tốt nhất ${node.progress.bestScore.round()}%',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: Icon(completed
                      ? Icons.refresh_rounded
                      : Icons.edit_rounded),
                  label: Text(
                    completed ? 'LUYỆN VIẾT LẠI' : 'BẮT ĐẦU VIẾT',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (action != true || !mounted) return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => HanziWritingScreen(
          characterId: node.characterId,
          sourceContext: widget.sourceContext,
          returnToLearningPath: true,
        ),
      ),
    );
    if (mounted) await controller.refreshCurrent();
  }

  Future<void> _chooseHsk() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: Obx(
          () => ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            children: [
              const ListTile(
                title: Text(
                  'Chọn nhanh cấp HSK',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text('Danh sách lấy trực tiếp từ database hiện tại.'),
              ),
              ...controller.catalog.map(
                (item) => ListTile(
                  leading: const Icon(Icons.route_rounded),
                  title: Text(item.name),
                  subtitle: Text(
                    '${item.sectionCount} Section'
                    '${item.mappedCharacterCount > 0 ? " • ${item.mappedCharacterCount} chữ" : ""}',
                  ),
                  onTap: () => Navigator.pop(context, item.id),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    await controller.jumpToHsk(selected);
    if (!mounted || !_scrollController.hasClients) return;
    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: 'Con đường luyện viết',
      actions: [
        IconButton(
          tooltip: 'Chọn HSK / Section',
          icon: const Icon(Icons.travel_explore_rounded),
          onPressed: _chooseHsk,
        ),
        IconButton(
          tooltip: 'Làm mới tiến độ',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: controller.refreshCurrent,
        ),
      ],
      body: LearningSceneBackground(
        theme: LearningSceneTheme.bambooVillage,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.errorMessage.value != null) {
            return _ErrorState(
              message: controller.errorMessage.value!,
              retry: controller.loadInitial,
            );
          }
          if (controller.catalog.isEmpty || controller.loadedPaths.isEmpty) {
            return const Center(
              child: Text('Database chưa có lộ trình luyện viết phù hợp.'),
            );
          }

          final recommendation = controller.recommendation;
          final recommended = recommendation?.node;
          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: controller.refreshCurrent,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: _buildSlivers(),
                ),
              ),
              if (recommended != null)
                Positioned(
                  right: 16,
                  bottom: 18,
                  child: FloatingActionButton.extended(
                    heroTag: 'writing-smart-continue-$_controllerTag',
                    tooltip: recommendation!.explanation,
                    onPressed: () => _openNode(recommended),
                    icon: const Icon(Icons.edit_rounded),
                    label: Text(recommendation.label),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  List<Widget> _buildSlivers() {
    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: AdventureQuestBanner(
            eyebrow: 'Lộ trình viết thông minh',
            title: 'Học đúng chữ trong từng Section',
            description:
                'Panda ưu tiên bài đang học hoặc chữ tới hạn ôn. Dữ liệu HSK và chữ được lấy từ Supabase, không hardcode.',
            statusLabel: '${controller.catalog.length} cấp HSK thật',
            mood: PandaMood.thinking,
            compact: true,
          ),
        ),
      ),
    ];

    for (final path in controller.loadedPaths) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Row(
              children: [
                const PandaCompanion(size: 58, mood: PandaMood.celebrate),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        path.catalog.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: GameVisualTokens.templeWood,
                        ),
                      ),
                      Text(
                        '${path.completedCount}/${path.requiredCount} chữ đã hoàn thành',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      for (final section in path.sections) {
        slivers.add(
          SliverToBoxAdapter(
            child: HskWritingSectionBanner(
              hskName: path.catalog.name,
              section: section,
            ),
          ),
        );
        slivers.add(
          SliverList.builder(
            itemCount: section.nodes.length,
            itemBuilder: (context, index) {
              final node = section.nodes[index];
              return WritingPathNodeWidget(
                key: ValueKey(
                    'writing-${section.id}-${node.characterId}'),
                node: node,
                index: index,
                isLast: index == section.nodes.length - 1,
                onTap: () => _openNode(node),
              );
            },
          ),
        );
      }

      slivers.add(
        SliverToBoxAdapter(
          child: WritingHskMilestone(path: path),
        ),
      );
    }

    if (controller.isLoadingMore.value) {
      slivers.add(
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    } else {
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 110)));
    }
    return slivers;
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(text),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.retry,
  });

  final String message;
  final Future<void> Function() retry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PandaCompanion(size: 86, mood: PandaMood.encourage),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: retry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
