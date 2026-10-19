import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'widget/flashcard_content.dart';
import '../../core/theme/game_visual_tokens.dart';
import '../../core/theme/app_colors.dart';
import 'package:get/get.dart';
import 'controller/flashcards_controller.dart';
import '../../core/models/word.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/learning_scene_background.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key, this.controller});

  final FlashcardsController? controller;

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  int _selectedHskLevel = 1; // 1 to 6. 0 for "Review Due"
  List<Word> get _deck => controller.deck;
  int _currentIndex = 0;
  bool _isFlipped = false;
  int _deckRequest = 0;
  bool _isAnswering = false;

  static int _nextControllerId = 0;
  late final String _controllerTag;
  late final FlashcardsController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      controller = widget.controller!;
      _ownsController = false;
      _controllerTag = '';
    } else {
      _controllerTag = 'flashcards-${_nextControllerId++}';
      controller = Get.put(FlashcardsController(), tag: _controllerTag);
      _ownsController = true;
    }
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _loadDeck();
  }

  @override
  void dispose() {
    if (_ownsController) {
      Get.delete<FlashcardsController>(tag: _controllerTag);
    }
    _flipController.dispose();
    super.dispose();
  }

  Future<void> _loadDeck() async {
    _deckRequest++;
    setState(() {
      _isAnswering = false;
      _currentIndex = 0;
      _isFlipped = false;
    });
    _flipController.reset();
    await controller.loadDeck(_selectedHskLevel);
  }

  void _flipCard() {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) {
      _flipController.value = _isFlipped ? 0.0 : 1.0;
    } else {
      if (_isFlipped) {
        _flipController.reverse();
      } else {
        _flipController.forward();
      }
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  Future<void> _answerCard(String rating) async {
    if (_currentIndex >= _deck.length || _isAnswering) return;
    final request = _deckRequest;
    setState(() => _isAnswering = true);
    final word = _deck[_currentIndex];

    await controller.rate(word, rating);

    if (!mounted) return;
    if (request != _deckRequest) return;
    // Flip back & go to next card
    if (_isFlipped) {
      _flipCard();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    if (!mounted) return;
    if (request != _deckRequest) return;
    setState(() {
      _isAnswering = false;
      _currentIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Flashcards ôn tập',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: LearningSceneBackground(
        theme: LearningSceneTheme.bambooVillage,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildChip(int val, String label) {
    final isSelected = _selectedHskLevel == val;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedHskLevel = val;
            });
            _loadDeck();
          }
        },
        selectedColor: GameVisualTokens.primaryGreenSoft,
        checkmarkColor: GameVisualTokens.primaryGreenDark,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected
              ? GameVisualTokens.primaryGreen
              : const Color(0xFFF1E6CF),
        ),
        labelStyle: TextStyle(
          color: isSelected
              ? GameVisualTokens.primaryGreenDark
              : const Color(0xFF342E10),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildCardContainer(ThemeData theme) {
    final word = _deck[_currentIndex];
    final progress = _currentIndex / _deck.length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Thẻ: ${_currentIndex + 1} / ${_deck.length}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Độ chính xác: ${(progress * 100).round()}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.muted),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  GameVisualTokens.primaryGreen),
            ),
          ),
          const Spacer(),

          // 3D Flip Card
          SizedBox(
            width: double.infinity,
            height: 320,
            child: GestureDetector(
              onTap: _flipCard,
              child: AnimatedBuilder(
                animation: _flipAnimation,
                builder: (context, child) {
                  final angle = _flipAnimation.value * math.pi;
                  final isBack = angle >= math.pi / 2;
                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // perspective
                      ..rotateY(angle),
                    alignment: Alignment.center,
                    child: isBack
                        ? Transform(
                            transform: Matrix4.identity()..rotateY(math.pi),
                            alignment: Alignment.center,
                            child: FlashcardBack(word: word),
                          )
                        : FlashcardFront(word: word),
                  );
                },
              ),
            ),
          ),

          const Spacer(),

          // SRS Buttons visible when flipped
          AnimatedOpacity(
            opacity: _isFlipped ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: IgnorePointer(
              ignoring: !_isFlipped,
              child: Row(
                children: [
                  _buildSrsButton('hard', 'Khó', AppColors.error),
                  _buildSrsButton('good', 'Vừa', AppColors.orange),
                  _buildSrsButton('easy', 'Dễ', AppColors.success),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSrsButton(String val, String label, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: _isAnswering ? null : () => _answerCard(val),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildLevelFilters() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildChip(0, 'Cần ôn gấp'),
          ...List.generate(6, (i) => _buildChip(i + 1, 'HSK ${i + 1}')),
        ],
      ),
    );
  }

  Widget _buildDeckContent(ThemeData theme) {
    return Obx(() => controller.isLoading.value
        ? const Center(child: CircularProgressIndicator())
        : _deck.isEmpty
            ? FlashcardEmptyState(isReview: _selectedHskLevel == 0)
            : _currentIndex >= _deck.length
                ? FlashcardCompletion(onContinue: _loadDeck)
                : _buildCardContainer(theme));
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final maxWidth = ResponsiveHelper.contentMaxWidth(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          children: [
            // HSK level filter chips
            const SizedBox(height: 12),
            _buildLevelFilters(),
            const Divider(height: 24),

            Expanded(
              child: _buildDeckContent(theme),
            ),
          ],
        ),
      ),
    );
  }
}
