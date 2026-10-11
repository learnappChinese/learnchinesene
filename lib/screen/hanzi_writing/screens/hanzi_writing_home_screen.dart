import 'dart:async';
import 'package:flutter/material.dart';
import '../widget/writing_character_tile.dart';
import '../../../core/theme/app_colors.dart';
import 'package:get/get.dart';
import '../controller/hanzi_writing_home_controller.dart';
import '../../../core/models/hanzi_character.dart';
import '../../../core/widgets/learning_scene_background.dart';
import '../../../core/widgets/learning_scaffold.dart';
import '../../../core/theme/learning_theme.dart';
import 'hanzi_writing_screen.dart';

class HanziWritingHomeScreen extends StatefulWidget {
  const HanziWritingHomeScreen({super.key});

  @override
  State<HanziWritingHomeScreen> createState() => _HanziWritingHomeScreenState();
}

class _HanziWritingHomeScreenState extends State<HanziWritingHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _keyword = '';
  int? _selectedHskLevel;
  List<HanziCharacter> get _characters => controller.characters;

  static int _nextControllerId = 0;
  late final String _controllerTag;
  late final HanziWritingHomeController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'writing-home-${_nextControllerId++}';
    controller = Get.put(HanziWritingHomeController(), tag: _controllerTag);
    _loadCharacters();
  }

  @override
  void dispose() {
    Get.delete<HanziWritingHomeController>(tag: _controllerTag);
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCharacters() =>
      controller.loadCharacters(keyword: _keyword, hskLevel: _selectedHskLevel);

  void _onSearchChanged(String value) {
    controller.invalidateSearch();
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _keyword = value;
      });
      _loadCharacters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: 'Luyện viết chữ Hán',
      body: LearningSceneBackground(
        theme: LearningSceneTheme.bambooVillage,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildFilterChip(int? level, String label) {
    final isSelected = _selectedHskLevel == level;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (selected) {
          setState(() {
            _selectedHskLevel = selected ? level : null;
          });
          _loadCharacters();
        },
        selectedColor: AppColors.red.withValues(alpha: 0.2),
        checkmarkColor: AppColors.red,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.red : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Tìm theo chữ Hán, pinyin, nghĩa...',
          prefixIcon: const Icon(Icons.search, color: AppColors.muted),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFF0E7E5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFF0E7E5)),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelFilters() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip(null, 'Tất cả'),
          ...List.generate(6, (i) => _buildFilterChip(i + 1, 'HSK ${i + 1}')),
        ],
      ),
    );
  }

  Widget _buildCharacterList() {
    return Obx(() => controller.isLoading.value
        ? const Center(child: CircularProgressIndicator())
        : _characters.isEmpty
            ? const Center(
                child: Text(
                  'Không tìm thấy chữ Hán nào.',
                  style: TextStyle(color: AppColors.muted),
                ),
              )
            : ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _characters.length,
                itemBuilder: (context, index) {
                  final char = _characters[index];
                  // c.stroke_count is 0 or c.stroke_count < 1 when no paths are available

                  return WritingCharacterTile(
                      key: ValueKey(char.id),
                      char: char,
                      onTap: () {
                        if (char.strokeCount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Chữ này chưa có dữ liệu luyện viết.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                HanziWritingScreen(characterId: char.id),
                          ),
                        );
                      });
                },
              ));
  }

  Widget _buildBody() {
    return Obx(() {
      final due = _characters
          .where((character) =>
              character.learningState == HanziLearningState.needsReview ||
              character.learningState == HanziLearningState.learning)
          .length;
      return Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.all(LearningSpacing.md),
            decoration: BoxDecoration(
              color: LearningColors.jadeDark,
              borderRadius: LearningRadius.card,
              boxShadow: LearningShadow.card,
            ),
            child: Row(
              children: [
                const Icon(Icons.gesture_rounded,
                    color: LearningColors.gold, size: 38),
                const SizedBox(width: LearningSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TODAY\'S HANZI MISSION',
                          style: LearningTypography.eyebrow
                              .copyWith(color: LearningColors.gold)),
                      const SizedBox(height: 3),
                      Text(
                        due == 0
                            ? 'Chọn một chữ mới để luyện'
                            : '$due chữ cần luyện hôm nay',
                        style: LearningTypography.cardTitle
                            .copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildSearchField(),
          _buildLevelFilters(),
          const SizedBox(height: 8),
          Expanded(child: _buildCharacterList()),
        ],
      );
    });
  }
}
