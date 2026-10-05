import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'shared_tab_background.dart';
import 'tab_header.dart';
import 'tab_card_text.dart';

class HomeLearningTab extends StatelessWidget {
  const HomeLearningTab({
    super.key,
    required this.onPractice,
    required this.onVocabulary,
    required this.onLessons,
    required this.onConversation,
  });

  final VoidCallback onPractice, onVocabulary, onLessons, onConversation;

  @override
  Widget build(BuildContext context) {
    final bottomSpace = 122.w + MediaQuery.viewPaddingOf(context).bottom;
    return SharedTabBackground(
      child: Column(children: [
        const TabHeader(
          icon: Icons.menu_book_rounded,
          title: 'Học tập',
          accentTitle: 'chuyên sâu',
          subtitle: 'Chọn kỹ năng bạn muốn cải thiện hôm nay',
        ),
        Expanded(
          child: SingleChildScrollView(
            key: const ValueKey('learning-scroll'),
            padding: EdgeInsets.only(top: 4.w),
            child: Column(children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(children: [
                  _LearningCard(
                    title: 'Luyện tập & Thực hành',
                    subtitle: 'Luyện viết, phát âm, flashcards và ôn tập HSK',
                    asset: 'assets/images/backgrounds/learning_practice.png',
                    color: const Color(0xFF09A51F),
                    background: const Color(0xFFF3FCF1),
                    height: 128.w,
                    onTap: onPractice,
                  ),
                  SizedBox(height: 8.w),
                  _LearningCard(
                    title: 'Kho từ vựng HSK',
                    subtitle: 'Xem từ theo cấp độ HSK và bài học',
                    asset:
                        'assets/images/backgrounds/learning_vocabulary.png',
                    color: const Color(0xFF25BA81),
                    background: const Color(0xFFF0FCFB),
                    height: 128.w,
                    onTap: onVocabulary,
                  ),
                  SizedBox(height: 8.w),
                  _LearningCard(
                    title: 'Bài học chuyên đề AI',
                    subtitle: 'Tự động biên soạn bài học và ngữ pháp',
                    asset: 'assets/images/backgrounds/learning_lessons.png',
                    color: const Color(0xFFFF8809),
                    background: const Color(0xFFFFFAEC),
                    height: 128.w,
                    onTap: onLessons,
                  ),
                  SizedBox(height: 8.w),
                  _LearningCard(
                    title: 'Hội thoại tình huống AI',
                    subtitle: 'Luyện giao tiếp qua các chủ đề thông minh',
                    asset:
                        'assets/images/backgrounds/learning_conversation.png',
                    color: const Color(0xFF168CFF),
                    background: const Color(0xFFF4F7FF),
                    height: 128.w,
                    onTap: onConversation,
                  ),
                ]),
              ),
              SizedBox(height: bottomSpace),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _LearningCard extends StatelessWidget {
  const _LearningCard({
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.color,
    required this.background,
    required this.height,
    required this.onTap,
  });

  final String title, subtitle, asset;
  final Color color, background;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24.r);
    return Container(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: [
        BoxShadow(
            color: const Color(0x226B662A),
            blurRadius: 13.r,
            offset: Offset(0, 5.w)),
      ]),
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: Colors.white, width: 4.w)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                      children: [
                        Positioned.fill(
                          child: ExcludeSemantics(
                            child: Ink.image(
                                image: AssetImage(asset), fit: BoxFit.fill),
                          ),
                        ),
                        Container(
                          constraints: BoxConstraints(minHeight: height),
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.fromLTRB(
                              constraints.maxWidth * .38, 14.w, 58.w, 14.w),
                          child: TabCardText(
                            title: title,
                            description: subtitle,
                            titleColor: const Color(0xFF080F0C),
                            descriptionColor: const Color(0xFF24382C),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          bottom: 0,
                          right: 16.w,
                          width: 34.w,
                          child: IgnorePointer(
                            child: ExcludeSemantics(
                              child: Center(
                                child: Container(
                                  width: 34.w,
                                  height: 34.w,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: color.withValues(alpha: .15),
                                          blurRadius: 7.r,
                                          offset: Offset(0, 3.w)),
                                    ],
                                  ),
                                  child: Icon(Icons.chevron_right_rounded,
                                      color: color, size: 29.sp),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ))),
      ),
    );
  }
}
