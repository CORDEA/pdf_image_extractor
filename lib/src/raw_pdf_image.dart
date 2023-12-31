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

enum PdfImageColorModel {
  rgb,
  gray,
  unknown;

  factory PdfImageColorModel.from(String value) {
    return switch (value) {
      '/DeviceRGB' => rgb,
      '/DeviceGray' => gray,
      _ => unknown,
    };
  }
}

sealed class RawPdfImageColorSpace {}

final class RawPdfImageColorSpaceIccBased extends RawPdfImageColorSpace {
  RawPdfImageColorSpaceIccBased(this.n, this.alternate);

  final int n;
  final PdfImageColorModel alternate;

  @override
  int get hashCode => Object.hash(n, alternate);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RawPdfImageColorSpaceIccBased &&
          n == other.n &&
          alternate == other.alternate;
}

final class RawPdfImageColorModel extends RawPdfImageColorSpace {
  RawPdfImageColorModel(this.value);

  final PdfImageColorModel value;

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RawPdfImageColorModel && value == other.value;
}
