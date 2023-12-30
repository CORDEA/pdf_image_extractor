import 'package:mocktail/mocktail.dart';
import 'package:pdf_image_extractor/pdf_image_extractor.dart';
import 'package:pdf_image_extractor/src/pdf_parser.dart';
import 'package:test/test.dart';

class _MockPdfDictionaryParser extends Mock implements PdfDictionaryParser {}

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

  group('RawPdfImageColorSpace', () {
    final tests = {
      RawPdfImageColorSpace.rgb: '/DeviceRGB',
      RawPdfImageColorSpace.gray: '/DeviceGray',
      RawPdfImageColorSpace.unknown: '/',
    };

    tests.forEach((key, value) {
      test('from $value', () {
        expect(RawPdfImageColorSpace.from(value), key);
      });
    });
  });

  group('Serializer', () {
    late Serializer serializer;
    late _MockPdfDictionaryParser parser;

    setUp(() {
      parser = _MockPdfDictionaryParser();
      serializer = Serializer(parser);
    });

    group('canDeserialize', () {
      final tests = {
        <String>[]: false,
        ['/Subtype']: false,
        ['/Subtype', '', '/Image']: false,
        ['/Subtype', '/Image', '']: true,
      };

      tests.forEach((key, value) {
        test('given $key', () {
          expect(serializer.canDeserialize(key), value);
        });
      });
    });

    group('deserialize', () {
      test('given arguments', () {
        when(() => parser.parse(['line'])).thenReturn(
          {
            '/Type': ['/XObject'],
            '/Subtype': ['/Image'],
            '/Width': ['1'],
            '/Height': ['2'],
            '/ColorSpace': ['/DeviceRGB'],
            '/SMask': ['3', '4', 'R'],
            '/BitsPerComponent': ['5'],
            '/Filter': ['/FlateDecode'],
            '/Length': ['6'],
          },
        );

        final result = serializer.deserialize(
          RawPdfImageId(objectNumber: 1, generationNumber: 0),
          PdfObject(
            lines: ['line'],
            stream: '\x00\x00\x00\x00\x00\x00',
          ),
        );

        expect(result.width, 1);
        expect(result.height, 2);
        expect(result.colorSpace, RawPdfImageColorSpace.rgb);
        expect(
          result.sMask,
          RawPdfImageId(objectNumber: 3, generationNumber: 4),
        );
        expect(result.bitsPerComponent, 5);
        expect(result.filter, RawPdfImageFilterType.flate);
        expect(result.length, 6);
        expect(result.bytes, [0, 0, 0, 0, 0, 0]);
      });
    });

    test('given arguments except for non-required ones', () {
      when(() => parser.parse(['line'])).thenReturn(
        {
          '/Type': ['/XObject'],
          '/Subtype': ['/Image'],
          '/Width': ['1'],
          '/Height': ['2'],
          '/ColorSpace': ['/DeviceRGB'],
          '/SMask': ['3', '4'],
          '/BitsPerComponent': ['5'],
          '/Length': ['6'],
        },
      );

      final result = serializer.deserialize(
        RawPdfImageId(objectNumber: 1, generationNumber: 0),
        PdfObject(
          lines: ['line'],
          stream: '\x00\x00\x00\x00\x00\x00',
        ),
      );

      expect(result.width, 1);
      expect(result.height, 2);
      expect(result.colorSpace, RawPdfImageColorSpace.rgb);
      expect(result.sMask, isNull);
      expect(result.bitsPerComponent, 5);
      expect(result.filter, isNull);
      expect(result.length, 6);
      expect(result.bytes, [0, 0, 0, 0, 0, 0]);
    });
  });
}
