import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../../core/models/duo_challenge.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/game_visual_tokens.dart';

class DuoMultipleChoiceWidget extends StatefulWidget {
  final DuoChallenge challenge;
  final bool isAnswered;
  final Function(bool isCorrect) onCheck;

  const DuoMultipleChoiceWidget({
    super.key,
    required this.challenge,
    required this.isAnswered,
    required this.onCheck,
  });

  @override
  State<DuoMultipleChoiceWidget> createState() =>
      _DuoMultipleChoiceWidgetState();
}

class _DuoMultipleChoiceWidgetState extends State<DuoMultipleChoiceWidget> {
  int? selectedIndex;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playPromptAudio();
    });
  }

  @override
  void didUpdateWidget(DuoMultipleChoiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.challenge.id != widget.challenge.id) {
      selectedIndex = null;
      _stopAudio();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playPromptAudio();
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
  }

  Future<void> _playAudioUrl(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    try {
      setState(() => _isPlayingAudio = true);
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url.trim()));
    } catch (e) {
      debugPrint('[DuoMultipleChoiceWidget] Audio play error: $e');
    } finally {
      if (mounted) setState(() => _isPlayingAudio = false);
    }
  }

  Future<void> _playPromptAudio() async {
    // 1. Top-level TTS
    if (widget.challenge.tts != null &&
        widget.challenge.tts!.trim().isNotEmpty) {
      await _playAudioUrl(widget.challenge.tts);
      return;
    }

    // 2. Fallback to sequence of token TTS or first valid token TTS
    final tokenTts = widget.challenge.tokensTts ?? [];
    final validUrls =
        tokenTts.where((u) => u.trim().isNotEmpty).toList(growable: false);
    if (validUrls.isNotEmpty) {
      try {
        setState(() => _isPlayingAudio = true);
        for (final url in validUrls) {
          if (!mounted) break;
          await _audioPlayer.stop();
          await _audioPlayer.play(UrlSource(url.trim()));
          await _audioPlayer.onPlayerComplete.first.timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          );
        }
      } catch (_) {
      } finally {
        if (mounted) setState(() => _isPlayingAudio = false);
      }
    }
  }

  void selectOption(int index) {
    if (widget.isAnswered) return;
    setState(() {
      selectedIndex = index;
    });

    // Phát âm thanh của lựa chọn vừa bấm nếu có
    final choicesTts = widget.challenge.choicesTts;
    if (choicesTts != null &&
        index < choicesTts.length &&
        choicesTts[index].trim().isNotEmpty) {
      _playAudioUrl(choicesTts[index]);
    }
  }

  _TapCompleteInfo? _getTapCompleteInfo() {
    final tokens = widget.challenge.tokensText;
    if (tokens == null || tokens.isEmpty) return null;
    final choices = widget.challenge.choicesText ?? [];

    int gapIdx = tokens.indexWhere((t) => t.trim().isEmpty);
    String correctWord = '';
    List<String> prefix = [];
    List<String> suffix = [];

    if (gapIdx != -1) {
      // Có token khoảng trắng ' ' chỉ định vị trí khuyết
      prefix = tokens.sublist(0, gapIdx);
      if (gapIdx + 1 < tokens.length) {
        correctWord = tokens[gapIdx + 1];
        suffix = tokens.sublist(gapIdx + 2);
      } else {
        suffix = [];
        for (final c in choices) {
          if (!prefix.contains(c)) {
            correctWord = c;
            break;
          }
        }
      }
    } else {
      // Không có token khoảng trắng -> Tìm từ cần điền từ choicesCorrect hoặc đối chiếu
      int correctChoiceIdx = widget.challenge.choicesCorrect?.indexOf(1) ?? -1;
      if (correctChoiceIdx != -1 && correctChoiceIdx < choices.length) {
        correctWord = choices[correctChoiceIdx];
      } else {
        for (final c in choices) {
          if (tokens.contains(c)) {
            correctWord = c;
            break;
          }
        }
      }

      int matchIdx = tokens.indexOf(correctWord);
      if (matchIdx != -1) {
        prefix = tokens.sublist(0, matchIdx);
        suffix = tokens.sublist(matchIdx + 1);
      } else {
        prefix = tokens;
        suffix = [];
      }
    }

    // Tổng hợp nghĩa tiếng Việt gợi ý từ tokensHints
    final hints = widget.challenge.tokensHints ?? [];
    final meaningfulHints = <String>[];
    for (var i = 0; i < hints.length; i++) {
      final h = hints[i].trim();
      if (h.isNotEmpty) {
        final clean = h.split('|').first.trim();
        if (clean.isNotEmpty) meaningfulHints.add(clean);
      }
    }
    final vnHint = meaningfulHints.isNotEmpty
        ? meaningfulHints.join(' ')
        : (widget.challenge.prompt ?? '');

    return _TapCompleteInfo(
      correctWord: correctWord,
      prefixTokens: prefix,
      suffixTokens: suffix,
      vietnameseHint: vnHint,
    );
  }

  void handleCheck() {
    if (selectedIndex == null) return;
    final choices = widget.challenge.choicesText ?? [];
    if (selectedIndex! >= choices.length) return;

    bool isCorrect = false;
    final info = _getTapCompleteInfo();
    if (info != null && info.correctWord.isNotEmpty) {
      isCorrect = choices[selectedIndex!] == info.correctWord;
    } else {
      final correctIds = widget.challenge.choicesCorrect ?? [];
      if (selectedIndex! < correctIds.length) {
        isCorrect = correctIds[selectedIndex!] == 1;
      } else if (widget.challenge.solutions != null) {
        isCorrect = choices[selectedIndex!] == widget.challenge.solutions;
      }
    }

    widget.onCheck(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    final choices = widget.challenge.choicesText ?? [];
    final isGapType = widget.challenge.type == 'gapFill' ||
        widget.challenge.type == 'tapComplete' ||
        (widget.challenge.tokensText != null &&
            widget.challenge.tokensText!.isNotEmpty);

    final tapInfo = isGapType ? _getTapCompleteInfo() : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (tapInfo != null)
                    _buildGapFillSection(tapInfo, choices)
                  else
                    _buildStandardPromptSection(),
                  const SizedBox(height: 24),
                  _buildAnswerChoices(choices, tapInfo),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (!widget.isAnswered) ...[
            ElevatedButton(
              onPressed: selectedIndex != null ? handleCheck : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: GameVisualTokens.blue,
                disabledBackgroundColor: Colors.grey.shade300,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'KIỂM TRA',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildGapFillSection(_TapCompleteInfo info, List<String> choices) {
    final hasAudio = (widget.challenge.tts != null &&
            widget.challenge.tts!.trim().isNotEmpty) ||
        (widget.challenge.tokensTts != null &&
            widget.challenge.tokensTts!.any((u) => u.trim().isNotEmpty));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hoàn thành câu:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: GameVisualTokens.templeWood,
          ),
        ),
        const SizedBox(height: 10),

        // Khung gợi ý nghĩa tiếng Việt
        if (info.vietnameseHint.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: GameVisualTokens.parchment,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: GameVisualTokens.imperialGold.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.translate_rounded,
                  size: 20,
                  color: GameVisualTokens.imperialGold,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    info.vietnameseHint,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF451A03),
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),

        // Khung hiển thị câu tiếng Trung với ô trống tương tác
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasAudio)
                Row(
                  children: [
                    InkWell(
                      onTap: _isPlayingAudio ? null : _playPromptAudio,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: GameVisualTokens.blue.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlayingAudio
                              ? Icons.volume_up_rounded
                              : Icons.volume_down_rounded,
                          color: GameVisualTokens.blue,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nghe phát âm',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              if (hasAudio) const SizedBox(height: 12),

              // Dòng chữ tiếng Trung với ô trống
              Wrap(
                spacing: 8,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Từ đứng trước ô trống
                  ...info.prefixTokens.map(
                    (token) => Text(
                      token,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  // Ô trống điền từ (Slot)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: selectedIndex != null
                          ? GameVisualTokens.blue.withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedIndex != null
                            ? GameVisualTokens.blue
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      selectedIndex != null
                          ? choices[selectedIndex!]
                          : '   ?   ',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: selectedIndex != null
                            ? GameVisualTokens.blue
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),

                  // Từ đứng sau ô trống
                  ...info.suffixTokens.map(
                    (token) => Text(
                      token,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStandardPromptSection() {
    final hasAudio =
        widget.challenge.tts != null && widget.challenge.tts!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn đáp án đúng:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: GameVisualTokens.templeWood,
          ),
        ),
        const SizedBox(height: 14),
        if (widget.challenge.prompt != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
            ),
            child: Row(
              children: [
                if (hasAudio) ...[
                  InkWell(
                    onTap: _isPlayingAudio ? null : _playPromptAudio,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: GameVisualTokens.blue.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.volume_up_rounded,
                        color: GameVisualTokens.blue,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    widget.challenge.prompt!,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAnswerChoices(List<String> choices, _TapCompleteInfo? tapInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn từ thích hợp:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: choices.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, idx) {
            final isSelected = selectedIndex == idx;
            final choiceText = choices[idx];

            Color borderColor = Colors.grey.shade300;
            Color bgColor = Colors.white;

            if (isSelected) {
              borderColor = GameVisualTokens.blue;
              bgColor = GameVisualTokens.blue.withValues(alpha: 0.08);
            }

            if (widget.isAnswered) {
              bool isCorrectChoice = false;
              if (tapInfo != null && tapInfo.correctWord.isNotEmpty) {
                isCorrectChoice = choiceText == tapInfo.correctWord;
              } else {
                final correctIds = widget.challenge.choicesCorrect ?? [];
                if (idx < correctIds.length) {
                  isCorrectChoice = correctIds[idx] == 1;
                }
              }

              if (isCorrectChoice) {
                borderColor = AppColors.success;
                bgColor = AppColors.success.withValues(alpha: 0.12);
              } else if (isSelected) {
                borderColor = AppColors.error;
                bgColor = AppColors.error.withValues(alpha: 0.12);
              }
            }

            final hasChoiceAudio = widget.challenge.choicesTts != null &&
                idx < widget.challenge.choicesTts!.length &&
                widget.challenge.choicesTts![idx].trim().isNotEmpty;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => selectOption(idx),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 2),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: GameVisualTokens.blue.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? GameVisualTokens.blue
                              : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          String.fromCharCode(65 + idx), // A, B, C...
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          choiceText,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (hasChoiceAudio)
                        IconButton(
                          icon: const Icon(
                            Icons.volume_up_rounded,
                            size: 20,
                            color: GameVisualTokens.blue,
                          ),
                          onPressed: () =>
                              _playAudioUrl(widget.challenge.choicesTts![idx]),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TapCompleteInfo {
  final String correctWord;
  final List<String> prefixTokens;
  final List<String> suffixTokens;
  final String vietnameseHint;

  _TapCompleteInfo({
    required this.correctWord,
    required this.prefixTokens,
    required this.suffixTokens,
    required this.vietnameseHint,
  });
}
