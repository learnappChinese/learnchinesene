import 'package:flutter/material.dart';
import '../../../core/models/duo_flashcard.dart';
import '../../../core/theme/app_colors.dart';

class DuoFlashcardWidget extends StatefulWidget {
  final DuoFlashcard flashcard;
  final bool isAnswered;
  final Function(bool isCorrect) onCheck;

  const DuoFlashcardWidget({
    super.key,
    required this.flashcard,
    required this.isAnswered,
    required this.onCheck,
  });

  @override
  State<DuoFlashcardWidget> createState() => _DuoFlashcardWidgetState();
}

class _DuoFlashcardWidgetState extends State<DuoFlashcardWidget> {
  bool showMeaning = false;

  @override
  void didUpdateWidget(DuoFlashcardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flashcard.id != widget.flashcard.id) {
      showMeaning = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text(
            'Học từ mới (Chạm thẻ để xem nghĩa)',
            style: TextStyle(
                fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (widget.isAnswered) return;
                setState(() {
                  showMeaning = !showMeaning;
                });
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5))
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.flashcard.word,
                      style: TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                        fontFamily: showMeaning ? 'FZKaiTiPinyin' : null,
                      ),
                    ),
                    if (showMeaning) ...[
                      const SizedBox(height: 20),
                      Text(
                        widget.flashcard.meaning ?? '',
                        style: const TextStyle(
                            fontSize: 24, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      const SizedBox(height: 40),
                      const Text(
                        'Chạm để xem nghĩa',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          if (!widget.isAnswered)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onCheck(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Chưa nhớ',
                        style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onCheck(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Đã nhớ',
                        style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
