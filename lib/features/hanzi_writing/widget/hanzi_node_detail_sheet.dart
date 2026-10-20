import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/tts_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/game_visual_tokens.dart';
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

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final char = node.character;
    final isLocked = node.state == WritingNodeState.locked;
    final isCompleted = node.state == WritingNodeState.completed;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
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
        24,
        12,
        24,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tay nắm kéo (Pull handle)
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header: Huy hiệu HSK và nút đóng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: GameVisualTokens.primaryGreenSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'HSK ${node.hskLevel} • BÀI ${node.sectionId}',
                  style: const TextStyle(
                    color: GameVisualTokens.primaryGreenDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded,
                    color: Color(0xFF64748B), size: 24),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Khung hiển thị chữ Hán to và đẹp
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            ),
            child: Column(
              children: [
                Text(
                  char.character,
                  style: const TextStyle(
                    fontFamily: 'FZKaiTiPinyin',
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: GameVisualTokens.ink,
                  ),
                ),
                const SizedBox(height: 8),

                // Pinyin và nút phát âm thanh
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      (char.pinyin?.isNotEmpty ?? false) ? char.pinyin! : '—',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: GameVisualTokens.primaryGreenDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _playTts,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _isPlayingAudio
                              ? GameVisualTokens.primaryGreen
                              : GameVisualTokens.primaryGreenSoft,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlayingAudio
                              ? Icons.volume_up_rounded
                              : Icons.volume_down_rounded,
                          size: 20,
                          color: _isPlayingAudio
                              ? Colors.white
                              : GameVisualTokens.primaryGreenDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Nghĩa tiếng Việt
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    (char.meaning?.isNotEmpty ?? false)
                        ? char.meaning!
                        : 'Chưa có định nghĩa',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Hàng thông tin chi tiết: Số nét, Lần luyện, Điểm cao nhất
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  icon: '✏️',
                  label: 'Số nét',
                  value: char.strokeCount > 0
                      ? '${char.strokeCount} nét'
                      : 'Đang cập nhật',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatBox(
                  icon: '🔄',
                  label: 'Luyện tập',
                  value: '${node.practiceCount} lần',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatBox(
                  icon: '🎯',
                  label: 'Điểm cao',
                  value: '${node.bestScore.toInt()}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Trạng thái thông báo
          if (isLocked)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_clock_rounded,
                      color: Color(0xFFDC2626), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Chữ Hán này đang bị khóa. Hãy hoàn thành các chữ trước đó để mở khóa nhé!',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (isCompleted)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Color(0xFF059669), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bạn đã hoàn thành chữ này. Hãy luyện lại để củng cố nét viết!',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Nút bấm CTA phong cách 3D Duolingo
          GestureDetector(
            onTap: isLocked
                ? null
                : () {
                    Navigator.pop(context);
                    widget.onStartWriting();
                  },
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: isLocked
                    ? const Color(0xFFE2E8F0)
                    : isCompleted
                        ? GameVisualTokens.primaryGreen
                        : GameVisualTokens.primaryGreenDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isLocked
                      ? const Color(0xFFCBD5E1)
                      : isCompleted
                          ? GameVisualTokens.primaryGreenDark
                          : const Color(0xFF1B6A3B),
                  width: 2,
                ),
                boxShadow: isLocked
                    ? []
                    : [
                        BoxShadow(
                          color: (isCompleted
                                  ? GameVisualTokens.primaryGreenDark
                                  : const Color(0xFF155724))
                              .withValues(alpha: 0.5),
                          offset: const Offset(0, 4),
                          blurRadius: 0, // Độ sâu 3D đặc trưng Duolingo
                        ),
                      ],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isLocked
                        ? Icons.lock_outline_rounded
                        : isCompleted
                            ? Icons.refresh_rounded
                            : Icons.edit_note_rounded,
                    color: isLocked ? const Color(0xFF94A3B8) : Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isLocked
                        ? 'CHƯA MỞ KHÓA'
                        : isCompleted
                            ? 'LUYỆN VIẾT LẠI'
                            : 'BẮT ĐẦU VIẾT',
                    style: TextStyle(
                      color: isLocked ? const Color(0xFF94A3B8) : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required String icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: GameVisualTokens.ink,
            ),
          ),
        ],
      ),
    );
  }
}
