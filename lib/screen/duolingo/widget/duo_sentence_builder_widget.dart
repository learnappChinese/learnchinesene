import 'package:flutter/material.dart';
import '../../../core/models/duo_challenge.dart';
import '../../../core/theme/app_colors.dart';
import 'package:get/get.dart';

class DuoSentenceBuilderWidget extends StatefulWidget {
  final DuoChallenge challenge;
  final bool isAnswered;
  final Function(bool isCorrect) onCheck;

  const DuoSentenceBuilderWidget({
    super.key,
    required this.challenge,
    required this.isAnswered,
    required this.onCheck,
  });

  @override
  State<DuoSentenceBuilderWidget> createState() =>
      _DuoSentenceBuilderWidgetState();
}

class _DuoSentenceBuilderWidgetState extends State<DuoSentenceBuilderWidget> {
  final List<int> selectedIndices = [];

  @override
  void didUpdateWidget(DuoSentenceBuilderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.challenge.id != widget.challenge.id) {
      selectedIndices.clear();
    }
  }

  void toggleSelection(int index) {
    if (widget.isAnswered) return;

    setState(() {
      if (selectedIndices.contains(index)) {
        selectedIndices.remove(index);
      } else {
        selectedIndices.add(index);
      }
    });
  }

  void handleCheck() {
    final correctIds = widget.challenge.choicesCorrect ?? [];
    final userSequence = selectedIndices.map((idx) => correctIds[idx]).toList();

    bool isCorrect = true;
    int expectedId = 1;

    for (int id in userSequence) {
      if (id != expectedId) {
        isCorrect = false;
        break;
      }
      expectedId++;
    }

    final totalCorrectWords = correctIds.where((id) => id > 0).length;
    if (userSequence.length != totalCorrectWords) {
      isCorrect = false;
    }

    widget.onCheck(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    final choices = widget.challenge.choicesText ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),

          if (widget.challenge.type == 'translate' ||
              widget.challenge.type == 'orderTapComplete') ...[
            const Text('Dịch câu sau:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              widget.challenge.prompt ?? widget.challenge.solutions ?? '',
              style: const TextStyle(fontSize: 24, color: AppColors.red),
            ),
          ] else if (widget.challenge.type == 'listenTap') ...[
            const Text('Nghe và xếp câu:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Center(
              child: InkWell(
                onTap: () {
                  Get.snackbar(
                      'Audio', 'Phát âm thanh từ: ${widget.challenge.tts}',
                      snackPosition: SnackPosition.TOP);
                },
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: AppColors.orange, shape: BoxShape.circle),
                  child: const Icon(Icons.volume_up_rounded,
                      color: Colors.white, size: 48),
                ),
              ),
            ),
          ],

          const SizedBox(height: 40),

          // Vùng xếp từ (Selected Words)
          _buildSelectedWords(choices),

          const SizedBox(height: 40),

          // Vùng Word Bank (Available Words)
          _buildWordBank(choices),

          const Spacer(),

          if (!widget.isAnswered)
            ElevatedButton(
              onPressed: selectedIndices.isNotEmpty ? handleCheck : null,
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

  Widget _buildSelectedWords(List<String> choices) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Colors.grey.shade300, width: 2)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: selectedIndices.map((idx) {
          return InkWell(
            onTap: () => toggleSelection(idx),
            child: Chip(
              label: Text(choices[idx], style: const TextStyle(fontSize: 18)),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Colors.grey),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWordBank(List<String> choices) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: List.generate(choices.length, (idx) {
        final isSelected = selectedIndices.contains(idx);
        return InkWell(
          onTap: isSelected ? null : () => toggleSelection(idx),
          child: Chip(
            label: Text(choices[idx],
                style: TextStyle(
                    fontSize: 18,
                    color: isSelected ? Colors.transparent : Colors.black)),
            backgroundColor: isSelected ? Colors.grey.shade200 : Colors.white,
            side: BorderSide(
                color: isSelected ? Colors.transparent : Colors.grey),
          ),
        );
      }),
    );
  }
}
