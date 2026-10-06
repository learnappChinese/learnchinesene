import 'package:flutter/material.dart';
import 'widget/dictionary_entry_view.dart';
import 'controller/dictionary_controller.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/gemini_service.dart';
import '../../core/services/history_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/responsive/responsive_layout.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TtsService _tts = Get.find<TtsService>();
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
    } catch (_) {}
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

  Future<void> _playAudio(String text) async {
    await _tts.speakChinese(text, slow: true);
  }

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
      body: _buildBody(context),
    );
  }

  Widget _buildSearchCard(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(18),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceVariant.withAlpha(80),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onSubmitted: (_) => _handleSearch(),
          ),
        ),
        const SizedBox(width: 10),
        Obx(() => FilledButton(
              onPressed: controller.isLoading.value ? null : _handleSearch,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              child: controller.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Tra từ'),
            )),
      ],
    );
  }

  Widget _buildVoiceInput(ThemeData theme) {
    return Row(
      children: [
        IconButton.filled(
          onPressed: _handleListen,
          style: IconButton.styleFrom(
            backgroundColor:
                _isListening ? AppColors.error : theme.colorScheme.primary,
          ),
          icon: Icon(
            _isListening ? Icons.stop_rounded : Icons.mic_rounded,
            color: Colors.white,
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
                    entry: controller.entry.value!, onPlayAudio: _playAudio),
            ]));
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final maxWidth = ResponsiveHelper.contentMaxWidth(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ListView(
          padding: const EdgeInsets.all(20),
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
