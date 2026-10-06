import 'package:flutter/material.dart';
import 'widget/conversation_bubble.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/learning_scene_background.dart';
import 'controller/conversations_controller.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  late final ConversationsController controller;

  @override
  void initState() {
    super.initState();
    // GetX retains the existing route ownership and cleanup.
    controller = Get.isRegistered<ConversationsController>()
        ? Get.find<ConversationsController>()
        : Get.put(ConversationsController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hội thoại tình huống AI',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: LearningSceneBackground(
        theme: LearningSceneTheme.bambooVillage,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildConversation() {
    return Expanded(
      child: Obx(() {
        if (controller.isLoading.value) {
          return const SizedBox();
        }

        if (controller.lines.isEmpty) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.forum_rounded,
                    size: 80,
                    color: AppColors.muted.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bắt đầu cuộc trò chuyện',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chọn cấp độ HSK và nhập chủ đề mong muốn để AI tạo đoạn hội thoại chất lượng cao.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, height: 1.4),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            if (controller.currentTopic.value.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: AppColors.orange.withOpacity(0.1),
                width: double.infinity,
                alignment: Alignment.center,
                child: Text(
                  'Chủ đề: ${controller.currentTopic.value}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.orange),
                ),
              ),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: controller.lines.length + 1,
                itemBuilder: (context, index) {
                  if (index == controller.lines.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Obx(() => controller.isMoreLoading.value
                            ? const CircularProgressIndicator()
                            : TextButton.icon(
                                onPressed: controller.loadMoreLines,
                                icon: const Icon(Icons.add_comment_rounded),
                                label: const Text('Tiếp tục hội thoại'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.red,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  side: const BorderSide(color: AppColors.red),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                ),
                              )),
                      ),
                    );
                  }

                  final line = controller.lines[index];
                  return ConversationBubble(
                      chinese: line['zh'] ?? '',
                      vietnamese: line['vi'] ?? '',
                      turn: line['turn'] as int? ?? 1,
                      onSpeak: () => controller.speak(line['zh'] ?? ''));
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildConversationSettings() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    'Cấp độ HSK:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.ink),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => DropdownButton<int>(
                          value: controller.selectedLevel.value,
                          isExpanded: true,
                          underline: Container(
                              height: 1,
                              color: AppColors.muted.withOpacity(0.3)),
                          items: List.generate(6, (index) {
                            final lvl = index + 1;
                            return DropdownMenuItem(
                              value: lvl,
                              child: Text('HSK $lvl',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            );
                          }),
                          onChanged: (val) {
                            if (val != null) {
                              controller.selectedLevel.value = val;
                            }
                          },
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.topicController,
                decoration: InputDecoration(
                  hintText:
                      'Nhập chủ đề hội thoại (Ví dụ: Mua sắm, Du lịch...)',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: AppColors.muted.withOpacity(0.3)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Obx(() => controller.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                      label: 'Tạo hội thoại',
                      onPressed: controller.startConversation,
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Settings Panel Card
          _buildConversationSettings(),

          // Conversation Chat View
          _buildConversation(),
        ],
      ),
    );
  }
}
