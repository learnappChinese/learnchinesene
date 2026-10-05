import 'package:flutter/material.dart';
import '../../../core/models/duo_challenge.dart';
import '../../../core/theme/app_colors.dart';

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

  @override
  void didUpdateWidget(DuoMultipleChoiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.challenge.id != widget.challenge.id) {
      selectedIndex = null;
    }
  }

  void selectOption(int index) {
    if (widget.isAnswered) return;
    setState(() {
      selectedIndex = index;
    });
  }

  void handleCheck() {
    if (selectedIndex == null) return;
    final correctIds = widget.challenge.choicesCorrect ?? [];
    final isCorrect = correctIds[selectedIndex!] == 1;
    widget.onCheck(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    final choices = widget.challenge.choicesText ?? [];
    final type = widget.challenge.type;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          if (widget.challenge.prompt != null) ...[
            Text(
              type == 'gapFill' ? 'Điền vào chỗ trống:' : 'Chọn đáp án đúng:',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              widget.challenge.prompt!,
              style: const TextStyle(fontSize: 24, color: AppColors.red),
            ),
            const SizedBox(height: 40),
          ] else if (type == 'gapFill' &&
              widget.challenge.tokensText != null) ...[
            const Text(
              'Điền vào chỗ trống:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildGapFillPrompt(choices),
            const SizedBox(height: 40),
          ],
          _buildAnswerChoices(choices),
          if (!widget.isAnswered)
            ElevatedButton(
              onPressed: selectedIndex != null ? handleCheck : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Kiểm tra',
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGapFillPrompt(List<String> choices) {
    return Wrap(
      spacing: 4,
      runSpacing: 8,
      children: widget.challenge.tokensText!.map((token) {
        int correctIdx = widget.challenge.choicesCorrect?.indexOf(1) ?? -1;
        String correctText = correctIdx >= 0 ? choices[correctIdx] : '';

        bool isGap = token == correctText ||
            token.isEmpty ||
            (widget.challenge.tokensHints != null &&
                widget.challenge.tokensHints![
                        widget.challenge.tokensText!.indexOf(token)] ==
                    '');

        if (isGap) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
            ),
            child: Text(
              selectedIndex != null ? choices[selectedIndex!] : '      ',
              style: TextStyle(
                fontSize: 24,
                color: selectedIndex != null ? Colors.blue : Colors.transparent,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }
        return Text(token, style: const TextStyle(fontSize: 24));
      }).toList(),
    );
  }

  Widget _buildAnswerChoices(List<String> choices) {
    return Expanded(
      child: ListView.separated(
        itemCount: choices.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, idx) {
          final isSelected = selectedIndex == idx;

          Color borderColor = Colors.grey.shade300;
          Color bgColor = Colors.white;

          if (isSelected) {
            borderColor = Colors.blue;
            bgColor = Colors.blue.withValues(alpha: 0.1);
          }

          if (widget.isAnswered) {
            if (widget.challenge.choicesCorrect![idx] == 1) {
              borderColor = AppColors.success;
              bgColor = AppColors.success.withValues(alpha: 0.1);
            } else if (isSelected) {
              borderColor = AppColors.error;
              bgColor = AppColors.error.withValues(alpha: 0.1);
            }
          }

          return InkWell(
            onTap: () => selectOption(idx),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Text(
                choices[idx],
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }
}
