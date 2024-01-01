import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:image/image.dart';
import 'package:pdf_image_extractor/src/raw_pdf_image.dart';

abstract interface class PdfImageDecoder {
  bool canDecode(List<PdfImageFilterType> filter);

  List<int> decode(List<int> bytes);
}

final class _PdfFlateImageDecoder implements PdfImageDecoder {
  final zlibDecoder = ZLibDecoder();

  @override
  bool canDecode(List<PdfImageFilterType> filter) =>
      filter.contains(PdfImageFilterType.flate);

  @override
  List<int> decode(List<int> bytes) => zlibDecoder.convert(bytes);
}

final class _PdfAsciiHexImageDecoder implements PdfImageDecoder {
  @override
  bool canDecode(List<PdfImageFilterType> filter) =>
      filter.contains(PdfImageFilterType.asciiHex);

  @override
  List<int> decode(List<int> bytes) => bytes
      .takeWhile((value) => value != 0x3e)
      .map(
        (e) => switch (e) {
          >= 0x30 && <= 0x39 => e & 0xf,
          >= 0x41 && <= 0x46 || >= 0x61 && <= 0x66 => (e & 0xf) + 0x9,
          int() => null,
        },
      )
      .whereNotNull()
      .slices(2)
      .map((e) => e[0] << 4 | e[1])
      .toList(growable: false);
}

final _defaultDecoders = [_PdfFlateImageDecoder(), _PdfAsciiHexImageDecoder()];

class PdfImageProcessor {
  PdfImageProcessor(
    Iterable<RawPdfImage> images, {
    List<PdfImageDecoder>? decoders,
    this.leaveMask = false,
  })  : _imageMap = Map.fromIterable(images, key: (e) => e.id),
        _decoders = decoders ?? _defaultDecoders;

  final List<PdfImageDecoder> _decoders;
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
    final hasDctDecoder =
        _decoders.any((e) => e.canDecode([PdfImageFilterType.dct]));
    return maskedImages.map((e) {
      final source = _decode(e.source);
      final mask = e.mask == null ? null : _decode(e.mask!);
      if (!hasDctDecoder && e.source.filter.contains(PdfImageFilterType.dct)) {
        if (mask != null) {
          throw UnsupportedError(
            'DCT filter and mask were detected at the same time.',
          );
        }
        return decodeJpg(Uint8List.fromList(source))!;
      }
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
        case RawPdfImageColorSpaceIndexed(base: final value):
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
              final ({int r, int g, int b}) rgb;
              if (colorSpace is RawPdfImageColorSpaceIndexed) {
                rgb = (
                  r: colorSpace.table[source[i] * 3],
                  g: colorSpace.table[source[i] * 3 + 1],
                  b: colorSpace.table[source[i] * 3 + 2],
                );
              } else {
                rgb = (
                  r: source[i * 3],
                  g: source[i * 3 + 1],
                  b: source[i * 3 + 2],
                );
              }
              final a = mask?[i] ?? 255;
              image
                ..r = rgb.r
                ..g = rgb.g
                ..b = rgb.b
                ..a = a;
            case 1:
              if (colorSpace is RawPdfImageColorSpaceIndexed) {
                image.r = colorSpace.table[source[i]];
              } else {
                image.r = source[i];
              }
            default:
              throw ArgumentError('Invalid number of channels. $channels');
          }
        });
    }).toList(growable: false);
  }

  List<int> _decode(RawPdfImage image) {
    final result = _decoders
        .firstWhereOrNull((e) => e.canDecode(image.filter))
        ?.decode(image.bytes);
    if (result == null) {
      throw UnsupportedError('Unsupported filter. ${image.filter}');
    }
    return result;
  }
}
