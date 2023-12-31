import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:pdf_image_extractor/src/pdf_parser.dart';
import 'package:pdf_image_extractor/src/raw_pdf_image.dart';

class PdfImageExtractor {
  PdfImageExtractor(this.file);

  final File file;
  final _serializer = Serializer(PdfTagParser());
  late Uint8List _bytes;

  Future<List<RawPdfImage>> extract() async {
    _bytes = await file.readAsBytes();
    if (_isPdf()) {
      return [];
    }
    final objects = PdfObjectParser().parse(_bytes);
    return objects.entries
        .where((e) => _serializer.canDeserialize(e.value.lines))
        .map((e) => _serializer.deserialize(e.key, e.value, objects))
        .toList(growable: false);
  }

  bool _isPdf() =>
      IterableEquality().equals(_bytes.take(4), [0x25, 0x55, 0x44, 0x46]);
}
