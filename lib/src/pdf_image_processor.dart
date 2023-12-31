import 'dart:io';

import 'package:collection/collection.dart';
import 'package:image/image.dart';
import 'package:pdf_image_extractor/src/raw_pdf_image.dart';

class PdfImageProcessor {
  PdfImageProcessor(List<RawPdfImage> images, {this.leaveMask = false})
      : _imageMap = Map.fromIterable(images, key: (e) => e.id);

  final _zlibDecoder = ZLibDecoder();
  final Map<RawPdfImageId, RawPdfImage> _imageMap;
  final bool leaveMask;

  List<Image> write() {
    final images = _imageMap.values;
    final List<({RawPdfImage source, RawPdfImage? mask})> maskedImages;
    if (leaveMask) {
      maskedImages =
          images.map((e) => (source: e, mask: null)).toList(growable: false);
    } else {
      final sources = images
          .map((e) => e.id)
          .toSet()
          .difference(images.map((e) => e.sMask).whereNotNull().toSet());
      maskedImages = sources.map((e) {
        final image = _imageMap[e]!;
        final mask = image.sMask;
        return (
          source: image,
          mask: mask == null ? null : _imageMap[mask],
        );
      }).toList(growable: false);
    }
    return maskedImages.map((e) {
      final source = _decode(e.source);
      final mask = e.mask == null ? null : _decode(e.mask!);
      final int channels;
      final colorSpace = e.source.colorSpace;
      switch (colorSpace) {
        case RawPdfImageColorSpaceIccBased(
            n: final n,
            alternate: final alternate,
          ):
          switch (alternate) {
            case PdfImageColorModel.rgb:
              channels = mask == null ? 3 : 4;
            case PdfImageColorModel.gray:
              channels = 1;
            case PdfImageColorModel.unknown:
              channels = n + (mask == null ? 0 : 1);
          }
        case RawPdfImageColorModel(value: final value):
          switch (value) {
            case PdfImageColorModel.rgb:
              channels = mask == null ? 3 : 4;
            case PdfImageColorModel.gray:
              channels = 1;
            case PdfImageColorModel.unknown:
              throw UnimplementedError();
          }
      }
      return Image(
        width: e.source.width,
        height: e.source.height,
        numChannels: channels,
      )..forEachIndexed((i, image) {
          switch (channels) {
            case 3:
            case 4:
              final r = source[i * 3];
              final g = source[i * 3 + 1];
              final b = source[i * 3 + 2];
              final a = mask?[i] ?? 255;
              image
                ..r = r
                ..g = g
                ..b = b
                ..a = a;
            case 1:
              image.r = source[i];
            default:
              throw UnimplementedError();
          }
        });
    }).toList(growable: false);
  }

  List<int> _decode(RawPdfImage image) {
    switch (image.filter) {
      case RawPdfImageFilterType.flate:
        return _zlibDecoder.convert(image.bytes);
      case RawPdfImageFilterType.unknown:
      case null:
        throw UnimplementedError();
    }
  }
}
