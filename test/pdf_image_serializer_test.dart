import 'package:mocktail/mocktail.dart';
import 'package:pdf_image_extractor/src/pdf_image_serializer.dart';
import 'package:pdf_image_extractor/src/pdf_parser.dart';
import 'package:pdf_image_extractor/src/raw_pdf_image.dart';
import 'package:test/test.dart';

class _MockPdfTagParser extends Mock implements PdfTagParser {}

void main() {
  group('PdfImageSerializer', () {
    late PdfImageSerializer serializer;
    late _MockPdfTagParser parser;

    setUp(() {
      parser = _MockPdfTagParser();
      serializer = PdfImageSerializer(parser);
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
          PdfTagDictionary({
            '/Type': PdfTagList(['/XObject']),
            '/Subtype': PdfTagList(['/Image']),
            '/Width': PdfTagList(['1']),
            '/Height': PdfTagList(['2']),
            '/ColorSpace': PdfTagList(['/DeviceRGB']),
            '/SMask': PdfTagList(['3', '4', 'R']),
            '/BitsPerComponent': PdfTagList(['5']),
            '/Filter': PdfTagList(['/FlateDecode']),
            '/Length': PdfTagList(['6']),
          }),
        );

        final result = serializer.deserialize(
          RawPdfImageId(objectNumber: 1, generationNumber: 0),
          PdfObject(
            lines: ['line'],
            stream: '\x00\x00\x00\x00\x00\x00',
          ),
          {},
        );

        expect(result.width, 1);
        expect(result.height, 2);
        expect(
          result.colorSpace,
          RawPdfImageColorModel(PdfImageColorModel.rgb),
        );
        expect(
          result.sMask,
          RawPdfImageId(objectNumber: 3, generationNumber: 4),
        );
        expect(result.bitsPerComponent, 5);
        expect(result.filter, [PdfImageFilterType.flate]);
        expect(result.length, 6);
        expect(result.bytes, [0, 0, 0, 0, 0, 0]);
      });
    });

    test('given arguments except for non-required ones', () {
      when(() => parser.parse(['line'])).thenReturn(
        PdfTagDictionary({
          '/Type': PdfTagList(['/XObject']),
          '/Subtype': PdfTagList(['/Image']),
          '/Width': PdfTagList(['1']),
          '/Height': PdfTagList(['2']),
          '/ColorSpace': PdfTagList(['/DeviceRGB']),
          '/SMask': PdfTagList(['3', '4']),
          '/BitsPerComponent': PdfTagList(['5']),
          '/Length': PdfTagList(['6']),
        }),
      );

      final result = serializer.deserialize(
        RawPdfImageId(objectNumber: 1, generationNumber: 0),
        PdfObject(
          lines: ['line'],
          stream: '\x00\x00\x00\x00\x00\x00',
        ),
        {},
      );

      expect(result.width, 1);
      expect(result.height, 2);
      expect(
        result.colorSpace,
        RawPdfImageColorModel(PdfImageColorModel.rgb),
      );
      expect(result.sMask, isNull);
      expect(result.bitsPerComponent, 5);
      expect(result.filter, []);
      expect(result.length, 6);
      expect(result.bytes, [0, 0, 0, 0, 0, 0]);
    });

    test('given multiple filters', () {
      when(() => parser.parse(['line'])).thenReturn(
        PdfTagDictionary({
          '/Width': PdfTagList(['1']),
          '/Height': PdfTagList(['2']),
          '/ColorSpace': PdfTagList(['/DeviceRGB']),
          '/BitsPerComponent': PdfTagList(['5']),
          '/Filter': PdfTagList(['/ASCIIHexDecode', '/LZWDecode']),
          '/Length': PdfTagList(['1']),
        }),
      );

      final result = serializer.deserialize(
        RawPdfImageId(objectNumber: 1, generationNumber: 0),
        PdfObject(lines: ['line'], stream: '\x00'),
        {},
      );

      expect(
        result.filter,
        [PdfImageFilterType.asciiHex, PdfImageFilterType.lzw],
      );
    });

    test('given the ICCBased color space', () {
      when(() => parser.parse(['line1'])).thenReturn(
        PdfTagDictionary({
          '/Width': PdfTagList(['0']),
          '/Height': PdfTagList(['0']),
          '/ColorSpace': PdfTagList(['2', '0', 'R']),
          '/BitsPerComponent': PdfTagList(['0']),
          '/Length': PdfTagList(['1']),
        }),
      );
      when(() => parser.parse(['line2'])).thenReturn(
        PdfTagList(['/ICCBased', '3', '0', 'R']),
      );
      when(() => parser.parse(['line3'])).thenReturn(
        PdfTagDictionary({
          '/N': PdfTagList(['3']),
          '/Alternate': PdfTagList(['/DeviceRGB']),
        }),
      );

      final result = serializer.deserialize(
        RawPdfImageId(objectNumber: 1, generationNumber: 0),
        PdfObject(
          lines: ['line1'],
          stream: '\x00',
        ),
        {
          RawPdfImageId(objectNumber: 2, generationNumber: 0): PdfObject(
            lines: ['line2'],
            stream: null,
          ),
          RawPdfImageId(objectNumber: 3, generationNumber: 0): PdfObject(
            lines: ['line3'],
            stream: null,
          ),
        },
      );

      expect(
        result.colorSpace,
        RawPdfImageColorSpaceIccBased(3, PdfImageColorModel.rgb),
      );
    });

    test('given the indexed color space', () {
      when(() => parser.parse(['line1'])).thenReturn(
        PdfTagDictionary({
          '/Width': PdfTagList(['0']),
          '/Height': PdfTagList(['0']),
          '/ColorSpace': PdfTagList(['2', '0', 'R']),
          '/BitsPerComponent': PdfTagList(['0']),
          '/Length': PdfTagList(['1']),
        }),
      );
      when(() => parser.parse(['line2'])).thenReturn(
        PdfTagList(['/Indexed', '/DeviceRGB', '2', '3', '0', 'R']),
      );

      final result = serializer.deserialize(
        RawPdfImageId(objectNumber: 1, generationNumber: 0),
        PdfObject(
          lines: ['line1'],
          stream: '\x00',
        ),
        {
          RawPdfImageId(objectNumber: 2, generationNumber: 0): PdfObject(
            lines: ['line2'],
            stream: null,
          ),
          RawPdfImageId(objectNumber: 3, generationNumber: 0): PdfObject(
            lines: [],
            stream: '\x01',
          ),
        },
      );

      expect(
        result.colorSpace,
        RawPdfImageColorSpaceIndexed(2, PdfImageColorModel.rgb, [1]),
      );
    });
  });
}
