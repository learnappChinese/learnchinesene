import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/tts_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_green_button.dart';
import '../models/hanzi_path_models.dart';

/// Modal BottomSheet hiển thị chi tiết chữ Hán khi người học bấm vào một nút trên lộ trình.
class HanziNodeDetailSheet extends StatefulWidget {
  final HanziPathNode node;
  final VoidCallback onStartWriting;

  const HanziNodeDetailSheet({
    super.key,
    required this.node,
    required this.onStartWriting,
  });

  static Future<void> show(
    BuildContext context, {
    required HanziPathNode node,
    required VoidCallback onStartWriting,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HanziNodeDetailSheet(
        node: node,
        onStartWriting: onStartWriting,
      ),
    );
  }

  @override
  State<HanziNodeDetailSheet> createState() => _HanziNodeDetailSheetState();
}

class _HanziNodeDetailSheetState extends State<HanziNodeDetailSheet> {
  bool _isPlayingAudio = false;

  Future<void> _playTts() async {
    if (_isPlayingAudio) return;
    setState(() => _isPlayingAudio = true);
    try {
      final tts = Get.isRegistered<TtsService>()
          ? Get.find<TtsService>()
          : TtsService();
      await tts.speak(widget.node.character.character);
    } finally {
      if (mounted) {
        setState(() => _isPlayingAudio = false);
      }
    }
  }

  static const _line = Color(0xFFE8E1D6);

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final char = node.character;
    final isLocked = node.state == WritingNodeState.locked;
    final isCompleted = node.state == WritingNodeState.completed;
    final pinyin = char.pinyin ?? '';
    final meaning = (char.meaning?.isNotEmpty ?? false)
        ? char.meaning!
        : 'Chưa có định nghĩa';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFCF4),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tay nắm kéo (Pull handle)
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: _line,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header: Huy hiệu HSK và nút đóng
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.homeGreenLight, AppColors.homeGreen],
                  ),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    'HSK ${node.hskLevel} • BÀI ${node.sectionId}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              AppHudIconButton(
                icon: Icons.close_rounded,
                tooltip: 'Đóng',
                size: 36,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Khung chữ Hán: thẻ kem viền trắng như ở các màn học.
          // Font Khải đã vẽ sẵn pinyin của chữ phía trên.
          Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFDF6), Color(0xFFFFF4DE)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x24635D3B),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  char.character,
                  style: const TextStyle(
                    fontFamily: 'FZKaiTiPinyin',
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: AppColors.homeInk,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.homeGreenSoft,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          child: Text(
                            pinyin.isEmpty ? meaning : '$pinyin · $meaning',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppColors.homeGreenText,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Nút phát âm phụ: tròn, phẳng.
                    Material(
                      color: _isPlayingAudio
                          ? AppColors.homeGreen
                          : Colors.white,
                      shape: const CircleBorder(
                        side: BorderSide(color: AppColors.homeBorder, width: 1.5),
                      ),
                      child: InkWell(
                        onTap: _playTts,
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.volume_up_rounded,
                            size: 20,
                            color: _isPlayingAudio
                                ? Colors.white
                                : AppColors.homeGreen,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Hàng thông tin chi tiết: Số nét, Lần luyện, Điểm cao nhất
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  icon: Icons.draw_rounded,
                  color: AppColors.imperialGold,
                  label: 'Số nét',
                  value: char.strokeCount > 0
                      ? '${char.strokeCount} nét'
                      : 'Đang cập nhật',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatBox(
                  icon: Icons.replay_rounded,
                  color: GameVisualTokens.blue,
                  label: 'Luyện tập',
                  value: '${node.practiceCount} lần',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatBox(
                  icon: Icons.emoji_events_rounded,
                  color: AppColors.homeGreen,
                  label: 'Điểm cao',
                  value: '${node.bestScore.toInt()}%',
                ),
              ),
            ],
          ),

          // Trạng thái thông báo
          if (isLocked || isCompleted) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLocked
                    ? const Color(0xFFF3EEE4)
                    : AppColors.homeGreenSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    isLocked
                        ? Icons.lock_rounded
                        : Icons.check_circle_rounded,
                    color: isLocked
                        ? AppColors.homeSubtitle
                        : AppColors.homeGreenText,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isLocked
                          ? 'Hoàn thành các chữ trước đó để mở khóa chữ này nhé!'
                          : 'Bạn đã hoàn thành chữ này. Luyện lại để nhớ nét viết lâu hơn!',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: isLocked
                            ? AppColors.homeSubtitle
                            : AppColors.homeGreenText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),

          // Nút hành động chính: xanh nổi khối như ở màn Home
          AppGreenButton(
            label: isLocked
                ? 'Chưa mở khóa'
                : isCompleted
                    ? 'Luyện viết lại'
                    : 'Bắt đầu viết',
            icon: isLocked
                ? Icons.lock_outline_rounded
                : isCompleted
                    ? Icons.refresh_rounded
                    : Icons.edit_note_rounded,
            height: 54,
            fontSize: 16,
            expand: true,
            onPressed: isLocked
                ? null
                : () {
                    Navigator.pop(context);
                    widget.onStartWriting();
                  },
          ),
        ],
      ),
    );
  }

  /// Ô thông tin phẳng: icon màu trong vòng tròn, nhãn xám, giá trị đậm.
  Widget _buildStatBox({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.homeSubtitle,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.homeTitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
