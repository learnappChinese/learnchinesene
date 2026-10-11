import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/learning_theme.dart';

class LearningAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LearningAppBar({
    super.key,
    required this.title,
    this.actions = const <Widget>[],
    this.leading,
    this.bottom,
  });

  final String title;
  final List<Widget> actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) => AppBar(
        systemOverlayStyle: LearningSystemUi.overlay,
        backgroundColor: LearningColors.background,
        foregroundColor: LearningColors.ink,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: leading,
        title: Text(title, style: LearningTypography.screenTitle),
        actions: actions,
        bottom: bottom,
      );
}

class LearningScaffold extends StatelessWidget {
  const LearningScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const <Widget>[],
    this.leading,
    this.bottom,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset,
    this.useSafeArea = true,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool? resizeToAvoidBottomInset;
  final bool useSafeArea;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: LearningSystemUi.overlay,
        child: Scaffold(
          backgroundColor: LearningColors.background,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          appBar: LearningAppBar(
            title: title,
            actions: actions,
            leading: leading,
            bottom: bottom,
          ),
          body: useSafeArea ? SafeArea(top: false, child: body) : body,
          bottomNavigationBar: bottomNavigationBar,
          floatingActionButton: floatingActionButton,
        ),
      );
}

class LearningPrimaryButton extends StatelessWidget {
  const LearningPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.play_arrow_rounded,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: LearningColors.jade,
            foregroundColor: Colors.white,
            disabledBackgroundColor: LearningColors.locked,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: .4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LearningRadius.md),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
}
