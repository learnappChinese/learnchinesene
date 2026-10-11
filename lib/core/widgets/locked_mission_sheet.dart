import 'package:flutter/material.dart';

import '../theme/learning_theme.dart';
import 'learning_scaffold.dart';

Future<void> showLockedMissionSheet(
  BuildContext context, {
  required String title,
  required String message,
  String? requiredTitle,
  VoidCallback? onViewRequired,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      padding: EdgeInsets.fromLTRB(
        LearningSpacing.lg,
        LearningSpacing.md,
        LearningSpacing.lg,
        LearningSpacing.lg + MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      decoration: const BoxDecoration(
        color: LearningColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LearningRadius.lg),
        ),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 42,
          height: 4,
          decoration: BoxDecoration(
            color: LearningColors.surfaceStrong,
            borderRadius: BorderRadius.circular(LearningRadius.pill),
          ),
        ),
        const SizedBox(height: LearningSpacing.md),
        const Icon(Icons.lock_rounded, size: 42, color: LearningColors.red),
        const SizedBox(height: LearningSpacing.sm),
        Text(title, style: LearningTypography.screenTitle),
        const SizedBox(height: LearningSpacing.sm),
        Text(
          message,
          textAlign: TextAlign.center,
          style: LearningTypography.body,
        ),
        if (requiredTitle != null) ...[
          const SizedBox(height: LearningSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(LearningSpacing.md),
            decoration: BoxDecoration(
              color: LearningColors.surfaceStrong,
              borderRadius: BorderRadius.circular(LearningRadius.md),
            ),
            child: Row(children: [
              const Icon(Icons.radio_button_unchecked_rounded,
                  color: LearningColors.orange),
              const SizedBox(width: LearningSpacing.sm),
              Expanded(
                child: Text(
                  requiredTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ]),
          ),
        ],
        const SizedBox(height: LearningSpacing.lg),
        LearningPrimaryButton(
          label: onViewRequired == null ? 'ĐÃ HIỂU' : 'XEM NHIỆM VỤ CẦN LÀM',
          icon: onViewRequired == null
              ? Icons.check_rounded
              : Icons.route_rounded,
          onPressed: () {
            Navigator.of(sheetContext).pop();
            onViewRequired?.call();
          },
        ),
      ]),
    ),
  );
}
