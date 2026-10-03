import 'dart:io';
import 'package:flutter/services.dart';

Future<void> copyBundledDb(String assetPath, String dbPath) async {
  final file = File(dbPath);
  if (!await file.exists() || await file.length() == 0) {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await file.writeAsBytes(bytes, flush: true);
  }
}
