import 'package:flutter/material.dart';
import 'widget/dictionary_entry_view.dart';
import 'controller/dictionary_controller.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/theme/game_visual_tokens.dart';
import '../../core/widgets/app_green_button.dart';
import '../../core/services/tts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/gemini_service.dart';
import '../../core/services/history_service.dart';
import '../../core/responsive/responsive_layout.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TtsService _tts =
      Get.isRegistered<TtsService>() ? Get.find<TtsService>() : TtsService();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  String _recognitionLang = 'vi-VN';
  String _recognitionError = '';

  static int _nextControllerId = 0;
  late final String _controllerTag;
  late final DictionaryController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'dictionary-${_nextControllerId++}';
    controller = Get.put(
        DictionaryController(
            lookup: Get.find<GeminiService>().fetchDictionaryEntry,
            saveHistory: Get.find<HistoryService>().saveHistory),
        tag: _controllerTag);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      await _speech.initialize();
    } catch (e) {
      debugPrint(
          '[DictionaryScreen] Speech recognition initialization failed: $e');
    }
  }

  @override
  void dispose() {
    Get.delete<DictionaryController>(tag: _controllerTag);
    _inputController.dispose();
    _tts.stop();
    _speech.stop();
    super.dispose();
  }

  Future<void> _handleSearch() => controller.search(_inputController.text);

  Future<void> _playAudio(String text) => _tts.speak(text, speechRate: 0.4);

  Future<void> _handleListen() async {
    var status = await Permission.microphone.status;
    if (!mounted) return;
    if (status.isDenied) {
      status = await Permission.microphone.request();
      if (!mounted) return;
      if (status.isDenied) {
        setState(() {
          _recognitionError = 'Chưa được cấp quyền sử dụng Micro.';
        });
        return;
      }
    }

    if (_isListening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() {
        _isListening = false;
      });
      return;
    }

    final isAvailable = await _speech.initialize();
    if (!mounted) return;
    if (!isAvailable) {
      setState(() {
        _recognitionError = 'Nhận giọng nói không khả dụng.';
      });
      return;
    }

    setState(() {
      _isListening = true;
      _recognitionError = '';
    });

    await _speech.listen(
      localeId: _recognitionLang,
      onResult: (result) {
        if (mounted && result.finalResult) {
          setState(() {
            _inputController.text = result.recognizedWords;
            _isListening = false;
          });
          _handleSearch();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Từ điển Việt ↔ Trung',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      // Nội dung cuộn tràn xuống đáy, khoảng đệm nằm ở cuối danh sách.
      body: _buildBody(context),
    );
  }

  Widget _buildSearchCard(ThemeData theme) {
    return Container(
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
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchInput(theme),
            const SizedBox(height: 12),
            _buildVoiceInput(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchInput(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _inputController,
            decoration: InputDecoration(
              hintText: 'Nhập từ cần tra (tiếng Việt hoặc Trung)...',
              prefixIcon: const Icon(Icons.search_rounded,
                  color: GameVisualTokens.primaryGreen),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0xFFF1E6CF), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                    color: GameVisualTokens.primaryGreen, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onSubmitted: (_) => _handleSearch(),
          ),
        ),
        const SizedBox(width: 10),
        Obx(() => AppGreenButton(
              label: 'Tra từ',
              isLoading: controller.isLoading.value,
              onPressed: _handleSearch,
              height: 50,
            )),
      ],
    );
  }

  Widget _buildVoiceInput(ThemeData theme) {
    return Row(
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: _handleListen,
            customBorder: const CircleBorder(),
            child: Ink(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _isListening
                      ? const [Color(0xFFEF4444), AppColors.error]
                      : const [
                          GameVisualTokens.primaryGreenLight,
                          GameVisualTokens.primaryGreen,
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isListening
                            ? AppColors.error
                            : GameVisualTokens.primaryGreen)
                        .withValues(alpha: .35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        DropdownButton<String>(
          value: _recognitionLang,
          underline: const SizedBox(),
          items: const [
            DropdownMenuItem(
              value: 'vi-VN',
              child: Text('Nói Tiếng Việt'),
            ),
            DropdownMenuItem(
              value: 'zh-CN',
              child: Text('说中文 (zh-CN)'),
            ),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _recognitionLang = val;
              });
            }
          },
        ),
        if (_recognitionError.isNotEmpty) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _recognitionError,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLookupResult() {
    return Obx(
        () => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (controller.error.value.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      controller.error.value,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              if (controller.entry.value != null)
                DictionaryEntryView(
                    entry: controller.entry.value!, onPlayAudio: _playAudio)
              else if (!controller.isLoading.value &&
                  controller.error.value.isEmpty)
                const _DictionaryEmptyHint(),
            ]));
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final maxWidth = ResponsiveHelper.contentMaxWidth(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          children: [
            // Search input container
            _buildSearchCard(theme),

            const SizedBox(height: 20),

            _buildLookupResult(),
          ],
        ),
      ),
    );
  }
}

class _DictionaryEmptyHint extends StatelessWidget {
  const _DictionaryEmptyHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xFFF1E6CF), width: 3),
            ),
            child: Image.asset(
              'assets/images/characters/home_panda_peek.png',
              errorBuilder: (_, __, ___) => const Center(
                  child: Text('🐼', style: TextStyle(fontSize: 48))),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tra cứu từ vựng bằng AI',
            style: TextStyle(
              color: Color(0xFF342E10),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Gõ hoặc nói một từ tiếng Việt hay tiếng Trung để xem nghĩa, pinyin và câu ví dụ.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF5D5C54),
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: const [
              _HintChip('你好'),
              _HintChip('cảm ơn'),
              _HintChip('学习'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: GameVisualTokens.primaryGreenSoft,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: GameVisualTokens.primaryGreenDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}
