import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/hanzi_practice_config.dart';
import '../../../core/responsive/responsive_layout.dart';

class WritingRoundProgress extends StatelessWidget {
  const WritingRoundProgress({super.key, required this.currentRoundIndex});
  final int currentRoundIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(10, (index) {
        final isCompleted = index < currentRoundIndex;
        final isCurrent = index == currentRoundIndex;

        Color color;
        double size = 10.0;
        BoxBorder? border;
        List<BoxShadow>? shadow;

        if (isCompleted) {
          color = AppColors.orange;
        } else if (isCurrent) {
          color = AppColors.orange;
          size = 16.0;
          border = Border.all(color: Colors.white, width: 2.0);
          shadow = const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ];
        } else {
          color = Colors.grey[200]!;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: border,
            boxShadow: shadow,
          ),
        );
      }),
    );
  }
}

class WritingRoundCompletion extends StatelessWidget {
  const WritingRoundCompletion(
      {super.key,
      required this.roundNumber,
      required this.roundScore,
      required this.currentRoundIndex,
      required this.onContinue});
  final int roundNumber;
  final double roundScore;
  final int currentRoundIndex;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        onPanStart: (_) {},
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: _buildCompletionCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.green,
                size: 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hoàn thành lượt $roundNumber/10',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Điểm: ${roundScore.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        currentRoundIndex == 9
                            ? 'Xem kết quả'
                            : 'Tiếp tục lượt ${currentRoundIndex + 2}/10',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WritingSessionMetric extends StatelessWidget {
  const WritingSessionMetric(
      {super.key,
      required this.icon,
      required this.title,
      required this.value,
      required this.color});
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black45)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87)),
          ],
        ),
      ],
    );
  }
}

class WritingSessionSummary extends StatelessWidget {
  const WritingSessionSummary(
      {super.key,
      required this.results,
      required this.character,
      required this.onNextCharacter,
      required this.onRetry,
      required this.onClose});
  final List<HanziRoundResult> results;
  final String character;
  final VoidCallback onNextCharacter;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final totalScore = results.map((r) => r.score).fold(0.0, (a, b) => a + b);
    final avgScore = results.isEmpty ? 0.0 : totalScore / results.length;

    final lastThree = results.sublist(math.max(0, results.length - 3));
    final avgLastThree = lastThree.isEmpty
        ? 0.0
        : lastThree.map((r) => r.score).fold(0.0, (a, b) => a + b) /
            lastThree.length;

    final totalDrawn =
        results.map((r) => r.drawnStrokeCount).fold(0, (a, b) => a + b);
    final totalAttemptsSum =
        results.map((r) => r.attemptCount).fold(0, (a, b) => a + b);
    final strokeAccuracy =
        totalAttemptsSum > 0 ? (totalDrawn / totalAttemptsSum) * 100 : 0.0;
    final totalWrong = totalAttemptsSum - totalDrawn;

    final totalDurationMs =
        results.map((r) => r.durationMilliseconds).fold(0, (a, b) => a + b);
    final totalDurationSec = totalDurationMs ~/ 1000;
    final durationText = totalDurationSec >= 60
        ? '${totalDurationSec ~/ 60} phút ${totalDurationSec % 60} giây'
        : '$totalDurationSec giây';

    final maxScore =
        results.isEmpty ? 0.0 : results.map((r) => r.score).reduce(math.max);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Stack(
        children: [
          // Background Gradient Decoration
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.orange.withOpacity(0.15),
                    const Color(0xFFF9F9F9),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            maxWidth:
                                ResponsiveHelper.contentMaxWidth(context)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24.0, vertical: 16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Header Row
                              _buildSummaryHeader(),
                              const SizedBox(height: 24),

                              // Main Score & Accuracy Card
                              _buildScoreSummaryCard(avgScore, strokeAccuracy),
                              const SizedBox(height: 16),

                              // Stats Grid (2x2 highly compact)
                              _buildSessionMetrics(avgLastThree, maxScore,
                                  durationText, totalWrong),
                              const SizedBox(height: 32),

                              // Action Buttons
                              _buildNextCharacterAction(),
                              const SizedBox(height: 12),
                              _buildSummaryActions(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.elasticOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.orange,
                      AppColors.orange.withOpacity(0.7)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orange.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    color: Colors.white, size: 28),
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tuyệt vời!',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87),
            ),
            Text(
              'Hoàn thành chữ "$character"',
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreSummaryCard(double avgScore, double strokeAccuracy) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Left: Score
          Column(
            children: [
              const Text('ĐIỂM TRUNG BÌNH',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.black45)),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1200),
                tween: Tween(begin: 0.0, end: avgScore),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: AppColors.orange,
                        height: 1.2),
                  );
                },
              ),
            ],
          ),
          Container(width: 1, height: 60, color: Colors.grey[200]),
          // Right: Accuracy
          Column(
            children: [
              const Text('CHÍNH XÁC',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.black45)),
              Text(
                '${strokeAccuracy.toStringAsFixed(0)}%',
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.green,
                    height: 1.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionMetrics(double avgLastThree, double maxScore,
      String durationText, int totalWrong) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: WritingSessionMetric(
                      icon: Icons.trending_up_rounded,
                      title: '3 lượt cuối',
                      value: avgLastThree.toStringAsFixed(0),
                      color: Colors.blue)),
              Container(width: 1, height: 40, color: Colors.grey[100]),
              Expanded(
                  child: WritingSessionMetric(
                      icon: Icons.star_rounded,
                      title: 'Cao nhất',
                      value: maxScore.toStringAsFixed(0),
                      color: Colors.orange)),
            ],
          ),
          const Divider(height: 32, thickness: 1, color: Color(0xFFF5F5F5)),
          Row(
            children: [
              Expanded(
                  child: WritingSessionMetric(
                      icon: Icons.timer_rounded,
                      title: 'Thời gian',
                      value: durationText,
                      color: Colors.purple)),
              Container(width: 1, height: 40, color: Colors.grey[100]),
              Expanded(
                  child: WritingSessionMetric(
                      icon: Icons.error_outline_rounded,
                      title: 'Viết sai',
                      value: '$totalWrong lần',
                      color: Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextCharacterAction() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onNextCharacter,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.orange.withOpacity(0.4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text('Học chữ tiếp theo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSummaryActions() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Luyện lại',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: onClose,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Danh sách',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }
}
