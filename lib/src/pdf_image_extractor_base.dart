import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:pdf_image_extractor/src/raw_pdf_image.dart';

class PdfImageExtractor {
  PdfImageExtractor(this.file);

  final File file;
  final _serializer = Serializer();
  late Uint8List _bytes;

  Future<List<RawPdfImage>> extract() async {
    _bytes = await file.readAsBytes();
    if (_isPdf()) {
      return [];
    }
    final lines = _bytes
        .splitAfter((e) => e == 0x0a || e == 0x0d)
        .map((e) => String.fromCharCodes(e))
        .toList(growable: false);
    final Map<RawPdfImageId, List<String>> objects = {};
    RawPdfImageId? currentId;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.endsWith('obj')) {
        if (line.startsWith('end')) {
          currentId = null;
        } else {
          final args = line.split(' ');
          currentId = RawPdfImageId(
            objectNumber: int.parse(args[0]),
            generationNumber: int.parse(args[1]),
          );
        }
        continue;
      }
      if (currentId == null) {
        continue;
      }
      objects.putIfAbsent(currentId, () => []).add(line);
    }

    objects.removeWhere((_, value) => !_serializer.canDeserialize(value));
    return objects
        .map((key, value) => MapEntry(key, _serializer.deserialize(key, value)))
        .values
        .toList(growable: false);
  }

  bool _isPdf() =>
      IterableEquality().equals(_bytes.take(4), [0x25, 0x55, 0x44, 0x46]);
}
