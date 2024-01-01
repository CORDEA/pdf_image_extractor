import 'dart:io';

import 'package:collection/collection.dart';
import 'package:image/image.dart';
import 'package:pdf_image_extractor/pdf_image_extractor.dart';

Future<void> main(List<String> arguments) async {
  final file = File(arguments.first);
  final rawImages = await PdfImageExtractor(file).extract();
  final images = PdfImageProcessor(rawImages).write();
  final date = DateTime.now();
  images.forEachIndexed((i, e) async {
    await encodePngFile('${date.millisecondsSinceEpoch}_$i.png', e);
  });
}
