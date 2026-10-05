import 'package:flutter/material.dart';
import 'widget/lesson_content.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import 'controller/lessons_controller.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  late final LessonsController controller;

  @override
  void initState() {
    super.initState();
    // GetX retains the existing route ownership and cleanup.
    controller = Get.isRegistered<LessonsController>()
        ? Get.find<LessonsController>()
        : Get.put(LessonsController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Bài học chuyên đề AI',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _buildBody(),
    );
  }

  void _openLessonDetail(String topicTitle) {
    controller.loadLessonDetail(topicTitle);
    Get.to(() => _LessonDetailView(controller: controller));
  }

  Widget _buildLevelSelector() {
    return Obx(() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Text(
                    'Cấp độ HSK:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.ink),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<int>(
                      value: controller.selectedLevel.value,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: List.generate(6, (index) {
                        final lvl = index + 1;
                        return DropdownMenuItem(
                          value: lvl,
                          child: Text('HSK $lvl',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) {
                          controller.selectedLevel.value = val;
                          controller.loadTopics();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildTopics() {
    return Obx(() => controller.isTopicsLoading.value
        ? const Center(child: CircularProgressIndicator())
        : controller.topics.isEmpty
            ? const Center(child: Text('Không tìm thấy bài học nào.'))
            : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: controller.topics.length,
                itemBuilder: (context, index) {
                  final topic = controller.topics[index];
                  return LessonTopicTile(
                      number: index + 1,
                      title: topic['title'] ?? '',
                      description: topic['description'] ?? '',
                      onTap: () => _openLessonDetail(topic['title'] ?? ''));
                },
              ));
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Level selector header
        _buildLevelSelector(),

        // Topics Grid/List
        Expanded(
          child: _buildTopics(),
        ),
      ],
    );
  }
}

class _LessonDetailView extends StatelessWidget {
  const _LessonDetailView({required this.controller});

  final LessonsController controller;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Obx(() => Text(
                controller.lessonTitle.value,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              )),
          bottom: const TabBar(
            labelColor: AppColors.red,
            unselectedLabelColor: AppColors.muted,
            indicatorColor: AppColors.red,
            tabs: [
              Tab(text: 'Hội thoại'),
              Tab(text: 'Từ vựng'),
              Tab(text: 'Ngữ pháp'),
            ],
          ),
        ),
        body: _buildDetailContent(),
      ),
    );
  }

  Widget _buildDetailContent() {
    return Obx(() {
      if (controller.isDetailLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return TabBarView(
        physics: const BouncingScrollPhysics(),
        children: [
          LessonDialogueTab(
              lines: controller.dialogue.toList(), onSpeak: controller.speak),
          LessonVocabularyTab(
              items: controller.keyVocabulary.toList(),
              onSpeak: controller.speak),
          LessonGrammarTab(
              points: controller.grammarPoints.toList(),
              onSpeak: controller.speak),
        ],
      );
    });
  }
}
