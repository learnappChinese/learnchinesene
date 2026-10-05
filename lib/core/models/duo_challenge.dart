import 'dart:convert';

class DuoChallenge {
  final String id;
  final String type;
  final String? prompt;
  final String? tts;
  final String? slowTts;

  final List<String>? choicesText;
  final List<String>? choicesTts;
  final List<String>? choicesImage;

  final List<String>? tokensText;
  final List<String>? tokensTts;
  final List<String>? tokensHints;

  final List<int>? choicesCorrect;

  final String? solutions;

  DuoChallenge({
    required this.id,
    required this.type,
    this.prompt,
    this.tts,
    this.slowTts,
    this.choicesText,
    this.choicesTts,
    this.choicesImage,
    this.tokensText,
    this.tokensTts,
    this.tokensHints,
    this.choicesCorrect,
    this.solutions,
  });

  factory DuoChallenge.fromMap(Map<String, dynamic> map) {
    return DuoChallenge(
      id: '${map['id'] ?? ''}',
      type: '${map['type'] ?? ''}',
      prompt: map['prompt']?.toString(),
      tts: map['tts']?.toString(),
      slowTts: map['slow_tts']?.toString(),
      choicesText: _parseStringList(map['choices_text']),
      choicesTts: _parseStringList(map['choices_tts']),
      choicesImage: _parseStringList(map['choices_image']),
      tokensText: _parseStringList(map['tokens_text']),
      tokensTts: _parseStringList(map['tokens_tts']),
      tokensHints: _parseStringList(map['tokens_hints']),
      choicesCorrect: _parseIntList(map['choices_correct']),
      solutions: _parseSolutions(map['solutions']),
    );
  }

  static List<dynamic>? _asList(dynamic value) {
    if (value == null) return null;
    if (value is List) return value;
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        return decoded is List ? decoded : null;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static List<String>? _parseStringList(dynamic value) {
    final list = _asList(value);
    if (list == null) return null;
    return list.map((item) => item.toString()).toList();
  }

  static List<int>? _parseIntList(dynamic value) {
    final list = _asList(value);
    if (list == null) return null;
    return list.map((item) {
      if (item == true) return 1;
      if (item == false) return 0;
      if (item is num) return item.toInt();
      return int.tryParse(item.toString()) ?? 0;
    }).toList();
  }

  static String? _parseSolutions(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((item) => item.toString()).join(' ');
        }
      } catch (_) {}
      return value;
    }
    if (value is List) {
      return value.map((item) => item.toString()).join(' ');
    }
    return value.toString();
  }
}
