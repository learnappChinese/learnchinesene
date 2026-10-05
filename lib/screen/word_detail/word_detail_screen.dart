import 'package:flutter/material.dart';
import 'widget/word_detail_cards.dart';
import '../../core/widgets/bottom_action_bar.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../hanzi_writing/screens/hanzi_writing_screen.dart';
import 'controller/word_detail_controller.dart';
import '../../core/models/word.dart';

class WordDetailScreen extends StatefulWidget {
  const WordDetailScreen({super.key});

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  late final WordDetailController controller;

  @override
  void initState() {
    super.initState();
    // The existing GetX route owns this registration.
    controller = Get.isRegistered<WordDetailController>()
        ? Get.find<WordDetailController>()
        : Get.put(WordDetailController());
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chi tiết từ vựng',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          Obx(() => IconButton(
                onPressed: controller.mark,
                icon: Icon(
                  controller.learned.value
                      ? Icons.bookmark_added_rounded
                      : Icons.bookmark_add_outlined,
                  color: controller.learned.value ? AppColors.success : null,
                ),
              )),
        ],
      ),
      body: _buildWordContent(context, w),
    );
  }

  Widget _buildExamples() {
    return Obx(() {
      if (controller.isLoadingExamples.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        );
      }
      if (controller.examples.isEmpty) {
        return const EmptyStateWidget(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Chưa có câu mẫu',
          message: 'Từ này chưa có câu ví dụ.',
        );
      }
      return Column(
        children: controller.examples.asMap().entries.map((entry) {
          final e = entry.value;
          return WordExampleCard(
              key: ValueKey(e.id),
              example: e,
              number: entry.key + 1,
              onSpeak: () => controller.speak(exampleId: e.id));
        }).toList(),
      );
    });
  }

  Widget _buildPracticeActions() {
    return BottomActionBar(
        child: Obx(() => Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => controller.speak(),
                    icon: const Icon(Icons.record_voice_over_rounded),
                    label: const Text('Luyện phát âm'),
                  ),
                ),
                if (controller.characterId.value != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Get.to(() => HanziWritingScreen(
                            characterId: controller.characterId.value!));
                      },
                      icon: const Icon(Icons.draw_rounded),
                      label: const Text('Luyện viết'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.red),
                        foregroundColor: AppColors.red,
                      ),
                    ),
                  ),
                ],
              ],
            )));
  }

  Widget _buildWordContent(BuildContext context, Word word) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: ResponsiveHelper.contentMaxWidth(context)),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  ResponsiveHelper.horizontalPadding(context),
                  4,
                  ResponsiveHelper.horizontalPadding(context),
                  24,
                ),
                children: [
                  WordPronunciationCard(
                      word: word,
                      onPlayAudio: word.ttsUrl.isEmpty
                          ? null
                          : () => controller.audio.playUrl(word.ttsUrl),
                      onSpeak: () => controller.speak()),
                  const SizedBox(height: 26),
                  const Text(
                    'Câu mẫu theo ngữ cảnh',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  _buildExamples(),
                ],
              ),
            ),
          ),
        ),
        _buildPracticeActions(),
      ],
    );
  }
}
