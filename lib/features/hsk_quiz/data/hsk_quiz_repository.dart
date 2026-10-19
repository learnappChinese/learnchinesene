import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class HskQuizRepository {
  /// Loads official curriculum vocabulary for the requested HSK level.
  ///
  /// Each item in the returned list contains:
  /// - `id` / `word_id`: int
  /// - `hanzi` / `word`: String
  /// - `pinyin`: String
  /// - `meaning_vi`: String
  /// - `hsk_level`: int
  /// - `source`: String ('lexicon_db' or 'curriculum_seed')
  Future<List<Map<String, dynamic>>> loadHskVocabulary(int level);
}

class CloudHskQuizRepository implements HskQuizRepository {
  CloudHskQuizRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient? get _activeClient {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> loadHskVocabulary(int level) async {
    final client = _activeClient;
    if (client != null) {
      try {
        final rows = List<Map<String, dynamic>>.from(
          await client
              .from('lexicon_words')
              .select('id, word, pinyin, meaning_vi, tts_url, hsk_level_id')
              .eq('hsk_level_id', level)
              .order('id'),
        );

        if (rows.length >= 10) {
          return rows.map((r) {
            final wordText = (r['word'] ?? '').toString();
            final wordId = (r['id'] as num?)?.toInt() ?? 0;
            return <String, dynamic>{
              'id': wordId,
              'word_id': wordId,
              'source_word_id': wordId,
              'word': wordText,
              'hanzi': wordText,
              'pinyin': (r['pinyin'] ?? '').toString(),
              'meaning_vi': (r['meaning_vi'] ?? '').toString(),
              'hsk_level': level,
              'tts_url': r['tts_url'],
              'source': 'lexicon_db',
            };
          }).toList();
        }
      } catch (e) {
        debugPrint('CloudHskQuizRepository fetch warning: $e');
      }
    }

    // Curriculum Grounded Fallback Seed (offline / test / seed resilience)
    return HskSeedVocabulary.getWordsForLevel(level);
  }
}

/// Curated, official standard HSK vocabulary seed for offline resilience and tests.
class HskSeedVocabulary {
  static List<Map<String, dynamic>> getWordsForLevel(int level) {
    final list = _seedsByLevel[level] ?? _seedsByLevel[1]!;
    return list.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  static final Map<int, List<Map<String, dynamic>>> _seedsByLevel = {
    1: [
      {
        'id': 1001,
        'word_id': 1001,
        'source_word_id': 1001,
        'hanzi': '爱',
        'word': '爱',
        'pinyin': 'ài',
        'meaning_vi': 'yêu, thích',
        'hsk_level': 1,
        'source': 'curriculum_seed'
      },
      {
        'id': 1002,
        'word_id': 1002,
        'source_word_id': 1002,
        'hanzi': '八',
        'word': '八',
        'pinyin': 'bā',
        'meaning_vi': 'số tám',
        'hsk_level': 1,
        'source': 'curriculum_seed'
      },
      {
        'id': 1003,
        'word_id': 1003,
        'source_word_id': 1003,
        'hanzi': '爸爸',
        'word': '爸爸',
        'pinyin': 'bàba',
        'meaning_vi': 'bố, ba',
        'hsk_level': 1,
        'source': 'curriculum_seed'
      },
      {
        'id': 1004,
        'word_id': 1004,
        'source_word_id': 1004,
        'hanzi': '不',
        'word': '不',
        'pinyin': 'bù',
        'meaning_vi': 'không',
        'hsk_level': 1,
        'source': 'curriculum_seed'
      },
      {
        'id': 1005,
        'word_id': 1005,
        'source_word_id': 1005,
        'hanzi': '菜',
        'word': '菜',
        'pinyin': 'cài',
        'meaning_vi': 'món ăn, rau',
        'hsk_level': 1,
        'source': 'curriculum_seed'
      },
      {
        'id': 1006,
        'word_id': 1006,
        'source_word_id': 1006,
        'hanzi': '茶',
        'word': '茶',
        'pinyin': 'chá',
        'meaning_vi': 'trà',
        'hsk_level': 1,
        'source': 'curriculum_seed'
      },
      {
        'id': 1007,
        'word_id': 1007,
        'source_word_id': 1007,
        'hanzi': '吃',
        'word': '吃',
        'pinyin': 'chī',
        'meaning_vi': 'ăn',
        'hsk_level': 1,
        'source': 'curriculum_seed'
      },
      {
        'id': 1008,
        'word_id': 1008,
        'source_word_id': 1008,
        'hanzi': '大',
        'word': '大',
        'pinyin': 'dà',
        'meaning_vi': 'to, lớn',
        'hsk_level': 1,
        'source': 'curriculum_seed'
      },
      {
        'id': 1009,
        'word_id': 1009,
        'source_word_id': 1009,
        'hanzi': '的',
        'word': '的',
        'pinyin': 'de',
        'meaning_vi': 'của',
        'hsk_level': 1,
        'source': 'curriculum_seed'
      },
      {
        'id': 1010,
        'word_id': 1010,
        'source_word_id': 1010,
        'hanzi': '点',
        'word': '点',
        'pinyin': 'diǎn',
        'meaning_vi': 'giờ, một chút',
        'hsk_level': 1,
        'source': 'curriculum_seed'
      },
      {
        'id': 1011,
        'word_id': 1011,
        'source_word_id': 1011,
        'hanzi': '读',
        'word': '读',
        'pinyin': 'dú',
        'meaning_vi': 'đọc',
        'hsk_level': 1,
        'source': 'curriculum_seed'
      },
      {
        'id': 1012,
        'word_id': 1012,
        'source_word_id': 1012,
        'hanzi': '对不起',
        'word': '对不起',
        'pinyin': 'duìbuqǐ',
        'meaning_vi': 'xin lỗi',
        'hsk_level': 1,
        'source': 'curriculum_seed'
      },
      {
        'id': 1013,
        'word_id': 1013,
        'source_word_id': 1013,
        'hanzi': '多',
        'word': '多',
        'pinyin': 'duō',
        'meaning_vi': 'nhiều',
        'hsk_level': 1,
        'source': 'curriculum_seed'
      },
      {
        'id': 1014,
        'word_id': 1014,
        'source_word_id': 1014,
        'hanzi': '多少',
        'word': '多少',
        'pinyin': 'duōshao',
        'meaning_vi': 'bao nhiêu',
        'hsk_level': 1,
        'source': 'curriculum_seed'
      },
      {
        'id': 1015,
        'word_id': 1015,
        'source_word_id': 1015,
        'hanzi': '儿子',
        'word': '儿子',
        'pinyin': 'érzi',
        'meaning_vi': 'con trai',
        'hsk_level': 1,
        'source': 'curriculum_seed'
      },
      {
        'id': 1016,
        'word_id': 1016,
        'source_word_id': 1016,
        'hanzi': '工作',
        'word': '工作',
        'pinyin': 'gōngzuò',
        'meaning_vi': 'làm việc, công việc',
        'hsk_level': 1,
        'source': 'curriculum_seed'
      },
    ],
    2: [
      {
        'id': 2001,
        'word_id': 2001,
        'source_word_id': 2001,
        'hanzi': '吧',
        'word': '吧',
        'pinyin': 'ba',
        'meaning_vi': 'nhé, đi',
        'hsk_level': 2,
        'source': 'curriculum_seed'
      },
      {
        'id': 2002,
        'word_id': 2002,
        'source_word_id': 2002,
        'hanzi': '白',
        'word': '白',
        'pinyin': 'bái',
        'meaning_vi': 'trắng',
        'hsk_level': 2,
        'source': 'curriculum_seed'
      },
      {
        'id': 2003,
        'word_id': 2003,
        'source_word_id': 2003,
        'hanzi': '百',
        'word': '百',
        'pinyin': 'bǎi',
        'meaning_vi': 'trăm',
        'hsk_level': 2,
        'source': 'curriculum_seed'
      },
      {
        'id': 2004,
        'word_id': 2004,
        'source_word_id': 2004,
        'hanzi': '帮助',
        'word': '帮助',
        'pinyin': 'bāngzhù',
        'meaning_vi': 'giúp đỡ',
        'hsk_level': 2,
        'source': 'curriculum_seed'
      },
      {
        'id': 2005,
        'word_id': 2005,
        'source_word_id': 2005,
        'hanzi': '报纸',
        'word': '报纸',
        'pinyin': 'bàozhǐ',
        'meaning_vi': 'báo chí',
        'hsk_level': 2,
        'source': 'curriculum_seed'
      },
      {
        'id': 2006,
        'word_id': 2006,
        'source_word_id': 2006,
        'hanzi': '比',
        'word': '比',
        'pinyin': 'bǐ',
        'meaning_vi': 'so với',
        'hsk_level': 2,
        'source': 'curriculum_seed'
      },
      {
        'id': 2007,
        'word_id': 2007,
        'source_word_id': 2007,
        'hanzi': '别',
        'word': '别',
        'pinyin': 'bié',
        'meaning_vi': 'đừng',
        'hsk_level': 2,
        'source': 'curriculum_seed'
      },
      {
        'id': 2008,
        'word_id': 2008,
        'source_word_id': 2008,
        'hanzi': '长',
        'word': '长',
        'pinyin': 'cháng',
        'meaning_vi': 'dài',
        'hsk_level': 2,
        'source': 'curriculum_seed'
      },
      {
        'id': 2009,
        'word_id': 2009,
        'source_word_id': 2009,
        'hanzi': '唱歌',
        'word': '唱歌',
        'pinyin': 'chànggē',
        'meaning_vi': 'ca hát',
        'hsk_level': 2,
        'source': 'curriculum_seed'
      },
      {
        'id': 2010,
        'word_id': 2010,
        'source_word_id': 2010,
        'hanzi': '出',
        'word': '出',
        'pinyin': 'chū',
        'meaning_vi': 'ra ngoài, xuất hiện',
        'hsk_level': 2,
        'source': 'curriculum_seed'
      },
      {
        'id': 2011,
        'word_id': 2011,
        'source_word_id': 2011,
        'hanzi': '穿',
        'word': '穿',
        'pinyin': 'chuān',
        'meaning_vi': 'mặc, xỏ',
        'hsk_level': 2,
        'source': 'curriculum_seed'
      },
      {
        'id': 2012,
        'word_id': 2012,
        'source_word_id': 2012,
        'hanzi': '次',
        'word': '次',
        'pinyin': 'cì',
        'meaning_vi': 'lần, lượt',
        'hsk_level': 2,
        'source': 'curriculum_seed'
      },
      {
        'id': 2013,
        'word_id': 2013,
        'source_word_id': 2013,
        'hanzi': '从',
        'word': '从',
        'pinyin': 'cóng',
        'meaning_vi': 'từ',
        'hsk_level': 2,
        'source': 'curriculum_seed'
      },
      {
        'id': 2014,
        'word_id': 2014,
        'source_word_id': 2014,
        'hanzi': '错',
        'word': '错',
        'pinyin': 'cuò',
        'meaning_vi': 'sai',
        'hsk_level': 2,
        'source': 'curriculum_seed'
      },
      {
        'id': 2015,
        'word_id': 2015,
        'source_word_id': 2015,
        'hanzi': '大家',
        'word': '大家',
        'pinyin': 'dàjiā',
        'meaning_vi': 'mọi người',
        'hsk_level': 2,
        'source': 'curriculum_seed'
      },
      {
        'id': 2016,
        'word_id': 2016,
        'source_word_id': 2016,
        'hanzi': '等待',
        'word': '等待',
        'pinyin': 'děngdài',
        'meaning_vi': 'chờ đợi',
        'hsk_level': 2,
        'source': 'curriculum_seed'
      },
    ],
    3: [
      {
        'id': 3001,
        'word_id': 3001,
        'source_word_id': 3001,
        'hanzi': '阿姨',
        'word': '阿姨',
        'pinyin': 'āyí',
        'meaning_vi': 'cô, dì',
        'hsk_level': 3,
        'source': 'curriculum_seed'
      },
      {
        'id': 3002,
        'word_id': 3002,
        'source_word_id': 3002,
        'hanzi': '矮',
        'word': '矮',
        'pinyin': 'ǎi',
        'meaning_vi': 'thấp, lùn',
        'hsk_level': 3,
        'source': 'curriculum_seed'
      },
      {
        'id': 3003,
        'word_id': 3003,
        'source_word_id': 3003,
        'hanzi': '爱好',
        'word': '爱好',
        'pinyin': 'àihào',
        'meaning_vi': 'sở thích',
        'hsk_level': 3,
        'source': 'curriculum_seed'
      },
      {
        'id': 3004,
        'word_id': 3004,
        'source_word_id': 3004,
        'hanzi': '安静',
        'word': '安静',
        'pinyin': 'ānjìng',
        'meaning_vi': 'yên tĩnh',
        'hsk_level': 3,
        'source': 'curriculum_seed'
      },
      {
        'id': 3005,
        'word_id': 3005,
        'source_word_id': 3005,
        'hanzi': '把',
        'word': '把',
        'pinyin': 'bǎ',
        'meaning_vi': 'cầm, nắm, chữ 把',
        'hsk_level': 3,
        'source': 'curriculum_seed'
      },
      {
        'id': 3006,
        'word_id': 3006,
        'source_word_id': 3006,
        'hanzi': '班',
        'word': '班',
        'pinyin': 'bān',
        'meaning_vi': 'lớp học, ca làm',
        'hsk_level': 3,
        'source': 'curriculum_seed'
      },
      {
        'id': 3007,
        'word_id': 3007,
        'source_word_id': 3007,
        'hanzi': '搬',
        'word': '搬',
        'pinyin': 'bān',
        'meaning_vi': 'chuyển dọn',
        'hsk_level': 3,
        'source': 'curriculum_seed'
      },
      {
        'id': 3008,
        'word_id': 3008,
        'source_word_id': 3008,
        'hanzi': '办法',
        'word': '办法',
        'pinyin': 'bànfǎ',
        'meaning_vi': 'biện pháp, cách làm',
        'hsk_level': 3,
        'source': 'curriculum_seed'
      },
      {
        'id': 3009,
        'word_id': 3009,
        'source_word_id': 3009,
        'hanzi': '办公室',
        'word': '办公室',
        'pinyin': 'bàngōngshì',
        'meaning_vi': 'văn phòng',
        'hsk_level': 3,
        'source': 'curriculum_seed'
      },
      {
        'id': 3010,
        'word_id': 3010,
        'source_word_id': 3010,
        'hanzi': '半',
        'word': '半',
        'pinyin': 'bàn',
        'meaning_vi': 'nửa, rưỡi',
        'hsk_level': 3,
        'source': 'curriculum_seed'
      },
      {
        'id': 3011,
        'word_id': 3011,
        'source_word_id': 3011,
        'hanzi': '包',
        'word': '包',
        'pinyin': 'bāo',
        'meaning_vi': 'túi, gói',
        'hsk_level': 3,
        'source': 'curriculum_seed'
      },
      {
        'id': 3012,
        'word_id': 3012,
        'source_word_id': 3012,
        'hanzi': '饱',
        'word': '饱',
        'pinyin': 'bǎo',
        'meaning_vi': 'no',
        'hsk_level': 3,
        'source': 'curriculum_seed'
      },
      {
        'id': 3013,
        'word_id': 3013,
        'source_word_id': 3013,
        'hanzi': '北方',
        'word': '北方',
        'pinyin': 'běifāng',
        'meaning_vi': 'phương bắc',
        'hsk_level': 3,
        'source': 'curriculum_seed'
      },
      {
        'id': 3014,
        'word_id': 3014,
        'source_word_id': 3014,
        'hanzi': '被',
        'word': '被',
        'pinyin': 'bèi',
        'meaning_vi': 'bị, được',
        'hsk_level': 3,
        'source': 'curriculum_seed'
      },
      {
        'id': 3015,
        'word_id': 3015,
        'source_word_id': 3015,
        'hanzi': '比较',
        'word': '比较',
        'pinyin': 'bǐjiào',
        'meaning_vi': 'tương đối, so sánh',
        'hsk_level': 3,
        'source': 'curriculum_seed'
      },
      {
        'id': 3016,
        'word_id': 3016,
        'source_word_id': 3016,
        'hanzi': '比赛',
        'word': '比赛',
        'pinyin': 'bǐsài',
        'meaning_vi': 'thi đấu, trận đấu',
        'hsk_level': 3,
        'source': 'curriculum_seed'
      },
    ],
    4: [
      {
        'id': 4001,
        'word_id': 4001,
        'source_word_id': 4001,
        'hanzi': '爱情',
        'word': '爱情',
        'pinyin': 'àiqíng',
        'meaning_vi': 'tình yêu',
        'hsk_level': 4,
        'source': 'curriculum_seed'
      },
      {
        'id': 4002,
        'word_id': 4002,
        'source_word_id': 4002,
        'hanzi': '安排',
        'word': '安排',
        'pinyin': 'ānpái',
        'meaning_vi': 'sắp xếp, thu xếp',
        'hsk_level': 4,
        'source': 'curriculum_seed'
      },
      {
        'id': 4003,
        'word_id': 4003,
        'source_word_id': 4003,
        'hanzi': '安全',
        'word': '安全',
        'pinyin': 'ānquán',
        'meaning_vi': 'an toàn',
        'hsk_level': 4,
        'source': 'curriculum_seed'
      },
      {
        'id': 4004,
        'word_id': 4004,
        'source_word_id': 4004,
        'hanzi': '按时',
        'word': '按时',
        'pinyin': 'ànshí',
        'meaning_vi': 'đúng giờ',
        'hsk_level': 4,
        'source': 'curriculum_seed'
      },
      {
        'id': 4005,
        'word_id': 4005,
        'source_word_id': 4005,
        'hanzi': '保护',
        'word': '保护',
        'pinyin': 'bǎohù',
        'meaning_vi': 'bảo vệ',
        'hsk_level': 4,
        'source': 'curriculum_seed'
      },
      {
        'id': 4006,
        'word_id': 4006,
        'source_word_id': 4006,
        'hanzi': '保证',
        'word': '保证',
        'pinyin': 'bǎozhèng',
        'meaning_vi': 'bảo đảm, cam đoan',
        'hsk_level': 4,
        'source': 'curriculum_seed'
      },
      {
        'id': 4007,
        'word_id': 4007,
        'source_word_id': 4007,
        'hanzi': '抱歉',
        'word': '抱歉',
        'pinyin': 'bàoqiàn',
        'meaning_vi': 'xin lỗi, áy náy',
        'hsk_level': 4,
        'source': 'curriculum_seed'
      },
      {
        'id': 4008,
        'word_id': 4008,
        'source_word_id': 4008,
        'hanzi': '报名',
        'word': '报名',
        'pinyin': 'bàomíng',
        'meaning_vi': 'ghi danh, báo danh',
        'hsk_level': 4,
        'source': 'curriculum_seed'
      },
      {
        'id': 4009,
        'word_id': 4009,
        'source_word_id': 4009,
        'hanzi': '表格',
        'word': '表格',
        'pinyin': 'biǎogé',
        'meaning_vi': 'biểu mẫu, bảng biểu',
        'hsk_level': 4,
        'source': 'curriculum_seed'
      },
      {
        'id': 4010,
        'word_id': 4010,
        'source_word_id': 4010,
        'hanzi': '表演',
        'word': '表演',
        'pinyin': 'biǎoyǎn',
        'meaning_vi': 'biểu diễn',
        'hsk_level': 4,
        'source': 'curriculum_seed'
      },
      {
        'id': 4011,
        'word_id': 4011,
        'source_word_id': 4011,
        'hanzi': '毕业',
        'word': '毕业',
        'pinyin': 'bìyè',
        'meaning_vi': 'tốt nghiệp',
        'hsk_level': 4,
        'source': 'curriculum_seed'
      },
      {
        'id': 4012,
        'word_id': 4012,
        'source_word_id': 4012,
        'hanzi': '标准',
        'word': '标准',
        'pinyin': 'biāozhǔn',
        'meaning_vi': 'tiêu chuẩn',
        'hsk_level': 4,
        'source': 'curriculum_seed'
      },
      {
        'id': 4013,
        'word_id': 4013,
        'source_word_id': 4013,
        'hanzi': '表达',
        'word': '表达',
        'pinyin': 'biǎodá',
        'meaning_vi': 'bày tỏ, biểu đạt',
        'hsk_level': 4,
        'source': 'curriculum_seed'
      },
      {
        'id': 4014,
        'word_id': 4014,
        'source_word_id': 4014,
        'hanzi': '差不多',
        'word': '差不多',
        'pinyin': 'chàbuduō',
        'meaning_vi': 'gần như, suýt soát',
        'hsk_level': 4,
        'source': 'curriculum_seed'
      },
      {
        'id': 4015,
        'word_id': 4015,
        'source_word_id': 4015,
        'hanzi': '成功',
        'word': '成功',
        'pinyin': 'chénggōng',
        'meaning_vi': 'thành công',
        'hsk_level': 4,
        'source': 'curriculum_seed'
      },
      {
        'id': 4016,
        'word_id': 4016,
        'source_word_id': 4016,
        'hanzi': '诚实',
        'word': '诚实',
        'pinyin': 'chéngshí',
        'meaning_vi': 'thành thật',
        'hsk_level': 4,
        'source': 'curriculum_seed'
      },
    ],
    5: [
      {
        'id': 5001,
        'word_id': 5001,
        'source_word_id': 5001,
        'hanzi': '把握',
        'word': '把握',
        'pinyin': 'bǎwò',
        'meaning_vi': 'nắm chắc, nắm bắt',
        'hsk_level': 5,
        'source': 'curriculum_seed'
      },
      {
        'id': 5002,
        'word_id': 5002,
        'source_word_id': 5002,
        'hanzi': '办理',
        'word': '办理',
        'pinyin': 'bànlǐ',
        'meaning_vi': 'xử lý, làm thủ tục',
        'hsk_level': 5,
        'source': 'curriculum_seed'
      },
      {
        'id': 5003,
        'word_id': 5003,
        'source_word_id': 5003,
        'hanzi': '包含',
        'word': '包含',
        'pinyin': 'bāohán',
        'meaning_vi': 'chứa đựng, bao hàm',
        'hsk_level': 5,
        'source': 'curriculum_seed'
      },
      {
        'id': 5004,
        'word_id': 5004,
        'source_word_id': 5004,
        'hanzi': '保护',
        'word': '保护',
        'pinyin': 'bǎohù',
        'meaning_vi': 'bảo hộ, bảo vệ',
        'hsk_level': 5,
        'source': 'curriculum_seed'
      },
      {
        'id': 5005,
        'word_id': 5005,
        'source_word_id': 5005,
        'hanzi': '保留',
        'word': '保留',
        'pinyin': 'bǎoliú',
        'meaning_vi': 'giữ lại, bảo lưu',
        'hsk_level': 5,
        'source': 'curriculum_seed'
      },
      {
        'id': 5006,
        'word_id': 5006,
        'source_word_id': 5006,
        'hanzi': '报道',
        'word': '报道',
        'pinyin': 'bàodào',
        'meaning_vi': 'bản tin, đưa tin',
        'hsk_level': 5,
        'source': 'curriculum_seed'
      },
      {
        'id': 5007,
        'word_id': 5007,
        'source_word_id': 5007,
        'hanzi': '本质',
        'word': '本质',
        'pinyin': 'běnzhì',
        'meaning_vi': 'bản chất',
        'hsk_level': 5,
        'source': 'curriculum_seed'
      },
      {
        'id': 5008,
        'word_id': 5008,
        'source_word_id': 5008,
        'hanzi': '比例',
        'word': '比例',
        'pinyin': 'bǐlì',
        'meaning_vi': 'tỷ lệ',
        'hsk_level': 5,
        'source': 'curriculum_seed'
      },
      {
        'id': 5009,
        'word_id': 5009,
        'source_word_id': 5009,
        'hanzi': '必然',
        'word': '必然',
        'pinyin': 'bìrán',
        'meaning_vi': 'tất nhiên, chắc chắn',
        'hsk_level': 5,
        'source': 'curriculum_seed'
      },
      {
        'id': 5010,
        'word_id': 5010,
        'source_word_id': 5010,
        'hanzi': '毕业',
        'word': '毕业',
        'pinyin': 'bìyè',
        'meaning_vi': 'tốt nghiệp khóa học',
        'hsk_level': 5,
        'source': 'curriculum_seed'
      },
      {
        'id': 5011,
        'word_id': 5011,
        'source_word_id': 5011,
        'hanzi': '辩论',
        'word': '辩论',
        'pinyin': 'biànlùn',
        'meaning_vi': 'biện luận, tranh luận',
        'hsk_level': 5,
        'source': 'curriculum_seed'
      },
      {
        'id': 5012,
        'word_id': 5012,
        'source_word_id': 5012,
        'hanzi': '标志',
        'word': '标志',
        'pinyin': 'biāozhì',
        'meaning_vi': 'cột mốc, biểu tượng',
        'hsk_level': 5,
        'source': 'curriculum_seed'
      },
      {
        'id': 5013,
        'word_id': 5013,
        'source_word_id': 5013,
        'hanzi': '表达',
        'word': '表达',
        'pinyin': 'biǎodá',
        'meaning_vi': 'biểu đạt, diễn tả',
        'hsk_level': 5,
        'source': 'curriculum_seed'
      },
      {
        'id': 5014,
        'word_id': 5014,
        'source_word_id': 5014,
        'hanzi': '冰激凌',
        'word': '冰激凌',
        'pinyin': 'bīngjīlíng',
        'meaning_vi': 'kem lạnh',
        'hsk_level': 5,
        'source': 'curriculum_seed'
      },
      {
        'id': 5015,
        'word_id': 5015,
        'source_word_id': 5015,
        'hanzi': '补充',
        'word': '补充',
        'pinyin': 'bǔchōng',
        'meaning_vi': 'bổ sung',
        'hsk_level': 5,
        'source': 'curriculum_seed'
      },
      {
        'id': 5016,
        'word_id': 5016,
        'source_word_id': 5016,
        'hanzi': '不免',
        'word': '不免',
        'pinyin': 'bùmiǎn',
        'meaning_vi': 'không tránh khỏi',
        'hsk_level': 5,
        'source': 'curriculum_seed'
      },
    ],
    6: [
      {
        'id': 6001,
        'word_id': 6001,
        'source_word_id': 6001,
        'hanzi': '暧昧',
        'word': '暧昧',
        'pinyin': 'àimèi',
        'meaning_vi': 'mập mờ, ám muội',
        'hsk_level': 6,
        'source': 'curriculum_seed'
      },
      {
        'id': 6002,
        'word_id': 6002,
        'source_word_id': 6002,
        'hanzi': '安置',
        'word': '安置',
        'pinyin': 'ānzhì',
        'meaning_vi': 'bố trí, an trí',
        'hsk_level': 6,
        'source': 'curriculum_seed'
      },
      {
        'id': 6003,
        'word_id': 6003,
        'source_word_id': 6003,
        'hanzi': '按揭',
        'word': '按揭',
        'pinyin': 'ànjiē',
        'meaning_vi': 'vay trả góp thế chấp',
        'hsk_level': 6,
        'source': 'curriculum_seed'
      },
      {
        'id': 6004,
        'word_id': 6004,
        'source_word_id': 6004,
        'hanzi': '昂贵',
        'word': '昂贵',
        'pinyin': 'ángguì',
        'meaning_vi': 'đắt đỏ, đắt giá',
        'hsk_level': 6,
        'source': 'curriculum_seed'
      },
      {
        'id': 6005,
        'word_id': 6005,
        'source_word_id': 6005,
        'hanzi': '凹凸',
        'word': '凹凸',
        'pinyin': 'āotū',
        'meaning_vi': 'lồi lõm, mấp mô',
        'hsk_level': 6,
        'source': 'curriculum_seed'
      },
      {
        'id': 6006,
        'word_id': 6006,
        'source_word_id': 6006,
        'hanzi': '熬',
        'word': '熬',
        'pinyin': 'áo',
        'meaning_vi': 'ninh, nấu nhừ, chịu đựng',
        'hsk_level': 6,
        'source': 'curriculum_seed'
      },
      {
        'id': 6007,
        'word_id': 6007,
        'source_word_id': 6007,
        'hanzi': '奥秘',
        'word': '奥秘',
        'pinyin': 'àomì',
        'meaning_vi': 'huyền bí, bí mật',
        'hsk_level': 6,
        'source': 'curriculum_seed'
      },
      {
        'id': 6008,
        'word_id': 6008,
        'source_word_id': 6008,
        'hanzi': '扒',
        'word': '扒',
        'pinyin': 'bā',
        'meaning_vi': 'vịn, bấu, bới',
        'hsk_level': 6,
        'source': 'curriculum_seed'
      },
      {
        'id': 6009,
        'word_id': 6009,
        'source_word_id': 6009,
        'hanzi': '疤',
        'word': '疤',
        'pinyin': 'bā',
        'meaning_vi': 'vết sẹo',
        'hsk_level': 6,
        'source': 'curriculum_seed'
      },
      {
        'id': 6010,
        'word_id': 6010,
        'source_word_id': 6010,
        'hanzi': '拔苗助长',
        'word': '拔苗助长',
        'pinyin': 'bámiáozhùzhǎng',
        'meaning_vi': 'dục tốc bất đạt, đốt cháy giai đoạn',
        'hsk_level': 6,
        'source': 'curriculum_seed'
      },
      {
        'id': 6011,
        'word_id': 6011,
        'source_word_id': 6011,
        'hanzi': '把关',
        'word': '把关',
        'pinyin': 'bǎguān',
        'meaning_vi': 'giữ cửa, kiểm tra gắt gao',
        'hsk_level': 6,
        'source': 'curriculum_seed'
      },
      {
        'id': 6012,
        'word_id': 6012,
        'source_word_id': 6012,
        'hanzi': '把柄',
        'word': '把柄',
        'pinyin': 'bǎbǐng',
        'meaning_vi': 'cán cân, điểm yếu bị nắm bắt',
        'hsk_level': 6,
        'source': 'curriculum_seed'
      },
      {
        'id': 6013,
        'word_id': 6013,
        'source_word_id': 6013,
        'hanzi': '罢工',
        'word': '罢工',
        'pinyin': 'bàgōng',
        'meaning_vi': 'đình công',
        'hsk_level': 6,
        'source': 'curriculum_seed'
      },
      {
        'id': 6014,
        'word_id': 6014,
        'source_word_id': 6014,
        'hanzi': '霸道',
        'word': '霸道',
        'pinyin': 'bàdào',
        'meaning_vi': 'bá đạo, ngang ngược',
        'hsk_level': 6,
        'source': 'curriculum_seed'
      },
      {
        'id': 6015,
        'word_id': 6015,
        'source_word_id': 6015,
        'hanzi': '掰',
        'word': '掰',
        'pinyin': 'bāi',
        'meaning_vi': 'dùng tay bẻ, tách',
        'hsk_level': 6,
        'source': 'curriculum_seed'
      },
      {
        'id': 6016,
        'word_id': 6016,
        'source_word_id': 6016,
        'hanzi': '白皮书',
        'word': '白皮书',
        'pinyin': 'báipíshū',
        'meaning_vi': 'sách trắng (tài liệu chính thức)',
        'hsk_level': 6,
        'source': 'curriculum_seed'
      },
    ],
  };
}
