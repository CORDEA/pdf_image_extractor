class RawPdfImage {
  final RawPdfImageId id;
  final int width;
  final int height;
  final int bitsPerComponent;
  final RawPdfImageFilterType filter;
  final int length;
  final RawPdfImageId sMask;
  final List<int> bytes;

  RawPdfImage({
    required this.id,
    required this.width,
    required this.height,
    required this.bitsPerComponent,
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
}

enum RawPdfImageFilterType { flate }

enum RawPdfImageColorSpace { rgb, gray }
