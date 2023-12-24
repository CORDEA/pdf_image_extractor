import 'package:collection/collection.dart';
import 'package:image/image.dart';
import 'package:pdf_image_extractor/src/raw_pdf_image.dart';

class PdfImageProcessor {
  PdfImageProcessor(List<RawPdfImage> images, {this.leaveMask = false})
      : _imageMap = Map.fromIterable(images, key: (e) => e.id);

  final Map<RawPdfImageId, RawPdfImage> _imageMap;
  final bool leaveMask;

  List<Image> write() {
    final images = _imageMap.values;
    final List<({RawPdfImage image, RawPdfImage? mask})> maskedImages;
    if (leaveMask) {
      maskedImages =
          images.map((e) => (image: e, mask: null)).toList(growable: false);
    } else {
      final sources = images
          .map((e) => e.id)
          .toSet()
          .difference(images.map((e) => e.sMask).whereNotNull().toSet());
      maskedImages = sources.map((e) {
        final image = _imageMap[e]!;
        final mask = image.sMask;
        return (
          image: image,
          mask: mask == null ? null : _imageMap[mask],
        );
      }).toList(growable: false);
    }
    return [];
  }
}
