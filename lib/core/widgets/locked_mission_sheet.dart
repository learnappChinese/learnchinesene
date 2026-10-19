import 'package:flutter/material.dart';

import '../theme/game_visual_tokens.dart';
import 'app_green_button.dart';

Future<void> showLockedMissionSheet(
  BuildContext context, {
  required String title,
  required String message,
  String? requiredTitle,
  VoidCallback? onViewRequired,
  String? actionLabel,
  IconData? actionIcon,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => AppSheetSurface(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0xFFF5C979), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F635D3B),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.lock_rounded,
              size: 30, color: Color(0xFFB45309)),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF342E10),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF5D5C54),
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (requiredTitle != null) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1E6CF)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: GameVisualTokens.primaryGreenSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag_rounded,
                    size: 16, color: GameVisualTokens.primaryGreenDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  requiredTitle,
                  style: const TextStyle(
                    color: Color(0xFF342E10),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 20),
        AppGreenButton(
          label: actionLabel ??
              (onViewRequired == null ? 'ĐÃ HIỂU' : 'XEM NHIỆM VỤ CẦN LÀM'),
          icon: actionIcon ??
              (onViewRequired == null
                  ? Icons.check_rounded
                  : Icons.route_rounded),
          height: 50,
          expand: true,
          onPressed: () {
            Navigator.of(sheetContext).pop();
            onViewRequired?.call();
          },
        ),
      ]),
    ),
  );
}

/// Khung bottom sheet dùng chung: nền kem, bo góc trên, thanh kéo,
/// tự chừa vùng home indicator.
class AppSheetSurface extends StatelessWidget {
  const AppSheetSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewPaddingOf(context).bottom +
        MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(22, 10, 22, 20 + bottom),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFDF6), Color(0xFFFFF4DE)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE6D9BE),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
