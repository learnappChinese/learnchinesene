import 'package:flutter/material.dart';

abstract final class DuoGameVisuals {
  static IconData icon(String code) {
    switch (code) {
      case 'learn_words':
        return Icons.psychology;
      case 'word_connect':
      case 'match_pairs':
        return Icons.link;
      case 'select_answer':
        return Icons.adjust;
      case 'listen_select':
        return Icons.headphones;
      case 'translate':
        return Icons.translate;
      case 'gap_fill':
        return Icons.edit;
      case 'tap_complete':
        return Icons.extension;
      case 'dialogue':
        return Icons.chat_bubble;
      case 'sentence_order':
        return Icons.shuffle;
      case 'speaking':
        return Icons.mic;
      default:
        return Icons.videogame_asset;
    }
  }

  static Color color(String code) {
    switch (code) {
      case 'learn_words':
        return Colors.green;
      case 'word_connect':
      case 'match_pairs':
        return Colors.blue;
      case 'select_answer':
        return Colors.orange;
      case 'listen_select':
        return Colors.purple;
      case 'translate':
        return Colors.red;
      case 'gap_fill':
        return Colors.teal;
      case 'tap_complete':
        return Colors.indigo;
      case 'dialogue':
        return Colors.pink;
      case 'sentence_order':
        return Colors.cyan;
      case 'speaking':
        return Colors.amber.shade800;
      default:
        return Colors.blueGrey;
    }
  }

  static String emoji(String code) {
    switch (code) {
      case 'learn_words':
        return '🧠';
      case 'word_connect':
      case 'match_pairs':
        return '🔗';
      case 'select_answer':
        return '🎯';
      case 'listen_select':
        return '🎧';
      case 'translate':
        return '🇨🇳';
      case 'gap_fill':
        return '✏️';
      case 'tap_complete':
        return '🧩';
      case 'dialogue':
        return '💬';
      case 'sentence_order':
        return '🔀';
      case 'speaking':
        return '🗣️';
      default:
        return '🎮';
    }
  }
}
