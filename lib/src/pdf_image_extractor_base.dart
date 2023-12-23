import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';

class PdfImageExtractor {
  PdfImageExtractor(this.file);

  final File file;
  late Uint8List _bytes;

  Future<List<dynamic>> extract() async {
    _bytes = await file.readAsBytes();
    if (_isPdf()) {
      return [];
    }
    return [];
  }

  bool _isPdf() =>
      IterableEquality().equals(_bytes.take(4), [0x25, 0x55, 0x44, 0x46]);
}
