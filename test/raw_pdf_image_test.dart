import 'package:pdf_image_extractor/pdf_image_extractor.dart';
import 'package:test/test.dart';

void main() {
  group('PdfImageFilterType', () {
    final tests = {
      PdfImageFilterType.flate: '/FlateDecode',
      PdfImageFilterType.jpx: '/JPXDecode',
      PdfImageFilterType.asciiHex: '/ASCIIHexDecode',
      PdfImageFilterType.lzw: '/LZWDecode',
      PdfImageFilterType.runLength: '/RunLengthDecode',
      PdfImageFilterType.crypt: '/Crypt',
      PdfImageFilterType.dct: '/DCTDecode',
      PdfImageFilterType.ascii85: '/ASCII85Decode',
      PdfImageFilterType.ccittFax: '/CCITTFaxDecode',
      PdfImageFilterType.jbig2: '/JBIG2Decode',
    };

    tests.forEach((key, value) {
      test('from $value', () {
        expect(PdfImageFilterType.from(value), key);
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
