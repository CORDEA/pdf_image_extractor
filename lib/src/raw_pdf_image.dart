import 'dart:typed_data';

import 'package:pdf_image_extractor/src/pdf_parser.dart';

class RawPdfImage {
  final RawPdfImageId id;
  final int width;
  final int height;
  final int bitsPerComponent;
  final RawPdfImageColorSpace colorSpace;
  final RawPdfImageFilterType? filter;
  final int length;
  final RawPdfImageId? sMask;
  final List<int> bytes;

  RawPdfImage({
    required this.id,
    required this.width,
    required this.height,
    required this.bitsPerComponent,
    required this.colorSpace,
    required this.filter,
    required this.length,
    required this.sMask,
    required this.bytes,
  });
}

class RawPdfImageId {
  final int objectNumber;
  final int generationNumber;

  RawPdfImageId({
    required this.objectNumber,
    required this.generationNumber,
  });

  @override
  int get hashCode => Object.hash(objectNumber, generationNumber);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RawPdfImageId &&
          objectNumber == other.objectNumber &&
          generationNumber == other.generationNumber;

  @override
  String toString() =>
      'RawPdfImageId(objectNumber: $objectNumber,  generationNumber: $generationNumber)';
}

enum RawPdfImageFilterType {
  flate,
  unknown;

  factory RawPdfImageFilterType.from(String value) {
    return switch (value) {
      '/FlateDecode' => flate,
      _ => unknown,
    };
  }
}

enum RawPdfImageColorSpace {
  rgb,
  gray,
  unknown;

  factory RawPdfImageColorSpace.from(String value) {
    return switch (value) {
      '/DeviceRGB' => rgb,
      '/DeviceGray' => gray,
      _ => unknown,
    };
  }
}

class Serializer {
  Serializer(this._parser);

  final PdfTagParser _parser;

  bool canDeserialize(List<String> value) {
    final index = value.indexOf('/Subtype');
    if (index < 0 || value.length <= index + 1) {
      return false;
    }
    return value[index + 1] == '/Image';
  }

  RawPdfImage deserialize(RawPdfImageId id, PdfObject value) {
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
            colorSpace = RawPdfImageColorSpace.from(value.first);
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
