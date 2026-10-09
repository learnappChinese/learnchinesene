import 'package:flutter/material.dart';
import 'widget/speaking_cards.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/learning_scene_background.dart';
import '../../core/widgets/learning_scaffold.dart';
import 'controller/speaking_controller.dart';

class SpeakingScreen extends StatefulWidget {
  final int? wordId;
  final int? exampleId;
  final int? unitId;
  final bool random;
  final bool isBottomSheet;

  const SpeakingScreen({
    super.key,
    this.wordId,
    this.exampleId,
    this.unitId,
    this.random = false,
    this.isBottomSheet = false,
  });

  @override
  State<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends State<SpeakingScreen> {
  static int _nextControllerId = 0;
  late final String _controllerTag;
  late SpeakingController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'speaking-${_nextControllerId++}';
    _registerController();
  }

  void _registerController() {
    controller = Get.put(
      SpeakingController(
        wordId: widget.wordId,
        exampleId: widget.exampleId,
        unitId: widget.unitId,
        random: widget.random,
        isBottomSheet: widget.isBottomSheet,
      ),
      tag: _controllerTag,
    );
  }

  @override
  void didUpdateWidget(covariant SpeakingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wordId != widget.wordId ||
        oldWidget.exampleId != widget.exampleId ||
        oldWidget.unitId != widget.unitId ||
        oldWidget.random != widget.random ||
        oldWidget.isBottomSheet != widget.isBottomSheet) {
      Get.delete<SpeakingController>(tag: _controllerTag);
      _registerController();
    }
  }

  @override
  void dispose() {
    Get.delete<SpeakingController>(tag: _controllerTag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller.isBottomSheet) {
      return Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Obx(() => _buildContent(context)),
      );
    }

    return LearningScaffold(
      title: 'Luyện phát âm',
      body: Obx(() => _buildContent(context)),
    );
  }

  Widget _buildContent(BuildContext context) {
    Widget content;

    if (controller.isLoading.value) {
      content = const Center(child: CircularProgressIndicator());
    } else if (controller.errorMessage.value != null) {
      content = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(controller.errorMessage.value!,
                style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      );
    } else if (controller.items.isEmpty) {
      content = const Center(child: Text('Không có dữ liệu luyện tập.'));
    } else {
      final item = controller.items[controller.currentIndex.value];
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveHelper.contentMaxWidth(context),
          ),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              ResponsiveHelper.horizontalPadding(context),
              controller.isBottomSheet ? 12 : 8,
              ResponsiveHelper.horizontalPadding(context),
              30,
            ),
            children: [
              if (controller.isBottomSheet)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              _buildPracticeHeader(),
              const SizedBox(height: 12),
              SpeakingPromptCard(
                  item: item,
                  onPlayAudio: item.audioUrl == null || item.audioUrl!.isEmpty
                      ? null
                      : () => controller.audioService.playUrl(item.audioUrl!)),
              const SizedBox(height: 36),
              _buildMicrophoneControl(context),
              const SizedBox(height: 30),
              _buildResultOrTip(context),
            ],
          ),
        ),
      );
    }

    return LearningSceneBackground(
      theme: LearningSceneTheme.bambooVillage,
      child: content,
    );
  }

  Widget _buildPracticeHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Nghe và đọc lại',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.red,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        if (controller.items.length > 1)
          Text(
            '${controller.currentIndex.value + 1} / ${controller.items.length}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.muted,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildMicrophoneControl(BuildContext context) {
    return Obx(() => Column(children: [
          Center(
            child: ScaleTransition(
              scale: controller.pulse,
              child: InkWell(
                onTap: controller.busy.value
                    ? null
                    : () => controller.start(context),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 108,
                  height: 108,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.red, AppColors.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x45B4232C),
                        blurRadius: 28,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Icon(
                    controller.busy.value
                        ? Icons.graphic_eq_rounded
                        : Icons.mic_rounded,
                    size: 46,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            controller.busy.value
                ? 'Đang nghe… hãy nói tự nhiên'
                : 'Chạm micro để bắt đầu',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          )
        ]));
  }

  Widget _buildResultOrTip(BuildContext context) {
    return Obx(() => controller.correct.value != null
        ? SpeakingResultCard(
            correct: controller.correct.value!,
            score: controller.score.value,
            recognized: controller.recognized.value,
            busy: controller.busy.value,
            showNext: controller.items.length > 1,
            isLast:
                controller.currentIndex.value == controller.items.length - 1,
            onRetry: () => controller.start(context),
            onNext: () => controller.nextItem(context))
        : Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3EF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.tips_and_updates_outlined,
                  color: AppColors.orange,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mẹo: hãy nói rõ ràng với tốc độ thoải mái. Bạn có thể thử lại bất cứ lúc nào.',
                    style: TextStyle(
                      color: AppColors.muted,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ));
  }
}
