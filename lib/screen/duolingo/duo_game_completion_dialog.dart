import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class DuoGameCompletionDialog extends StatelessWidget {
  final int stars;
  final int score;
  final int correctCount;
  final int wrongCount;
  final VoidCallback onContinue;

  const DuoGameCompletionDialog({
    super.key,
    required this.stars,
    required this.score,
    required this.correctCount,
    required this.wrongCount,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(Icons.emoji_events_rounded,
                  size: 100, color: Colors.amber),
              const SizedBox(height: 20),
              const Text(
                'HOÀN THÀNH MÀN CHƠI!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.success,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(
                      index < stars
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 48,
                      color: Colors.amber,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                        title: 'Điểm số', value: '+$score', color: Colors.blue),
                    _StatItem(
                        title: 'Đúng',
                        value: '$correctCount câu',
                        color: AppColors.success),
                    _StatItem(
                        title: 'Chưa chuẩn',
                        value: '$wrongCount câu',
                        color: AppColors.red),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                child: const Text(
                  'TIẾP TỤC',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatItem(
      {required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
