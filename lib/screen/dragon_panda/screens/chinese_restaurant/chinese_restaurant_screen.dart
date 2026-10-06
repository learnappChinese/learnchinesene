import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/database/db_helper.dart';
import 'widget/chinese_restaurant_options.dart';
import '../../widgets/game_screen_header.dart';
import '../../theme/app_colors.dart';

class ChineseRestaurantScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ChineseRestaurantScreen({super.key, required this.onBack});


  @override
  State<ChineseRestaurantScreen> createState() =>
      _ChineseRestaurantScreenState();
}

class _FoodItem {
  final String hanzi;
  final String pinyin;
  final String vietnamese;
  final String assetPath;
  final String emoji;

  const _FoodItem({
    required this.hanzi,
    required this.pinyin,
    required this.vietnamese,
    required this.assetPath,
    required this.emoji,
  });
}

class _RestaurantOrder {
  final String orderSentence;
  final String pinyinSentence;
  final String viTranslation;
  final _FoodItem targetFood;
  final List<_FoodItem> choices;

  _RestaurantOrder({
    required this.orderSentence,
    required this.pinyinSentence,
    required this.viTranslation,
    required this.targetFood,
    required this.choices,
  });
}

class _ChineseRestaurantScreenState extends State<ChineseRestaurantScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _isLoading = true;
  List<_RestaurantOrder> _orders = [];
  int _currentIndex = 0;
  int _score = 0;
  int _combo = 0;
  String? _selectedHanzi;
  bool _answered = false;

  final List<_FoodItem> _menuItems = const [
    _FoodItem(
      hanzi: '面条',
      pinyin: 'miàntiáo',
      vietnamese: 'Mì',
      assetPath: 'assets/images/foods/noodles.png',
      emoji: '🍜',
    ),
    _FoodItem(
      hanzi: '米饭',
      pinyin: 'mǐfàn',
      vietnamese: 'Cơm',
      assetPath: 'assets/images/foods/rice.png',
      emoji: '🍚',
    ),
    _FoodItem(
      hanzi: '饺子',
      pinyin: 'jiǎozi',
      vietnamese: 'Sủi cảo',
      assetPath: 'assets/images/foods/dumplings.png',
      emoji: '🥟',
    ),
    _FoodItem(
      hanzi: '包子',
      pinyin: 'bāozi',
      vietnamese: 'Bánh bao',
      assetPath: 'assets/images/foods/baozi.png',
      emoji: '🥟',
    ),
    _FoodItem(
      hanzi: '茶',
      pinyin: 'chá',
      vietnamese: 'Trà',
      assetPath: 'assets/images/foods/tea.png',
      emoji: '🍵',
    ),
    _FoodItem(
      hanzi: '咖啡',
      pinyin: 'kāfēi',
      vietnamese: 'Cà phê',
      assetPath: 'assets/images/foods/coffee.png',
      emoji: '☕',
    ),
    _FoodItem(
      hanzi: '果汁',
      pinyin: 'guǒzhī',
      vietnamese: 'Nước ép',
      assetPath: 'assets/images/foods/juice.png',
      emoji: '🧃',
    ),
    _FoodItem(
      hanzi: '牛奶',
      pinyin: 'niúnǎi',
      vietnamese: 'Sữa tươi',
      assetPath: 'assets/images/foods/milk.png',
      emoji: '🥛',
    ),
    _FoodItem(
      hanzi: '烤鸭',
      pinyin: 'kǎoyā',
      vietnamese: 'Vịt quay',
      assetPath: 'assets/images/foods/duck.png',
      emoji: '🍗',
    ),
    _FoodItem(
      hanzi: '豆腐',
      pinyin: 'dòufu',
      vietnamese: 'Đậu phụ',
      assetPath: 'assets/images/foods/tofu.png',
      emoji: '🧈',
    ),
    _FoodItem(
      hanzi: '火锅',
      pinyin: 'huǒguō',
      vietnamese: 'Lẩu',
      assetPath: 'assets/images/foods/hotpot.png',
      emoji: '🍲',
    ),
    _FoodItem(
      hanzi: '牛肉',
      pinyin: 'niúròu',
      vietnamese: 'Thịt bò',
      assetPath: 'assets/images/foods/beef.png',
      emoji: '🥩',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadGameData();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('zh-CN');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
    } catch (_) {}
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> _loadGameData() async {
    setState(() => _isLoading = true);
    final random = Random();
    List<_RestaurantOrder> generated = [];

    final sentenceTemplates = [
      (
        food: '面条',
        zh: '请给我一碗面条。',
        py: 'Qǐng gěi wǒ yī wǎn miàntiáo.',
        vi: 'Làm ơn cho tôi một bát mì.',
      ),
      (
        food: '米饭',
        zh: '我想吃一碗米饭。',
        py: 'Wǒ xiǎng chī yī wǎn mǐfàn.',
        vi: 'Tôi muốn ăn một bát cơm.',
      ),
      (
        food: '饺子',
        zh: '来一份热腾腾的饺子！',
        py: 'Lái yī fèn rè téngténg de jiǎozi!',
        vi: 'Cho một đĩa sủi cảo nóng hổi!',
      ),
      (
        food: '包子',
        zh: '请给我两个包子。',
        py: 'Qǐng gěi wǒ liǎng gè bāozi.',
        vi: 'Cho tôi hai cái bánh bao.',
      ),
      (
        food: '茶',
        zh: '服务员，请给我一杯茶。',
        py: 'Fúwùyuán, qǐng gěi wǒ yī bēi chá.',
        vi: 'Phục vụ ơi, cho tôi một cốc trà.',
      ),
      (
        food: '咖啡',
        zh: '我想喝一杯热咖啡。',
        py: 'Wǒ xiǎng hē yī bēi rè kāfēi.',
        vi: 'Tôi muốn uống một tách cà phê nóng.',
      ),
      (
        food: '果汁',
        zh: '来一杯新鲜的果汁。',
        py: 'Lái yī bēi xīnxiān de guǒzhī.',
        vi: 'Cho tôi một ly nước ép tươi mát.',
      ),
      (
        food: '牛奶',
        zh: '早上好，请给我一杯牛奶。',
        py: 'Zǎoshang hǎo, qǐng gěi wǒ yī bēi niúnǎi.',
        vi: 'Chào buổi sáng, cho tôi một cốc sữa.',
      ),
      (
        food: '烤鸭',
        zh: '今天我想吃北京烤鸭。',
        py: 'Jīntiān wǒ xiǎng chī Běijīng kǎoyā.',
        vi: 'Hôm nay tôi muốn ăn vịt quay Bắc Kinh.',
      ),
      (
        food: '豆腐',
        zh: '请来一份麻婆豆腐。',
        py: 'Qǐng lái yī fèn mápó dòufu.',
        vi: 'Làm ơn cho một đĩa đậu phụ Mapo.',
      ),
      (
        food: '火锅',
        zh: '天气很冷，我想吃火锅！',
        py: 'Tiānqì hěn lěng, wǒ xiǎng chī huǒguō!',
        vi: 'Trời lạnh quá, tôi muốn ăn lẩu!',
      ),
      (
        food: '牛肉',
        zh: '请给我一份炒牛肉。',
        py: 'Qǐng gěi wǒ yī fèn chǎo niúròu.',
        vi: 'Cho tôi một đĩa thịt bò xào.',
      ),
    ];

    final shuffled = List.of(sentenceTemplates)..shuffle(random);

    for (final item in shuffled) {
      final target = _menuItems.firstWhere(
        (m) => m.hanzi == item.food,
        orElse: () => _menuItems.first,
      );

      final otherFoods = _menuItems.where((m) => m.hanzi != target.hanzi).toList()
        ..shuffle(random);
      final choices = [target, otherFoods[0], otherFoods[1]]..shuffle(random);

      generated.add(_RestaurantOrder(
        orderSentence: item.zh,
        pinyinSentence: item.py,
        viTranslation: item.vi,
        targetFood: target,
        choices: choices,
      ));

      if (generated.length >= 10) break;
    }

    if (mounted) {
      setState(() {
        _orders = generated;
        _isLoading = false;
        _currentIndex = 0;
        _score = 0;
        _combo = 0;
        _selectedHanzi = null;
        _answered = false;
      });

      if (_orders.isNotEmpty) {
        _speak(_orders[0].orderSentence);
      }
    }
  }

  void _handleSelectFood(_FoodItem food) {
    if (_answered || _orders.isEmpty) return;

    final curr = _orders[_currentIndex];
    final isRight = (food.hanzi == curr.targetFood.hanzi);

    setState(() {
      _selectedHanzi = food.hanzi;
      _answered = true;
      if (isRight) {
        _combo++;
        _score += 100 + (_combo * 15);
      } else {
        _combo = 0;
      }
    });

    _speak(food.hanzi);

    Timer(const Duration(milliseconds: 950), () {
      if (!mounted) return;
      if (_currentIndex + 1 < _orders.length) {
        setState(() {
          _currentIndex++;
          _selectedHanzi = null;
          _answered = false;
        });
        _speak(_orders[_currentIndex].orderSentence);
      } else {
        _showVictoryDialog();
      }
    });
  }

  void _showVictoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF9EE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Center(
          child: Text(
            '👨‍🍳 Đầu Bếp Xuất Sắc!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD97706),
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tất cả thực khách đều hài lòng với món ăn bạn phục vụ!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
              ),
              child: Text(
                '⭐ Điểm số: $_score',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD97706),
                ),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _loadGameData();
            },
            child: const Text('Phục vụ tiếp',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onBack();
            },
            child: const Text('Về Menu',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/restaurant_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF71320D)),
            ),
          ),
          if (_isLoading)
            const Center(
                child: CircularProgressIndicator(color: Colors.white))
          else if (_orders.isEmpty)
            Center(
              child: ElevatedButton(
                onPressed: _loadGameData,
                child: const Text('Thử lại'),
              ),
            )
          else
            _buildGameContent(),
        ],
      ),
    );
  }

  Widget _buildCustomerOrder() {
    final curr = _orders[_currentIndex];

    return GestureDetector(
      onTap: () => _speak(curr.orderSentence),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.volume_up_rounded,
                    color: AppColors.primaryOrange, size: 24),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    curr.orderSentence,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              curr.pinyinSentence,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primaryOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '(${curr.viTranslation})',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodChoices() {
    final curr = _orders[_currentIndex];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Chọn đúng món khách đang gọi:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF92400E),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: curr.choices.map((food) {
              final isSelected = _selectedHanzi == food.hanzi;
              final isTarget = food.hanzi == curr.targetFood.hanzi;

              bool isCorrect = false;
              bool isWrong = false;

              if (_answered) {
                if (isTarget) {
                  isCorrect = true;
                } else if (isSelected) {
                  isWrong = true;
                }
              }

              return RestaurantFoodCard(
                hanzi: food.hanzi,
                vietnamese: food.vietnamese,
                assetPath: food.assetPath,
                fallbackEmoji: food.emoji,
                isCorrect: isCorrect,
                isWrong: isWrong,
                onTap: () => _handleSelectFood(food),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGameContent() {
    final total = _orders.length;
    final current = (_currentIndex + 1).clamp(1, total);
    final progress = total > 0 ? current / total : 0.0;

    return SafeArea(
      child: Column(
        children: [
          // Top App Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GameScreenHeader(
              title: 'Nhà hàng Trung Hoa',
              onBack: widget.onBack,
              onSettings: () {},
              titleSize: 20,
            ),
          ),

          // Customer Speech Bubble
          _buildCustomerOrder(),

          // Progress Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$current / $total  ($_score pts)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Panda Chef Behind Counter
          SizedBox(
            width: 190,
            height: 190,
            child: Image.asset(
              'assets/images/characters/panda_chef.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(
                child: Text('🐼🍜👨‍🍳', style: TextStyle(fontSize: 70)),
              ),
            ),
          ),
          const Spacer(),

          // 3 Food Choice Cards Tray
          _buildFoodChoices(),
        ],
      ),
    );
  }
}
