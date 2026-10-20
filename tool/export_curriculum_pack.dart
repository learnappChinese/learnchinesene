import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const supabaseUrl = 'https://hrlahralknhijnkypjix.supabase.co';
  const apikey = 'sb_publishable_9n5qfIMFqZELqlmJFUrg-A_7IJJebRy';

  final headers = {
    'apikey': apikey,
    'Authorization': 'Bearer $apikey',
  };

  print('1. Tải lexicon_hsk_levels...');
  final resLevels = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/lexicon_hsk_levels?select=*&order=id'),
    headers: headers,
  );
  final levels = jsonDecode(resLevels.body) as List;

  print('2. Tải lexicon_units...');
  final resUnits = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/lexicon_units?select=*&order=id'),
    headers: headers,
  );
  final units = jsonDecode(resUnits.body) as List;

  print('3. Tải lexicon_words...');
  final words = <dynamic>[];
  for (var offset = 0; offset < 5000; offset += 1000) {
    final res = await http.get(
      Uri.parse(
        '$supabaseUrl/rest/v1/lexicon_words?select=*&order=id&offset=$offset&limit=1000',
      ),
      headers: headers,
    );
    final list = jsonDecode(res.body) as List;
    if (list.isEmpty) break;
    words.addAll(list);
  }

  print('4. Tải lexicon_word_sources...');
  final sources = <dynamic>[];
  for (var offset = 0; offset < 6000; offset += 1000) {
    final res = await http.get(
      Uri.parse(
        '$supabaseUrl/rest/v1/lexicon_word_sources?select=*&order=id&offset=$offset&limit=1000',
      ),
      headers: headers,
    );
    final list = jsonDecode(res.body) as List;
    if (list.isEmpty) break;
    sources.addAll(list);
  }

  print('5. Tải lexicon_characters...');
  final resChars = await http.get(
    Uri.parse(
      '$supabaseUrl/rest/v1/lexicon_characters?select=*&order=id&limit=1000',
    ),
    headers: headers,
  );
  final characters = jsonDecode(resChars.body) as List;

  final pack = {
    'pack_id': 'hsk_curriculum_pack_v1',
    'version': 1,
    'content_schema_version': 1,
    'hsk_levels': levels,
    'units': units,
    'words': words,
    'word_sources': sources,
    'characters': characters,
  };

  final outFile = File('assets/data/hsk_curriculum_pack_v1.json');
  await outFile.parent.create(recursive: true);
  await outFile.writeAsString(jsonEncode(pack));

  print('Hoàn tất xuất dữ liệu:');
  print('- HSK Levels: ${levels.length}');
  print('- Units: ${units.length}');
  print('- Words: ${words.length}');
  print('- Word Sources: ${sources.length}');
  print('- Characters: ${characters.length}');
  print('- File size: ${(outFile.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB');
}
