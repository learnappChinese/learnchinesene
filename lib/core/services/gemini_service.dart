import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class GeminiService {
  GeminiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _apiKey => AppConfigVer1Ne.geminiApiKey;
  String get _endpoint => AppConfigVer1Ne.geminiEndpoint;

  Future<dynamic> _generateJson({
    required String prompt,
    required Map<String, dynamic> schema,
    String? systemInstruction,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'Chưa cấu hình API Key cho Gemini. Vui lòng thêm --dart-define=GEMINI_API_KEY=... khi chạy/build.',
      );
    }

    final requestBody = {
      if (systemInstruction != null)
        'systemInstruction': {
          'role': 'system',
          'parts': [
            {'text': systemInstruction}
          ],
        },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': schema,
      }
    };

    final response = await _client.post(
      Uri.parse('$_endpoint?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = decoded['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('Gemini không trả về kết quả nào.');
      }
      final parts = candidates.first['content']?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw Exception('Nội dung phản hồi trống.');
      }
      final text = parts.first['text'] as String? ?? '';
      return jsonDecode(text.trim());
    } else {
      throw Exception(
          'Lỗi API Gemini: ${response.statusCode} ${response.body}');
    }
  }

  /// Dịch văn bản giữa tiếng Việt và tiếng Trung
  Future<Map<String, dynamic>> translate(String text) async {
    const prompt =
        'Translate the input text. If it is Vietnamese, translate to Chinese. If it is Chinese, translate to Vietnamese. Provide a detailed analysis including Pinyin, Vietnamese meaning, 2-3 example sentences, and 1-2 grammar notes.';

    final schema = {
      'type': 'OBJECT',
      'properties': {
        'source_lang': {
          'type': 'STRING',
          'description': 'Language of the input'
        },
        'target_lang': {
          'type': 'STRING',
          'description': 'Language of translation'
        },
        'hanzi': {'type': 'STRING', 'description': 'Translated Chinese text'},
        'pinyin': {'type': 'STRING', 'description': 'Pinyin of translation'},
        'vi_meaning': {
          'type': 'STRING',
          'description': 'Detailed Vietnamese meaning'
        },
        'examples': {
          'type': 'ARRAY',
          'items': {
            'type': 'OBJECT',
            'properties': {
              'zh': {
                'type': 'STRING',
                'description': 'Example sentence in Chinese'
              },
              'pinyin': {'type': 'STRING', 'description': 'Pinyin for example'},
              'vi': {
                'type': 'STRING',
                'description': 'Vietnamese translation of example'
              },
            },
            'required': ['zh', 'pinyin', 'vi'],
          }
        },
        'grammar_notes': {
          'type': 'ARRAY',
          'items': {'type': 'STRING'}
        }
      },
      'required': [
        'source_lang',
        'target_lang',
        'hanzi',
        'pinyin',
        'vi_meaning',
        'examples',
        'grammar_notes'
      ],
    };

    final result = await _generateJson(
      prompt: '$prompt\nInput: "$text"',
      schema: schema,
    );
    return result as Map<String, dynamic>;
  }

  /// Trích xuất chữ Hán từ hình ảnh (OCR)
  Future<String> extractTextFromImage(
      String base64Image, String mimeType) async {
    if (_apiKey.isEmpty) {
      throw Exception('Chưa cấu hình API Key cho Gemini.');
    }

    final requestBody = {
      'contents': [
        {
          'parts': [
            {
              'inlineData': {
                'mimeType': mimeType,
                'data': base64Image,
              }
            },
            {
              'text':
                  'Extract all text content from this image. Output only the extracted text as a single block. Do not add any formatting or commentary.'
            }
          ]
        }
      ]
    };

    final response = await _client.post(
      Uri.parse('$_endpoint?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = decoded['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('Không có kết quả OCR.');
      }
      final parts = candidates.first['content']?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw Exception('Nội dung phản hồi OCR trống.');
      }
      return parts.first['text'] as String? ?? '';
    } else {
      throw Exception('Lỗi API OCR: ${response.statusCode} ${response.body}');
    }
  }

  /// Lấy hoặc tạo đoạn hội thoại theo cấp độ HSK và chủ đề
  Future<List<dynamic>> fetchConversation(int level, String? topic) async {
    final topicPrompt = topic != null && topic.trim().isNotEmpty
        ? 'about the topic "$topic"'
        : 'on a common daily life subject';

    final prompt =
        'Generate a short conversation in Chinese $topicPrompt suitable for HSK level $level. '
        'It should have 6-8 turns between two speakers (A and B). '
        'Provide consistent topic, turn number, Chinese text (zh), Pinyin, and Vietnamese translation (vi).';

    final schema = {
      'type': 'ARRAY',
      'items': {
        'type': 'OBJECT',
        'properties': {
          'topic': {'type': 'STRING'},
          'turn': {'type': 'INTEGER'},
          'zh': {'type': 'STRING'},
          'pinyin': {'type': 'STRING'},
          'vi': {'type': 'STRING'},
        },
        'required': ['topic', 'turn', 'zh', 'pinyin', 'vi'],
      }
    };

    final result = await _generateJson(prompt: prompt, schema: schema);
    return _convertToList(result);
  }

  List<dynamic> _convertToList(dynamic result) {
    if (result is List) {
      return result;
    }
    if (result is Map) {
      if (result.containsKey('items')) {
        return result['items'] as List<dynamic>;
      }
      return result['contents'] ?? result['list'] ?? [result];
    }
    return [result];
  }

  /// Lấy thêm câu tiếp theo cho cuộc hội thoại
  Future<List<dynamic>> fetchMoreConversationLines(
    List<Map<String, dynamic>> existingLines,
    int level,
  ) async {
    if (existingLines.isEmpty) return [];
    final lastLine = existingLines.last;
    final topic = lastLine['topic'] ?? 'Chủ đề hội thoại';
    final turn = lastLine['turn'] ?? 0;

    final conversationHistory = existingLines.map((line) {
      final speaker = (line['turn'] as int? ?? 1) % 2 == 1 ? 'A' : 'B';
      return '$speaker: ${line['zh']}';
    }).join('\n');

    final prompt =
        'This is an existing conversation for an HSK level $level learner. The topic is "$topic".\n'
        'Here is the conversation so far:\n$conversationHistory\n\n'
        'Please generate the next 2 to 4 turns of this conversation, continuing the dialogue logically. '
        'Maintain the same HSK level and topic. For each new line, provide topic, turn (starting from ${turn + 1}), zh, pinyin, vi.';

    final schema = {
      'type': 'ARRAY',
      'items': {
        'type': 'OBJECT',
        'properties': {
          'topic': {'type': 'STRING'},
          'turn': {'type': 'INTEGER'},
          'zh': {'type': 'STRING'},
          'pinyin': {'type': 'STRING'},
          'vi': {'type': 'STRING'},
        },
        'required': ['topic', 'turn', 'zh', 'pinyin', 'vi'],
      }
    };

    final result = await _generateJson(prompt: prompt, schema: schema);
    return _convertToList(result);
  }

  /// Tạo danh sách bài học chủ đề cho cấp độ HSK
  Future<List<dynamic>> fetchLessonTopics(int level) async {
    final prompt =
        'Generate a list of 10-12 diverse and practical lesson topics for a student learning HSK level $level. '
        'For each topic, provide a short, engaging title in Vietnamese and a one-sentence description in Vietnamese.';

    final schema = {
      'type': 'ARRAY',
      'items': {
        'type': 'OBJECT',
        'properties': {
          'title': {'type': 'STRING'},
          'description': {'type': 'STRING'},
        },
        'required': ['title', 'description'],
      }
    };

    final result = await _generateJson(prompt: prompt, schema: schema);
    return _convertToList(result);
  }

  /// Tạo chi tiết bài học (Dialogue, Key Vocabulary, Grammar Points)
  Future<Map<String, dynamic>> fetchLessonDetail(
      int level, String topic) async {
    final prompt =
        'Create a detailed Chinese lesson for an HSK level $level student on the topic: "$topic". '
        'Must include:\n'
        '1. "dialogue": A short, practical dialogue between A and B with 4-6 turns. Each turn has speaker, zh, pinyin, vi.\n'
        '2. "key_vocabulary": 5-7 key vocabulary words. Each word has hanzi, pinyin, meaning_vi.\n'
        '3. "grammar_points": 2-3 grammar points. Each point has point, explanation_vi, examples (each example has zh, pinyin, vi).';

    final schema = {
      'type': 'OBJECT',
      'properties': {
        'level': {'type': 'NUMBER'},
        'title': {'type': 'STRING'},
        'dialogue': {
          'type': 'ARRAY',
          'items': {
            'type': 'OBJECT',
            'properties': {
              'speaker': {'type': 'STRING'},
              'zh': {'type': 'STRING'},
              'pinyin': {'type': 'STRING'},
              'vi': {'type': 'STRING'},
            },
            'required': ['speaker', 'zh', 'pinyin', 'vi'],
          }
        },
        'key_vocabulary': {
          'type': 'ARRAY',
          'items': {
            'type': 'OBJECT',
            'properties': {
              'hanzi': {'type': 'STRING'},
              'pinyin': {'type': 'STRING'},
              'meaning_vi': {'type': 'STRING'},
            },
            'required': ['hanzi', 'pinyin', 'meaning_vi'],
          }
        },
        'grammar_points': {
          'type': 'ARRAY',
          'items': {
            'type': 'OBJECT',
            'properties': {
              'point': {'type': 'STRING'},
              'explanation_vi': {'type': 'STRING'},
              'examples': {
                'type': 'ARRAY',
                'items': {
                  'type': 'OBJECT',
                  'properties': {
                    'zh': {'type': 'STRING'},
                    'pinyin': {'type': 'STRING'},
                    'vi': {'type': 'STRING'},
                  },
                  'required': ['zh', 'pinyin', 'vi'],
                }
              }
            },
            'required': ['point', 'explanation_vi', 'examples'],
          }
        }
      },
      'required': [
        'level',
        'title',
        'dialogue',
        'key_vocabulary',
        'grammar_points'
      ],
    };

    final result = await _generateJson(prompt: prompt, schema: schema);
    return result as Map<String, dynamic>;
  }

  /// Tạo đề thi thử HSK cho cấp độ
  Future<List<dynamic>> fetchHskExam(int level) async {
    final examStructure = {
      1: {
        'listening': 10,
        'reading': 10,
        'writing': 0,
        'total': 20
      }, // Adjusted to run faster and avoid timeout on mobile
      2: {'listening': 15, 'reading': 15, 'writing': 0, 'total': 30},
      3: {'listening': 15, 'reading': 15, 'writing': 5, 'total': 35},
      4: {'listening': 15, 'reading': 15, 'writing': 5, 'total': 35},
      5: {'listening': 15, 'reading': 15, 'writing': 5, 'total': 35},
      6: {'listening': 15, 'reading': 15, 'writing': 1, 'total': 31},
    };

    final structure = examStructure[level] ?? examStructure[1]!;
    final total = structure['total']!;
    final listening = structure['listening']!;
    final reading = structure['reading']!;
    final writing = structure['writing']!;

    String writingPrompt = '';
    if (writing > 0) {
      if (level == 6) {
        writingPrompt =
            '- Exactly 1 "Viết" (Writing) question (essay prompt). For this question, the "options" array should be empty, and "correct_answer" should be a sample essay.';
      } else {
        writingPrompt =
            '- Exactly $writing "Viết" (Writing) multiple-choice questions (e.g. reordering).';
      }
    } else {
      writingPrompt = '- Do NOT include a "Viết" (Writing) section.';
    }

    final prompt =
        'Generate a complete mock HSK $level exam with exactly $total questions. '
        'Structure:\n'
        '- Exactly $listening "Nghe hiểu" (Listening) questions.\n'
        '- Exactly $reading "Đọc hiểu" (Reading) questions.\n'
        '$writingPrompt\n\n'
        'For each question, return: section (Nghe hiểu, Đọc hiểu, or Viết), question_text, audio_script (only for listening, null otherwise), options (4 strings, empty for HSK 6 writing), correct_answer, explanation (in Vietnamese).';

    final schema = {
      'type': 'ARRAY',
      'items': {
        'type': 'OBJECT',
        'properties': {
          'section': {'type': 'STRING'},
          'question_text': {'type': 'STRING'},
          'audio_script': {'type': 'STRING'},
          'options': {
            'type': 'ARRAY',
            'items': {'type': 'STRING'}
          },
          'correct_answer': {'type': 'STRING'},
          'explanation': {'type': 'STRING'},
        },
        'required': [
          'section',
          'question_text',
          'options',
          'correct_answer',
          'explanation'
        ],
      }
    };

    final result = await _generateJson(prompt: prompt, schema: schema);
    return _convertToList(result);
  }

  /// Đánh giá kết quả làm bài thi HSK
  Future<Map<String, dynamic>> analyzeHskExamPerformance({
    required int level,
    required List<Map<String, dynamic>> questionsAndAnswers,
    required int score,
    required int totalQuestions,
  }) async {
    final prompt =
        'Act as an expert HSK teacher providing feedback to a student. '
        'The student completed HSK level $level mock exam. Score: $score/$totalQuestions.\n'
        'Here are their incorrect answers:\n'
        '${jsonEncode(questionsAndAnswers.where((q) => q['user_answer'] != q['correct_answer']).toList())}\n\n'
        'Provide a detailed feedback in Vietnamese. Fields required:\n'
        '1. overall_assessment: General assessment\n'
        '2. strengths: List of 2-3 strengths\n'
        '3. weaknesses: List of 2-3 weaknesses\n'
        '4. study_suggestions: List of 2-3 actionable study suggestions.';

    final schema = {
      'type': 'OBJECT',
      'properties': {
        'overall_assessment': {'type': 'STRING'},
        'strengths': {
          'type': 'ARRAY',
          'items': {'type': 'STRING'}
        },
        'weaknesses': {
          'type': 'ARRAY',
          'items': {'type': 'STRING'}
        },
        'study_suggestions': {
          'type': 'ARRAY',
          'items': {'type': 'STRING'}
        },
      },
      'required': [
        'overall_assessment',
        'strengths',
        'weaknesses',
        'study_suggestions'
      ],
    };

    final result = await _generateJson(prompt: prompt, schema: schema);
    return result as Map<String, dynamic>;
  }

  /// Tra cứu từ điển Việt ↔ Trung bằng Gemini
  Future<Map<String, dynamic>> fetchDictionaryEntry(String word) async {
    final prompt =
        'Provide a detailed dictionary entry for the word "$word". The word can be in either Vietnamese or Chinese. '
        'The entry should include the Hanzi, Pinyin, detailed Vietnamese meaning(s) including part of speech, '
        '2-3 example sentences (with pinyin and Vietnamese translation), and any relevant grammar notes or synonyms. '
        'Treat it as a dictionary lookup, not a full-sentence translation.';

    final schema = {
      'type': 'OBJECT',
      'properties': {
        'source_lang': {'type': 'STRING'},
        'target_lang': {'type': 'STRING'},
        'hanzi': {'type': 'STRING'},
        'pinyin': {'type': 'STRING'},
        'vi_meaning': {'type': 'STRING'},
        'examples': {
          'type': 'ARRAY',
          'items': {
            'type': 'OBJECT',
            'properties': {
              'zh': {'type': 'STRING'},
              'pinyin': {'type': 'STRING'},
              'vi': {'type': 'STRING'},
            },
            'required': ['zh', 'pinyin', 'vi'],
          }
        },
        'grammar_notes': {
          'type': 'ARRAY',
          'items': {'type': 'STRING'}
        }
      },
      'required': [
        'source_lang',
        'target_lang',
        'hanzi',
        'pinyin',
        'vi_meaning',
        'examples',
        'grammar_notes'
      ],
    };

    final result = await _generateJson(prompt: prompt, schema: schema);
    return result as Map<String, dynamic>;
  }

  /// Sinh ngẫu nhiên danh sách từ vựng HSK để phục vụ trắc nghiệm
  Future<List<dynamic>> fetchHskVocabulary(int level, {int count = 20}) async {
    final prompt =
        'Generate a list of $count HSK level $level vocabulary words. For each word, provide the level (number), '
        'hanzi, pinyin, meaning_vi, pos (part of speech, e.g. noun, verb), and a simple example sentence '
        'in Chinese (example_zh) with its pinyin (example_pinyin) and Vietnamese translation (example_vi).';

    final schema = {
      'type': 'ARRAY',
      'items': {
        'type': 'OBJECT',
        'properties': {
          'level': {'type': 'NUMBER'},
          'hanzi': {'type': 'STRING'},
          'pinyin': {'type': 'STRING'},
          'meaning_vi': {'type': 'STRING'},
          'pos': {'type': 'STRING'},
          'example_zh': {'type': 'STRING'},
          'example_pinyin': {'type': 'STRING'},
          'example_vi': {'type': 'STRING'},
        },
        'required': [
          'level',
          'hanzi',
          'pinyin',
          'meaning_vi',
          'pos',
          'example_zh',
          'example_pinyin',
          'example_vi'
        ],
      }
    };

    final result = await _generateJson(prompt: prompt, schema: schema);
    return _convertToList(result);
  }
}
