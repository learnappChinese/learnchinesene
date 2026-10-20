import 'package:flutter/material.dart';

import 'controller/flashcards_controller.dart';
import 'screens/flashcards_home_screen.dart';

/// Entrypoint của tính năng Flashcards ôn tập thông minh (FSRS + Anki Style).
class FlashcardsScreen extends StatelessWidget {
  const FlashcardsScreen({
    super.key,
    this.controller,
    this.initialLevel = 1,
  });

  final FlashcardsController? controller;
  final int initialLevel;

  @override
  Widget build(BuildContext context) {
    return FlashcardsHomeScreen(
      initialLevel: initialLevel,
    );
  }
}
