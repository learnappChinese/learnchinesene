import 'package:flutter/material.dart';
import '../../core/widgets/app_shimmer.dart';
import 'widget/word_detail_cards.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/app_green_button.dart';
import '../../core/widgets/learning_scaffold.dart';
import '../../core/widgets/learning_scene_background.dart';
import 'package:get/get.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/theme/game_visual_tokens.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../hanzi_writing/screens/hanzi_writing_screen.dart';
import 'controller/word_detail_controller.dart';
import '../../core/models/word.dart';

class WordDetailScreen extends StatefulWidget {
  const WordDetailScreen({super.key, this.controller});

  final WordDetailController? controller;

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  late final WordDetailController controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      controller = widget.controller!;
    } else if (Get.isRegistered<WordDetailController>()) {
      controller = Get.find<WordDetailController>();
    } else {
      controller = Get.put(WordDetailController());
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController && Get.isRegistered<WordDetailController>()) {
      Get.delete<WordDetailController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = controller.word;

    if (w == null) {
      return const Scaffold(
        body: EmptyStateWidget(
          icon: Icons.search_off_rounded,
          title: 'Không tìm thấy từ',
          message: 'Từ vựng này hiện không khả dụng.',
        ),
      );
    }

    return LearningScaffold(
      title: 'Chi tiết từ vựng',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Obx(
            () => AppHudIconButton(
              icon: controller.learned.value
                  ? Icons.bookmark_added_rounded
                  : Icons.bookmark_add_outlined,
              tooltip: controller.learned.value
                  ? 'Đã đánh dấu đã học'
                  : 'Đánh dấu đã học',
              size: 40,
              onPressed: controller.mark,
            ),
          ),
        ),
      ],
      body: LearningSceneBackground(
        theme: LearningSceneTheme.bambooVillage,
        child: Column(
          children: [
            Expanded(child: _buildWordContent(context, w)),
            _buildPracticeActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildExamples() {
    return Obx(() {
      if (controller.isLoadingExamples.value) {
        return const _ExamplesSkeleton();
      }
      if (controller.examples.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Từ này chưa có câu ví dụ.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GameVisualTokens.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }
      return Column(
        children: controller.examples.asMap().entries.map((entry) {
          final e = entry.value;
          return WordExampleCard(
            key: ValueKey(e.id),
            example: e,
            number: entry.key + 1,
            onSpeak: () => controller.speak(exampleId: e.id),
          );
        }).toList(),
      );
    });
  }

  // Không có nền riêng: nút nổi thẳng trên phong cảnh để nền liền mạch
  // tới tận mép dưới màn hình.
  Widget _buildPracticeActions() {
    return Center(
      heightFactor: 1,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: ResponsiveHelper.contentMaxWidth(context),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Obx(
          () => Row(
            children: [
              Expanded(
                child: AppGreenButton(
                  label: 'Luyện phát âm',
                  icon: Icons.record_voice_over_rounded,
                  height: 50,
                  onPressed: () => controller.speak(),
                ),
              ),
              if (controller.characterId.value != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: AppGreenButton.light(
                    label: 'Luyện viết',
                    icon: Icons.draw_rounded,
                    height: 50,
                    onPressed: () {
                      Get.to(
                        () => HanziWritingScreen(
                          characterId: controller.characterId.value!,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWordContent(BuildContext context, Word word) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ResponsiveHelper.contentMaxWidth(context),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
          children: [
            WordPronunciationCard(
              word: word,
              onPlayAudio: word.ttsUrl.isEmpty
                  ? null
                  : () => controller.audio.playUrl(word.ttsUrl),
              onSpeak: () => controller.speak(),
            ),
            const SizedBox(height: 16),
            WordExamplesCard(child: _buildExamples()),
          ],
        ),
      ),
    );
  }
}

/// Khung đang tải khớp các thẻ câu mẫu: số thứ tự, câu, nghĩa, nút mic.
class _ExamplesSkeleton extends StatelessWidget {
  const _ExamplesSkeleton();

  @override
  Widget build(BuildContext context) => AppShimmer(
        child: Column(
          children: [
            for (var i = 0; i < 3; i++) ...[
              const SkeletonCard(
                padding: EdgeInsets.fromLTRB(12, 12, 10, 12),
                child: Row(
                  children: [
                    ShimmerBox.circle(size: 26),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerLine(widthFactor: .6, height: 9),
                          SizedBox(height: 4),
                          ShimmerLine(widthFactor: .8, height: 22),
                          SizedBox(height: 8),
                          ShimmerLine(widthFactor: .65, height: 12),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    ShimmerBox(width: 40, height: 40, radius: 13),
                  ],
                ),
              ),
              if (i < 2) const SizedBox(height: 14),
            ],
          ],
        ),
      );
}
