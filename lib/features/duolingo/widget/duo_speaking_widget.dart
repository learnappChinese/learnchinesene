import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/helper/permission_helper.dart';
import '../../../core/services/speech_service.dart';

class DuoSpeakingWidget extends StatefulWidget {
  final dynamic challenge;
  final bool isAnswered;
  final ValueChanged<SpeechResult> onCheck;

  const DuoSpeakingWidget({
    super.key,
    required this.challenge,
    required this.isAnswered,
    required this.onCheck,
  });

  @override
  State<DuoSpeakingWidget> createState() => _DuoSpeakingWidgetState();
}

class _DuoSpeakingWidgetState extends State<DuoSpeakingWidget> {
  bool isListening = false;
  final SpeechService _speech = SpeechService();

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  Future<void> _listen(String targetText) async {
    if (isListening || widget.isAnswered) return;
    final granted = await PermissionHelper.requestSpeakingPermissions();
    if (!granted || !mounted) return;
    setState(() => isListening = true);
    final result = await _speech.listenAndScore(targetText: targetText);
    if (!mounted) return;
    setState(() => isListening = false);
    if (result.isAvailable) widget.onCheck(result);
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.challenge.prompt ?? widget.challenge.solutions ?? '你好';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text(
            'Nghe và đọc lại câu sau:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          Text(
            text,
            style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.red),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          GestureDetector(
            onTap:
                widget.isAnswered || isListening ? null : () => _listen(text),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isListening ? AppColors.red : Colors.blue,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4))
                ],
              ),
              child: Icon(
                isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isListening
                ? 'Đang nghe... Nhấn lại để hoàn thành'
                : 'Nhấn vào mic để nói',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
