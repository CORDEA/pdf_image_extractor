import 'dart:io';

import 'package:pdf_image_extractor/pdf_image_extractor.dart';
import 'package:pdf_image_extractor/src/pdf_image_processor.dart';
import 'package:test/test.dart';

void main() {
  late PdfImageExtractor extractor;

  test('test1.pdf', () async {
    extractor = PdfImageExtractor(File('./test/fixtures/test1.pdf'));

    final rawImages = await extractor.extract();
    expect(rawImages, hasLength(2));
    for (final image in rawImages) {
      expect(image.width, 448);
      expect(image.height, 448);
      expect(image.bitsPerComponent, 8);
      expect(image.filter, [RawPdfImageFilterType.flate]);
    }
    expect(rawImages[0].length, 15302);
    expect(
      rawImages[0].colorSpace,
      RawPdfImageColorSpaceIccBased(3, PdfImageColorModel.rgb),
    );
    expect(rawImages[1].length, 5108);
    expect(
      rawImages[1].colorSpace,
      RawPdfImageColorModel(PdfImageColorModel.gray),
    );

    final images = PdfImageProcessor(rawImages).write();
    expect(images, hasLength(1));
    expect(images.first.lengthInBytes, 448 * 448 * 4);
  });

  test('test2.pdf', () async {
    extractor = PdfImageExtractor(File('./test/fixtures/test2.pdf'));

    final rawImages = await extractor.extract();
    expect(rawImages, hasLength(2));
    for (final image in rawImages) {
      expect(image.width, 448);
      expect(image.height, 448);
      expect(image.bitsPerComponent, 8);
      expect(image.filter, [RawPdfImageFilterType.flate]);
    }
    expect(rawImages[0].length, 12925);
    expect(
      rawImages[0].colorSpace,
      RawPdfImageColorModel(PdfImageColorModel.rgb),
    );
    expect(rawImages[1].length, 4064);
    expect(
      rawImages[1].colorSpace,
      RawPdfImageColorModel(PdfImageColorModel.gray),
    );

    final images = PdfImageProcessor(rawImages).write();
    expect(images, hasLength(1));
    expect(images.first.lengthInBytes, 448 * 448 * 4);
  });
}
