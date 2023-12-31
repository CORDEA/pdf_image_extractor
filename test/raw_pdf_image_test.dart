import 'package:pdf_image_extractor/pdf_image_extractor.dart';
import 'package:test/test.dart';

void main() {
  group('RawPdfImageFilterType', () {
    final tests = {
      RawPdfImageFilterType.flate: '/FlateDecode',
      RawPdfImageFilterType.unknown: '/',
    };

    tests.forEach((key, value) {
      test('from $value', () {
        expect(RawPdfImageFilterType.from(value), key);
      });
    });
  });

  group('PdfImageColorModel', () {
    final tests = {
      PdfImageColorModel.rgb: '/DeviceRGB',
      PdfImageColorModel.gray: '/DeviceGray',
      PdfImageColorModel.unknown: '/',
    };

    tests.forEach((key, value) {
      test('from $value', () {
        expect(PdfImageColorModel.from(value), key);
      });
    });
  });
}
