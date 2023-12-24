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
}

enum RawPdfImageFilterType {
  flate,
  unknown;

  factory RawPdfImageFilterType._from(String value) {
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

  factory RawPdfImageColorSpace._from(String value) {
    return switch (value) {
      '/DeviceRGB' => rgb,
      '/DeviceGray' => gray,
      _ => unknown,
    };
  }
}

class Serializer {
  bool canDeserialize(List<String> value) =>
      value.any((e) => e.startsWith('/Subtype /Image'));

  RawPdfImage deserialize(RawPdfImageId id, List<String> value) {
    late int width;
    late int height;
    late RawPdfImageColorSpace colorSpace;
    late int bitsPerComponent;
    late int length;
    RawPdfImageFilterType? filter;
    RawPdfImageId? sMask;

    var inStream = false;
    final List<int> bytes = [];
    for (final v in value) {
      if (inStream) {
        bytes.addAll(v.codeUnits);
        continue;
      }
      final line = v.trimRight();
      final args = line.split(' ');
      if (args.length > 1) {
        switch (args[0]) {
          case '/Width':
            width = _extractNumber(args[1]);
          case '/Height':
            height = _extractNumber(args[1]);
          case '/ColorSpace':
            colorSpace = RawPdfImageColorSpace._from(args[1]);
          case '/SMask':
            if (args.length > 3 && args[3] == 'R') {
              sMask = RawPdfImageId(
                objectNumber: _extractNumber(args[1]),
                generationNumber: _extractNumber(args[2]),
              );
            }
          case '/BitsPerComponent':
            bitsPerComponent = _extractNumber(args[1]);
          case '/Filter':
            filter = RawPdfImageFilterType._from(args[1]);
          case '/Length':
            length = _extractNumber(args[1]);
        }
      }
      if (line.endsWith('stream')) {
        inStream = true;
        continue;
      }
      if (line.endsWith('endstream')) {
        inStream = false;
        continue;
      }
    }

    return RawPdfImage(
      id: id,
      width: width,
      height: height,
      bitsPerComponent: bitsPerComponent,
      colorSpace: colorSpace,
      filter: filter,
      length: length,
      sMask: sMask,
      bytes: bytes,
    );
  }

  int _extractNumber(String value) => int.parse(
        String.fromCharCodes(
          value.codeUnits.takeWhile((value) => 0x30 <= value && value <= 0x39),
        ),
      );
}
