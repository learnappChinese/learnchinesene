import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../widget/writing_session_content.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/tts_service.dart';
import 'package:get/get.dart';
import '../controller/hanzi_writing_controller.dart';
import '../../../core/models/hanzi_character.dart';
import '../painters/hanzi_grid_painter.dart';
import '../painters/hanzi_writing_painter.dart';
import '../painters/user_stroke_painter.dart';
import '../services/stroke_validator.dart';
import '../services/svg_stroke_parser.dart';
import '../models/hanzi_practice_config.dart';
import '../../../core/learning/model/learning_source_context.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/widgets/learning_scaffold.dart';

class HanziWritingScreen extends StatefulWidget {
  final int characterId;
  final LearningSourceContext? sourceContext;
  final bool returnToLearningPath;

  const HanziWritingScreen({
    super.key,
    required this.characterId,
    this.sourceContext,
    this.returnToLearningPath = false,
  });

  @override
  State<HanziWritingScreen> createState() => _HanziWritingScreenState();
}

class _HanziWritingScreenState extends State<HanziWritingScreen>
    with SingleTickerProviderStateMixin {
  static int _nextControllerId = 0;
  late final String _controllerTag;
  late final HanziWritingController controller;
  HanziCharacter? _character;
  final AudioPlayer _pronunciationPlayer = AudioPlayer();
  final TtsService _ttsService = TtsService();
  bool _isPronouncing = false;
  List<Path> _strokePaths = [];
  int _loadRequest = 0;
  bool _isLoading = true;
  String? _errorMessage;

  // Round configs & stats
  List<HanziPracticeRoundConfig> _roundConfigs = [];
  int _currentRoundIndex = 0; // 0 to 9
  int _currentStrokeIndex = 0; // active stroke index in character
  final List<int> _completedStrokeIndexes = [];
  final List<double> _currentRoundStrokeScores = [];
  final List<HanziRoundResult> _completedRoundResults = [];

  int _totalAttempts = 0; // touch attempts in this round
  int _failedAttemptsThisStroke = 0;
  DateTime? _roundStartedAt;

  // Active user writing line repaint notifier
  final ValueNotifier<UserStroke> _userStrokeNotifier = ValueNotifier(
    const UserStroke(points: [], color: Colors.blue),
  );

  String _validationFeedback = 'Hãy viết nét đầu tiên.';
  Color _feedbackColor = Colors.grey;

  // Snap animation variables
  late AnimationController _snapAnimationController;
  int? _animatingStrokeIndex;

  bool _isRoundCompleted = false;
  bool _isSessionCompleted = false;
  bool _isPersistingSession = false;
  String? _persistError;
  Timer? _autoNextRoundTimer;
  Timer? _hintTimer;
  bool _showTemporaryHint = false;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'writing-session-${_nextControllerId++}';
    controller = Get.put(HanziWritingController(), tag: _controllerTag);
    _snapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        setState(() {});
      });
    _loadCharacter();
  }

  @override
  void didUpdateWidget(covariant HanziWritingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.characterId != widget.characterId) {
      _autoNextRoundTimer?.cancel();
      _hintTimer?.cancel();
      _snapAnimationController.stop();
      _loadCharacter();
    }
  }

  @override
  void dispose() {
    Get.delete<HanziWritingController>(tag: _controllerTag);
    _autoNextRoundTimer?.cancel();
    _hintTimer?.cancel();
    _snapAnimationController.dispose();
    unawaited(_pronunciationPlayer.dispose());
    unawaited(_ttsService.stop());
    _userStrokeNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadCharacter() async {
    final request = ++_loadRequest;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isSessionCompleted = false;
      _isRoundCompleted = false;
      _isPersistingSession = false;
      _persistError = null;
    });
    try {
      final char = await controller.loadCharacter(widget.characterId);
      if (!mounted || request != _loadRequest) return;
      if (char == null) {
        setState(() {
          _errorMessage = 'Không tìm thấy dữ liệu chữ Hán này.';
          _isLoading = false;
        });
        return;
      }

      if (char.strokePathData.trim().isEmpty) {
        setState(() {
          _character = char;
          _errorMessage = 'Chữ này chưa có dữ liệu nét vẽ.';
          _isLoading = false;
        });
        return;
      }

      final paths = SvgStrokeParser.parseStrokesToPaths(char.strokePathData);
      if (paths.isEmpty) {
        setState(() {
          _character = char;
          _errorMessage = 'Dữ liệu nét vẽ không hợp lệ.';
          _isLoading = false;
        });
        return;
      }

      await controller.beginPractice(
        widget.characterId,
        sourceContext: widget.sourceContext,
      );
      if (!mounted || request != _loadRequest) return;

      setState(() {
        _character = char;
        _strokePaths = paths;
        _isLoading = false;

        // Initialize session stats
        _roundConfigs = generateRoundConfigs(paths.length);
        _currentRoundIndex = 0;
        _completedRoundResults.clear();
        _isRoundCompleted = false;
        _isSessionCompleted = false;

        _initializeRound(_roundConfigs[_currentRoundIndex]);
      });
    } catch (e) {
      if (!mounted || request != _loadRequest) return;
      setState(() {
        _errorMessage = 'Lỗi kết nối database: $e';
        _isLoading = false;
      });
    }
  }

  void _initializeRound(HanziPracticeRoundConfig config) {
    _currentStrokeIndex = config.prefilledStrokeCount;

    _completedStrokeIndexes
      ..clear()
      ..addAll(
        List.generate(
          config.prefilledStrokeCount,
          (index) => index,
        ),
      );

    _currentRoundStrokeScores.clear();
    _userStrokeNotifier.value =
        const UserStroke(points: [], color: Colors.blue);
    _totalAttempts = 0;
    _failedAttemptsThisStroke = 0;
    _animatingStrokeIndex = null;
    _showTemporaryHint = false;
    _hintTimer?.cancel();
    _roundStartedAt = DateTime.now();
    _isRoundCompleted = false;

    // Reset feedback states
    if (_currentStrokeIndex >= _strokePaths.length) {
      _validationFeedback = 'Hoàn thành lượt vẽ.';
      _feedbackColor = AppColors.success;
    } else {
      final nextNum = _currentStrokeIndex + 1;
      final totalNum = _strokePaths.length;
      _validationFeedback = 'Hãy viết nét $nextNum/$totalNum.';
      _feedbackColor = Colors.grey;
    }
  }

  void _handlePanStart(DragStartDetails details, BoxConstraints constraints) {
    if (_isRoundCompleted || _isSessionCompleted) return;
    _userStrokeNotifier.value = UserStroke(
      points: [details.localPosition],
      color: Colors.blue,
    );
  }

  void _handlePanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (_isRoundCompleted || _isSessionCompleted) return;
    final currentStroke = _userStrokeNotifier.value;
    _userStrokeNotifier.value = UserStroke(
      points: List.from(currentStroke.points)..add(details.localPosition),
      color: currentStroke.color,
    );
  }

  void _handlePanEnd(DragEndDetails details, BoxConstraints constraints) {
    if (_isRoundCompleted || _isSessionCompleted) return;
    final userPoints = _userStrokeNotifier.value.points;
    if (userPoints.isEmpty) return;

    _totalAttempts++;

    final char = _character!;
    final Size canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

    // Convert user points to SVG space
    final scaleX = canvasSize.width / char.viewBoxWidth;
    final scaleY = canvasSize.height / char.viewBoxHeight;
    final scale = math.min(scaleX, scaleY);
    final offsetX = (canvasSize.width - char.viewBoxWidth * scale) / 2;
    final offsetY = (canvasSize.height - char.viewBoxHeight * scale) / 2;

    final List<Offset> svgSpacePoints = userPoints.map((p) {
      return Offset(
        (p.dx - offsetX) / scale,
        (p.dy - offsetY) / scale,
      );
    }).toList();

    // Validate against current stroke
    final currentPath = _strokePaths[_currentStrokeIndex];
    final result = StrokeValidator.validate(
      userPoints: svgSpacePoints,
      refPath: currentPath,
    );

    if (result.isValid) {
      _acceptCurrentStroke(result.score);
    } else {
      // Draw failed stroke in red
      _userStrokeNotifier.value = UserStroke(
        points: userPoints,
        color: AppColors.error,
      );
      _failedAttemptsThisStroke++;

      setState(() {
        _validationFeedback = result.errorMessage ?? 'Nét vẽ chưa đúng.';
        _feedbackColor = AppColors.error;
      });

      // Clear the user's drawing after 700ms so they can try again
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted && _failedAttemptsThisStroke > 0) {
          if (_userStrokeNotifier.value.color == AppColors.error) {
            _userStrokeNotifier.value =
                const UserStroke(points: [], color: Colors.blue);
          }
        }
      });
    }
  }

  void _acceptCurrentStroke(double score) {
    setState(() {
      _completedStrokeIndexes.add(_currentStrokeIndex);
      _currentRoundStrokeScores.add(score);

      _userStrokeNotifier.value =
          const UserStroke(points: [], color: Colors.blue);
      _failedAttemptsThisStroke = 0;

      // Start snap animation on this stroke
      _animatingStrokeIndex = _currentStrokeIndex;
      _snapAnimationController.forward(from: 0.0);

      _currentStrokeIndex++;

      if (_currentStrokeIndex >= _strokePaths.length) {
        _completeCurrentRound();
      } else {
        final nextNum = _currentStrokeIndex + 1;
        final totalNum = _strokePaths.length;
        _validationFeedback = 'Đúng rồi! Tiếp tục nét $nextNum/$totalNum.';
        _feedbackColor = AppColors.success;
      }
    });
  }

  void _completeCurrentRound() {
    final roundConfig = _roundConfigs[_currentRoundIndex];
    final duration = DateTime.now().difference(_roundStartedAt!).inMilliseconds;
    final roundScore = _currentRoundStrokeScores.isEmpty
        ? 0.0
        : _currentRoundStrokeScores.reduce((a, b) => a + b) /
            _currentRoundStrokeScores.length;

    final drawnStrokes = _strokePaths.length - roundConfig.prefilledStrokeCount;

    final roundResult = HanziRoundResult(
      roundNumber: roundConfig.roundNumber,
      mode: roundConfig.mode,
      drawnStrokeCount: drawnStrokes,
      attemptCount: _totalAttempts,
      score: roundScore,
      durationMilliseconds: duration,
    );

    _completedRoundResults.add(roundResult);

    if (_currentRoundIndex == 9) {
      // Do not expose "next" before the idempotent reward/progress write finishes.
      _isRoundCompleted = false;
      _isPersistingSession = true;
      _persistError = null;
      _validationFeedback = 'Đang lưu kết quả luyện viết...';
      _feedbackColor = AppColors.success;
      unawaited(_finishSessionPersistence());
    } else {
      setState(() {
        _isRoundCompleted = true;
        _validationFeedback = 'Hoàn thành lượt vẽ!';
        _feedbackColor = AppColors.success;
      });
    }
  }

  Future<void> _saveProgress() => controller.saveProgress(
        widget.characterId,
        List.of(_completedRoundResults),
        sourceContext: widget.sourceContext,
      );

  Future<void> _finishSessionPersistence() async {
    await _saveProgress();
    if (!mounted) return;
    final result = controller.learningResult.value;
    setState(() {
      _isPersistingSession = false;
      if (result == null) {
        _persistError =
            'Chưa lưu được kết quả. Tiến độ chưa thay đổi, hãy thử lưu lại.';
        _isSessionCompleted = false;
        return;
      }
      _persistError = null;
      _isSessionCompleted = true;
      _validationFeedback = result.passed
          ? 'Luyện tập hoàn thành!'
          : 'Đã lưu kết quả. Cần luyện thêm để mở chữ tiếp theo.';
      _feedbackColor =
          result.passed ? AppColors.success : AppColors.orange;
    });
  }

  void _goToNextRound() {
    _autoNextRoundTimer?.cancel();
    setState(() {
      _currentRoundIndex++;
      _initializeRound(_roundConfigs[_currentRoundIndex]);
    });
  }

  Future<void> _goToNextCharacter() async {
    final result = controller.learningResult.value;
    if (result == null) {
      setState(() {
        _persistError =
            'Kết quả chưa được lưu. Không thể mở bài tiếp theo lúc này.';
      });
      return;
    }
    if (!result.passed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cần đạt ít nhất 70 điểm để mở chữ tiếp theo.'),
        ),
      );
      return;
    }

    if (widget.returnToLearningPath) {
      Navigator.pop(context, true);
      return;
    }

    final request = _loadRequest;
    final next = await controller.nextCharacter(widget.characterId);
    if (!mounted || request != _loadRequest || !next.hasCharacters) return;
    if (next.id != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HanziWritingScreen(
            characterId: next.id!,
            sourceContext: widget.sourceContext,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hết chữ trong danh sách!')),
      );
    }
  }

  Future<void> _resetWholeSession() async {
    _autoNextRoundTimer?.cancel();
    _hintTimer?.cancel();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentRoundIndex = 0;
      _completedRoundResults.clear();
      _isRoundCompleted = false;
      _isSessionCompleted = false;
      _isPersistingSession = false;
      _persistError = null;
    });

    try {
      await controller.beginPractice(
        widget.characterId,
        sourceContext: widget.sourceContext,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _initializeRound(_roundConfigs[_currentRoundIndex]);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Không bắt đầu được lượt luyện mới. Vui lòng thử lại.';
      });
    }
  }

  String _buildRoundInstruction({
    required HanziPracticeMode mode,
    required int prefilledStrokeCount,
  }) {
    switch (mode) {
      case HanziPracticeMode.guidedTrace:
        return 'Viết theo nét được hướng dẫn';
      case HanziPracticeMode.completeRemaining:
        if (prefilledStrokeCount > 0) {
          return '$prefilledStrokeCount nét đã có sẵn · Hoàn thành các nét còn lại';
        }
        return 'Hoàn thành các nét còn lại';
      case HanziPracticeMode.faintCharacter:
        return 'Viết lại toàn bộ chữ';
      case HanziPracticeMode.startPointOnly:
        return 'Chỉ có điểm bắt đầu làm gợi ý';
      case HanziPracticeMode.fromScratch:
        return 'Viết toàn bộ chữ theo trí nhớ';
    }
  }

  String get _statusMessage {
    if (_isRoundCompleted || _isSessionCompleted) {
      return '';
    }
    return _validationFeedback;
  }

  @override
  Widget build(BuildContext context) {
    if (_isPersistingSession) {
      return LearningScaffold(
        title: _character != null
            ? 'Viết chữ: ${_character!.character}'
            : 'Viết chữ Hán',
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 14),
              Text('Đang lưu XP và tiến độ...'),
            ],
          ),
        ),
      );
    }

    if (_persistError != null) {
      return LearningScaffold(
        title: _character != null
            ? 'Viết chữ: ${_character!.character}'
            : 'Viết chữ Hán',
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.sync_problem_rounded,
                  size: 58,
                  color: AppColors.error,
                ),
                const SizedBox(height: 14),
                Text(
                  _persistError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _isPersistingSession = true;
                      _persistError = null;
                    });
                    unawaited(_finishSessionPersistence());
                  },
                  icon: const Icon(Icons.sync_rounded),
                  label: const Text('Lưu lại kết quả'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isSessionCompleted) {
      final result = controller.learningResult.value!;
      return WritingSessionSummary(
        results: List.unmodifiable(_completedRoundResults),
        character: _character?.character ?? "",
        passed: result.passed,
        nextActionLabel:
            widget.returnToLearningPath ? 'Mở chữ tiếp theo' : 'Học chữ tiếp theo',
        closeActionLabel:
            widget.returnToLearningPath ? 'Về lộ trình' : 'Danh sách',
        onNextCharacter: _goToNextCharacter,
        onRetry: _resetWholeSession,
        onClose: () => Navigator.pop(context, result.passed),
      );
    }

    final currentConfig =
        (_isLoading || _errorMessage != null || _roundConfigs.isEmpty)
            ? null
            : _roundConfigs[_currentRoundIndex];

    return LearningScaffold(
      title: _character != null
          ? 'Viết chữ: ${_character!.character}'
          : 'Viết chữ Hán',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 64, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadCharacter,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildPracticeContent(context, currentConfig!),
    );
  }

  Future<void> _playPronunciation() async {
    final character = _character;
    if (character == null || _isPronouncing) return;
    if (mounted) setState(() => _isPronouncing = true);
    try {
      final audioUrl = character.audioUrl?.trim();
      if (audioUrl != null && audioUrl.isNotEmpty) {
        await _pronunciationPlayer.stop();
        await _pronunciationPlayer.play(UrlSource(audioUrl));
      } else {
        await _ttsService.speak(character.character);
      }
    } catch (_) {
      await _ttsService.speak(character.character);
    } finally {
      if (mounted) setState(() => _isPronouncing = false);
    }
  }

  Widget _buildCharacterMetadata() {
    final character = _character!;
    final hasStandalone =
        character.pinyin?.trim().isNotEmpty == true ||
        character.meaning?.trim().isNotEmpty == true;

    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  hasStandalone
                      ? (character.pinyin ?? '')
                      : character.character,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Nghe phát âm',
                visualDensity: VisualDensity.compact,
                onPressed: _isPronouncing ? null : _playPronunciation,
                icon: Icon(
                  _isPronouncing
                      ? Icons.graphic_eq_rounded
                      : Icons.volume_up_rounded,
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
          if (character.meaning?.trim().isNotEmpty == true)
            Text(
              character.meaning!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
            )
          else if (character.contextWord?.trim().isNotEmpty == true) ...[
            Text(
              'Trong từ: ${character.contextWord}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFB45309),
                fontWeight: FontWeight.w700,
              ),
            ),
            if (character.contextPinyin?.trim().isNotEmpty == true)
              Text(
                character.contextPinyin!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.muted,
                ),
              ),
            if (character.contextMeaning?.trim().isNotEmpty == true)
              Text(
                character.contextMeaning!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.muted,
                ),
              ),
          ] else
            const Text(
              'Chưa có pinyin/nghĩa riêng đã kiểm duyệt.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFB45309),
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCharacterHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: ResponsiveHelper.contentMaxWidth(context)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Standalone character metadata is separated from context-word metadata.
                _buildCharacterMetadata(),
                const SizedBox(width: 12),
                // Right Column (Round/Stroke stats)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lượt ${_currentRoundIndex + 1}/10',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nét ${math.min(_currentStrokeIndex + 1, _strokePaths.length)}/${_strokePaths.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStrokeFeedback() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 30,
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _statusMessage.isEmpty
            ? const SizedBox.shrink()
            : Text(
                _statusMessage,
                key: ValueKey<String>(_statusMessage),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _feedbackColor == AppColors.error
                      ? AppColors.error
                      : _feedbackColor == AppColors.success
                          ? Colors.green[700]
                          : Colors.black87,
                ),
              ),
      ),
    );
  }

  void _clearCurrentStroke() {
    if (_isRoundCompleted || _isSessionCompleted) return;
    _userStrokeNotifier.value =
        const UserStroke(points: [], color: Colors.blue);
    setState(() {
      _validationFeedback =
          'Đã xóa nét đang viết. Hãy thử lại nét ${_currentStrokeIndex + 1}/${_strokePaths.length}.';
      _feedbackColor = Colors.grey;
    });
  }

  void _undoAcceptedStroke() {
    if (_isRoundCompleted ||
        _isSessionCompleted ||
        _roundConfigs.isEmpty ||
        _currentStrokeIndex <= 0) {
      _clearCurrentStroke();
      return;
    }
    final config = _roundConfigs[_currentRoundIndex];
    if (_currentStrokeIndex <= config.prefilledStrokeCount) {
      _clearCurrentStroke();
      return;
    }
    setState(() {
      _currentStrokeIndex--;
      _completedStrokeIndexes.remove(_currentStrokeIndex);
      if (_currentRoundStrokeScores.isNotEmpty) {
        _currentRoundStrokeScores.removeLast();
      }
      _animatingStrokeIndex = null;
      _userStrokeNotifier.value =
          const UserStroke(points: [], color: Colors.blue);
      _validationFeedback =
          'Đã hoàn tác. Viết lại nét ${_currentStrokeIndex + 1}/${_strokePaths.length}.';
      _feedbackColor = Colors.grey;
    });
  }

  void _showHintForCurrentStroke() {
    if (_isRoundCompleted ||
        _isSessionCompleted ||
        _currentStrokeIndex >= _strokePaths.length) {
      return;
    }
    _hintTimer?.cancel();
    setState(() => _showTemporaryHint = true);
    _hintTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _showTemporaryHint = false);
    });
  }

  Widget _buildDrawingSurface(
      BoxConstraints constraints, HanziPracticeRoundConfig currentConfig) {
    return GestureDetector(
      onPanStart: (details) => _handlePanStart(details, constraints),
      onPanUpdate: (details) => _handlePanUpdate(details, constraints),
      onPanEnd: (details) => _handlePanEnd(details, constraints),
      child: Stack(
        children: [
          // 1. Static grid guideline
          RepaintBoundary(
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: HanziGridPainter(),
            ),
          ),
          // 2. Character SVG template and snap animations
          RepaintBoundary(
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: HanziWritingPainter(
                strokePaths: _strokePaths,
                completedIndexes: Set.from(_completedStrokeIndexes),
                currentIndex: _currentStrokeIndex,
                viewBoxWidth: _character!.viewBoxWidth,
                viewBoxHeight: _character!.viewBoxHeight,
                guideOpacity: _showTemporaryHint
                    ? math.max(currentConfig.guideOpacity, 0.20)
                    : currentConfig.guideOpacity,
                showCurrentStroke:
                    currentConfig.showCurrentStroke || _showTemporaryHint,
                showStartPoint:
                    currentConfig.showStartPoint || _showTemporaryHint,
                showDirectionArrow:
                    currentConfig.showDirectionArrow || _showTemporaryHint,
                animatingStrokeIndex: _animatingStrokeIndex,
                snapAnimationValue: _snapAnimationController.value,
              ),
            ),
          ),
          // 3. User active hand drawing points (optimised repaint using ValueListenableBuilder)
          RepaintBoundary(
            child: ValueListenableBuilder<UserStroke>(
              valueListenable: _userStrokeNotifier,
              builder: (context, stroke, child) {
                return CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: UserStrokePainter(
                    points: stroke.points,
                    strokeColor: stroke.color,
                  ),
                );
              },
            ),
          ),
          // 4. Round Complete Overlay Card
          if (_isRoundCompleted)
            WritingRoundCompletion(
                roundNumber: currentConfig.roundNumber,
                roundScore: _currentRoundStrokeScores.isEmpty
                    ? 0
                    : _currentRoundStrokeScores.reduce((a, b) => a + b) /
                        _currentRoundStrokeScores.length,
                currentRoundIndex: _currentRoundIndex,
                onContinue: _goToNextRound),
        ],
      ),
    );
  }

  Widget _buildWritingTools(HanziPracticeRoundConfig currentConfig) {
    final canUndo = !_isRoundCompleted &&
        !_isSessionCompleted &&
        _currentStrokeIndex > currentConfig.prefilledStrokeCount;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Tooltip(
            message: 'Hoàn tác nét vừa hoàn thành',
            child: IconButton.filledTonal(
              onPressed: canUndo ? _undoAcceptedStroke : null,
              icon: const Icon(Icons.undo_rounded),
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: 'Xóa nét đang viết',
            child: IconButton.filledTonal(
              onPressed: _isRoundCompleted || _isSessionCompleted
                  ? null
                  : _clearCurrentStroke,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: 'Gợi ý nét hiện tại',
            child: IconButton.filledTonal(
              onPressed: _isRoundCompleted || _isSessionCompleted
                  ? null
                  : _showHintForCurrentStroke,
              icon: Icon(
                _showTemporaryHint
                    ? Icons.lightbulb_rounded
                    : Icons.lightbulb_outline_rounded,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWritingCanvas(HanziPracticeRoundConfig currentConfig) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 390,
              maxHeight: 390,
            ),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return _buildDrawingSurface(constraints, currentConfig);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPracticeContent(
      BuildContext context, HanziPracticeRoundConfig currentConfig) {
    return SafeArea(
      child: Column(
        children: [
          // Header: two columns layout
          _buildCharacterHeader(context),
          const SizedBox(height: 14),

          // Progress dots
          WritingRoundProgress(currentRoundIndex: _currentRoundIndex),
          const SizedBox(height: 10),

          // Mode description
          Text(
            _buildRoundInstruction(
              mode: currentConfig.mode,
              prefilledStrokeCount: currentConfig.prefilledStrokeCount,
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 20),

          // Status feedback above the board (using AnimatedSwitcher)
          _buildStrokeFeedback(),
          const SizedBox(height: 10),

          _buildWritingTools(currentConfig),
          const SizedBox(height: 10),

          // Writing Canvas Area
          _buildWritingCanvas(currentConfig),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class UserStroke {
  final List<Offset> points;
  final Color color;

  const UserStroke({
    required this.points,
    required this.color,
  });
}
