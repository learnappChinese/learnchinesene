import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../home/widgets/home_decorations.dart';
import '../../home/widgets/shared_tab_background.dart';
import '../../home/widgets/tab_header.dart';
import '../../home/widgets/tab_card_text.dart';
import 'game_journey_button.dart';

/// Shared illustrated game menu for the app and the standalone game preview.
class GameHubView extends StatelessWidget {
  const GameHubView({
    super.key,
    required this.onBossBattle,
    required this.onRadicalBuilder,
    required this.onToneNinja,
    required this.onRestaurant,
    required this.onQuickAnswer,
    this.onStageMap,
  });

  final VoidCallback onBossBattle, onRadicalBuilder, onToneNinja;
  final VoidCallback onRestaurant, onQuickAnswer;
  final VoidCallback? onStageMap;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: SharedTabBackground(
        child: Column(children: [
          TabHeader(
            icon: Icons.sports_esports_rounded,
            title: 'Trò chơi',
            subtitle: 'Học tiếng Trung qua những trò chơi thú vị!',
            trailingSize: 84.w,
            trailing: onStageMap == null
                ? null
                : FittedBox(child: GameJourneyButton(onTap: onStageMap!)),
          ),
          Expanded(
            child: SingleChildScrollView(
              key: const PageStorageKey('game-hub-scroll'),
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w,
                  122.w + MediaQuery.viewPaddingOf(context).bottom),
              child: Column(children: [
                _GameCard(
                  title: 'Boss Battle',
                  description: 'Đánh bại Boss bằng\nkiến thức tiếng Trung!',
                  asset: 'games_boss',
                  ink: const Color(0xFF7F190E),
                  accent: const Color(0xFFF51F17),
                  onTap: onBossBattle,
                ),
                SizedBox(height: 8.w),
                _GameCard(
                  title: 'Xây chữ Hán',
                  description: 'Xây chữ Hán từ bộ thủ',
                  asset: 'games_radicals',
                  ink: const Color(0xFF004C3C),
                  accent: const Color(0xFF2DBD37),
                  onTap: onRadicalBuilder,
                ),
                SizedBox(height: 8.w),
                _GameCard(
                  title: 'Tone Ninja',
                  description: 'Luyện thanh điệu\nnhư ninja',
                  asset: 'games_ninja',
                  character: 'assets/images/characters/panda_ninja.png',
                  ink: const Color(0xFF32136F),
                  accent: const Color(0xFF8845F7),
                  onTap: onToneNinja,
                ),
                SizedBox(height: 8.w),
                _GameCard(
                  title: 'Nhà hàng Trung Hoa',
                  description: 'Phục vụ món ăn\nbằng tiếng Trung',
                  asset: 'games_restaurant',
                  ink: const Color(0xFF71320D),
                  accent: const Color(0xFFFF8900),
                  onTap: onRestaurant,
                ),
                SizedBox(height: 8.w),
                _GameCard(
                  title: 'Trả lời nhanh',
                  description: 'Thử thách phản xạ\ntiếng Trung',
                  asset: 'games_quick',
                  ink: const Color(0xFF003E7C),
                  accent: const Color(0xFF159CFF),
                  onTap: onQuickAnswer,
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.title,
    required this.description,
    required this.asset,
    required this.ink,
    required this.accent,
    required this.onTap,
    this.character,
  });

  final String title, description, asset;
  final Color ink, accent;
  final VoidCallback onTap;
  final String? character;

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
        color: homeCream,
        shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: Colors.white, width: 4.w)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: LayoutBuilder(builder: (context, constraints) {
            return Stack(children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  child: Ink.image(
                    image: AssetImage('assets/images/backgrounds/$asset.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (character != null)
                Positioned(
                  left: 8.w,
                  top: 2.w,
                  bottom: -5.w,
                  width: constraints.maxWidth * .34,
                  child: ExcludeSemantics(
                    child: Image.asset(character!, fit: BoxFit.contain),
                  ),
                ),
              Container(
                constraints: BoxConstraints(minHeight: 128.w),
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.fromLTRB(
                    constraints.maxWidth * .38, 15.w, 58.w, 14.w),
                child: TabCardText(
                  title: title,
                  description: description,
                  titleColor: ink,
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
                                color: accent.withValues(alpha: .10),
                                blurRadius: 5.r,
                                offset: Offset(0, 2.w)),
                          ],
                        ),
                        child: Icon(Icons.chevron_right_rounded,
                            color: accent, size: 29.sp),
                      ),
                    ),
                  ),
                ),
              ),
            ]);
          }),
        ),
      ),
    );
  }
}
