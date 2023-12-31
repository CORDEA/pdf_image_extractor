import 'dart:typed_data';

import 'package:pdf_image_extractor/src/pdf_parser.dart';
import 'package:pdf_image_extractor/src/raw_pdf_image.dart';

class PdfImageSerializer {
  PdfImageSerializer(this._parser);

  final PdfTagParser _parser;

  bool canDeserialize(List<String> value) {
    final index = value.indexOf('/Subtype');
    if (index < 0 || value.length <= index + 1) {
      return false;
    }
    return value[index + 1] == '/Image';
  }

  RawPdfImage deserialize(
    RawPdfImageId id,
    PdfObject value,
    Map<RawPdfImageId, PdfObject> map,
  ) {
    late int width;
    late int height;
    late RawPdfImageColorSpace colorSpace;
    late int bitsPerComponent;
    late int length;
    RawPdfImageFilterType? filter;
    RawPdfImageId? sMask;
    final parsed = _parser.parse(value.lines);
    if (parsed is! PdfTagDictionary) {
      throw UnimplementedError();
    }
    parsed.value.forEach((key, tag) {
      if (tag is PdfTagList) {
        final value = tag.value;
        switch (key) {
          case '/Width':
            width = _extractNumber(value.first);
          case '/Height':
            height = _extractNumber(value.first);
          case '/ColorSpace':
            if (value.length == 3 && value.last == 'R') {
              final id = RawPdfImageId(
                objectNumber: _extractNumber(value[0]),
                generationNumber: _extractNumber(value[1]),
              );
              final ref = _parser.parse(map[id]!.lines);
              if (ref is PdfTagList && ref.value.first == '/ICCBased') {
                final profile = RawPdfImageId(
                  objectNumber: _extractNumber(ref.value[1]),
                  generationNumber: _extractNumber(ref.value[2]),
                );
                final tag = _parser.parse(map[profile]!.lines);
                if (tag is PdfTagDictionary) {
                  colorSpace = RawPdfImageColorSpaceIccBased(
                    _extractNumber(
                      (tag.value['/N'] as PdfTagList).value[0],
                    ),
                    PdfImageColorModel.from(
                      (tag.value['/Alternate'] as PdfTagList).value[0],
                    ),
                  );
                }
              }
            } else {
              colorSpace =
                  RawPdfImageColorModel(PdfImageColorModel.from(value.first));
            }
          case '/SMask':
            if (value.length == 3 && value.last == 'R') {
              sMask = RawPdfImageId(
                objectNumber: _extractNumber(value[0]),
                generationNumber: _extractNumber(value[1]),
              );
            }
          case '/BitsPerComponent':
            bitsPerComponent = _extractNumber(value.first);
          case '/Filter':
            filter = RawPdfImageFilterType.from(value.first);
          case '/Length':
            length = _extractNumber(value.first);
        }
      }
    });
    final stream = value.stream!;
    assert(length == stream.length);
    return RawPdfImage(
      id: id,
      width: width,
      height: height,
      bitsPerComponent: bitsPerComponent,
      colorSpace: colorSpace,
      filter: filter,
      length: length,
      sMask: sMask,
      bytes: Uint8List.fromList(stream.codeUnits),
    );
  }

  int _extractNumber(String value) => int.parse(
        String.fromCharCodes(
          value.codeUnits.takeWhile((value) => 0x30 <= value && value <= 0x39),
        ),
      );
}
