import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/theme/app_colors.dart';

class DuoWordConnectWidget extends StatefulWidget {
  final List<Map<String, String>> pairs;
  final bool isAnswered;
  final Function(bool isCorrect) onCheck;

  const DuoWordConnectWidget({
    super.key,
    required this.pairs,
    required this.isAnswered,
    required this.onCheck,
  });

  @override
  State<DuoWordConnectWidget> createState() => _DuoWordConnectWidgetState();
}

class _DuoWordConnectWidgetState extends State<DuoWordConnectWidget> {
  late List<String> leftWords;
  late List<String> rightWords;

  int _pairRevision = 0;
  String? selectedLeft;
  String? selectedRight;

  final Set<String> matchedLeft = {};
  final Set<String> matchedRight = {};

  final Map<String, bool> errorLeft = {};
  final Map<String, bool> errorRight = {};

  @override
  void initState() {
    super.initState();
    _initializePairs();
  }

  @override
  void didUpdateWidget(DuoWordConnectWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final samePairs = oldWidget.pairs.length == widget.pairs.length &&
        List.generate(
                widget.pairs.length,
                (index) =>
                    mapEquals(oldWidget.pairs[index], widget.pairs[index]))
            .every((equal) => equal);
    if (!samePairs) {
      _initializePairs();
    }
  }

  void _initializePairs() {
    _pairRevision++;
    leftWords = widget.pairs.map((p) => p['zh']!).toList()..shuffle();
    rightWords = widget.pairs.map((p) => p['vi']!).toList()..shuffle();
    selectedLeft = null;
    selectedRight = null;
    matchedLeft.clear();
    matchedRight.clear();
    errorLeft.clear();
    errorRight.clear();
  }

  void _checkMatch() {
    if (selectedLeft == null || selectedRight == null) return;

    // Tìm xem cặp này có khớp trong pairs không
    final isMatch = widget.pairs
        .any((p) => p['zh'] == selectedLeft && p['vi'] == selectedRight);

    if (isMatch) {
      setState(() {
        matchedLeft.add(selectedLeft!);
        matchedRight.add(selectedRight!);
        selectedLeft = null;
        selectedRight = null;
      });

      // Nếu đã nối khớp tất cả các cặp
      if (matchedLeft.length == widget.pairs.length) {
        widget.onCheck(true);
      }
    } else {
      // Mismatch animation / error state
      final failedLeft = selectedLeft!;
      final failedRight = selectedRight!;

      setState(() {
        errorLeft[failedLeft] = true;
        errorRight[failedRight] = true;
        selectedLeft = null;
        selectedRight = null;
      });

      final revision = _pairRevision;
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && revision == _pairRevision) {
          setState(() {
            errorLeft[failedLeft] = false;
            errorRight[failedRight] = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            'Nối các từ tiếng Trung với nghĩa tương ứng',
            style: TextStyle(
                fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                // Cột bên trái: Tiếng Trung
                _buildChineseColumn(),
                const SizedBox(width: 20),
                // Cột bên phải: Nghĩa tiếng Việt
                _buildMeaningColumn(),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildChineseColumn() {
    return Expanded(
      child: ListView.separated(
        itemCount: leftWords.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: _buildChineseWord,
      ),
    );
  }

  Widget _buildMeaningColumn() {
    return Expanded(
      child: ListView.separated(
        itemCount: rightWords.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: _buildMeaningWord,
      ),
    );
  }

  Widget _buildChineseWord(BuildContext context, int idx) {
    final word = leftWords[idx];
    final isMatched = matchedLeft.contains(word);
    final isSelected = selectedLeft == word;
    final isError = errorLeft[word] ?? false;

    Color borderColor = Colors.grey.shade300;
    Color bgColor = Colors.white;

    if (isMatched) {
      borderColor = AppColors.success;
      bgColor = AppColors.success.withValues(alpha: 0.1);
    } else if (isError) {
      borderColor = AppColors.red;
      bgColor = AppColors.red.withValues(alpha: 0.1);
    } else if (isSelected) {
      borderColor = Colors.blue;
      bgColor = Colors.blue.withValues(alpha: 0.1);
    }

    return InkWell(
      onTap: isMatched || widget.isAnswered
          ? null
          : () {
              setState(() {
                selectedLeft = word;
              });
              _checkMatch();
            },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Text(
          word,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildMeaningWord(BuildContext context, int idx) {
    final word = rightWords[idx];
    final isMatched = matchedRight.contains(word);
    final isSelected = selectedRight == word;
    final isError = errorRight[word] ?? false;

    Color borderColor = Colors.grey.shade300;
    Color bgColor = Colors.white;

    if (isMatched) {
      borderColor = AppColors.success;
      bgColor = AppColors.success.withValues(alpha: 0.1);
    } else if (isError) {
      borderColor = AppColors.red;
      bgColor = AppColors.red.withValues(alpha: 0.1);
    } else if (isSelected) {
      borderColor = Colors.blue;
      bgColor = Colors.blue.withValues(alpha: 0.1);
    }

    return InkWell(
      onTap: isMatched || widget.isAnswered
          ? null
          : () {
              setState(() {
                selectedRight = word;
              });
              _checkMatch();
            },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Text(
          word,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
