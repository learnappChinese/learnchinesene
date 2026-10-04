import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'tab_card_text.dart';

/// Scenic action card shared by the Progress and Personal tabs.
class HomeIllustratedCard extends StatelessWidget {
  const HomeIllustratedCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.ink,
    required this.accent,
    required this.background,
    required this.minHeight,
    required this.scale,
    required this.onTap,
    this.textStart = .40,
  });

  final String title, subtitle, asset;
  final Color ink, accent, background;
  final double minHeight, scale, textStart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24.r);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: const Color(0x24635D3B),
            blurRadius: 15 * scale,
            offset: Offset(0, 7 * scale),
          ),
        ],
      ),
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: Colors.white, width: 4.w),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: LayoutBuilder(builder: (context, constraints) {
            return Stack(
              children: [
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: Ink.image(
                      image: AssetImage('assets/images/backgrounds/$asset.png'),
                      fit: BoxFit.cover,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
                Container(
                  constraints: BoxConstraints(minHeight: minHeight),
                  alignment: const Alignment(-1, -.15),
                  padding: EdgeInsets.fromLTRB(
                    constraints.maxWidth * textStart,
                    20 * scale,
                    52 * scale,
                    20 * scale,
                  ),
                  child: TabCardText(
                    title: title,
                    description: subtitle,
                    titleColor: ink,
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 12 * scale,
                  child: IgnorePointer(
                    child: ExcludeSemantics(
                      child: Center(
                        child: Container(
                          width: 37 * scale,
                          height: 37 * scale,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: .13),
                                blurRadius: 8 * scale,
                                offset: Offset(0, 3 * scale),
                              ),
                            ],
                          ),
                          child: Icon(Icons.chevron_right_rounded,
                              color: accent, size: 32 * scale),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
