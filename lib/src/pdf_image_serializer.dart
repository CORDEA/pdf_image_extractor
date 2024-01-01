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
    final parsed = _parser.parse(value.lines);
    if (parsed is! PdfTagDictionary) {
      throw UnimplementedError();
    }
    final width = _extractNumber(_getList(parsed, '/Width').first);
    final height = _extractNumber(_getList(parsed, '/Height').first);
    final rawColorSpace = _getList(parsed, '/ColorSpace');
    final RawPdfImageColorSpace colorSpace;
    if (rawColorSpace.length == 3 && rawColorSpace.last == 'R') {
      final id = RawPdfImageId(
        objectNumber: _extractNumber(rawColorSpace[0]),
        generationNumber: _extractNumber(rawColorSpace[1]),
      );
      final ref = _parser.parse(map[id]!.lines);
      if (ref is PdfTagList) {
        switch (ref.value.first) {
          case '/Indexed':
            final hival = _extractNumber(ref.value[2]);
            final lookup = map[RawPdfImageId(
              objectNumber: _extractNumber(ref.value[3]),
              generationNumber: _extractNumber(ref.value[4]),
            )]!;
            colorSpace = RawPdfImageColorSpaceIndexed(
              hival,
              PdfImageColorModel.from(ref.value[1]),
              lookup.stream!.codeUnits,
            );
          case '/ICCBased':
            final profile = RawPdfImageId(
              objectNumber: _extractNumber(ref.value[1]),
              generationNumber: _extractNumber(ref.value[2]),
            );
            final tag = _parser.parse(map[profile]!.lines);
            colorSpace = RawPdfImageColorSpaceIccBased(
              _extractNumber(_getList(tag, '/N').first),
              PdfImageColorModel.from(_getList(tag, '/Alternate').first),
            );
          default:
            throw UnimplementedError();
        }
      } else {
        throw UnimplementedError();
      }
    } else {
      colorSpace =
          RawPdfImageColorModel(PdfImageColorModel.from(rawColorSpace.first));
    }
    final rawMask = _getList(parsed, '/SMask');
    final RawPdfImageId? sMask;
    if (rawMask.length == 3 && rawMask.last == 'R') {
      sMask = RawPdfImageId(
        objectNumber: _extractNumber(rawMask[0]),
        generationNumber: _extractNumber(rawMask[1]),
      );
    } else {
      sMask = null;
    }
    final bitsPerComponent =
        _extractNumber(_getList(parsed, '/BitsPerComponent').first);
    final filter = _getList(parsed, '/Filter')
        .map((e) => PdfImageFilterType.from(e))
        .toList(growable: false);
    final length = _extractNumber(_getList(parsed, '/Length').first);
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

  List<String> _getList(PdfTag tag, String key) {
    if (tag.value[key] is! PdfTagList) {
      return [];
    }
    return (tag.value[key] as PdfTagList).value;
  }

  int _extractNumber(String value) => int.parse(
        String.fromCharCodes(
          value.codeUnits.takeWhile((value) => 0x30 <= value && value <= 0x39),
        ),
      );
}
