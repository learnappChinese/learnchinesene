import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const gameJourneyButtonAsset = 'assets/images/icons/game_journey_button.png';

class GameJourneyButton extends StatelessWidget {
  const GameJourneyButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: 'Hành trình Ải',
        child: SizedBox(
          width: 92.w,
          height: 92.w,
          child: Stack(children: [
            Positioned.fill(
              child: ExcludeSemantics(
                child: Image.asset(
                  gameJourneyButtonAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            Positioned(
              left: 17.6.w,
              right: 17.6.w,
              top: 58.2.w,
              height: 16.2.w,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Hành trình',
                      style: TextStyle(
                        color: const Color(0xFFA45A20),
                        fontSize: 11.5.sp,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      )),
                ),
              ),
            ),
            Positioned.fill(
              child: Semantics(
                label: 'Hành trình',
                button: true,
                excludeSemantics: true,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(23.r),
                    onTap: onTap,
                  ),
                ),
              ),
            ),
          ]),
        ),
      );
}
