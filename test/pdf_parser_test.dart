import 'dart:typed_data';

import 'package:pdf_image_extractor/pdf_image_extractor.dart';
import 'package:pdf_image_extractor/src/pdf_parser.dart';
import 'package:test/test.dart';

void main() {
  group('PdfObjectParser', () {
    late PdfObjectParser parser;

    setUp(() {
      parser = PdfObjectParser();
    });

    for (final separator in [
      0x09,
      0x0a,
      0x0c,
      0x0d,
      0x20,
    ]) {
      test('parse the object delimited by $separator', () {
        final test = [
          '4 0 obj',
          '<</Type /XObject',
          '/Subtype /Image',
          '/Length 3>> stream',
          '\x00\x01\x02',
          'endstream',
          'endobj',
        ].join(String.fromCharCode(separator));

        final parsed = parser.parse(Uint8List.fromList(test.codeUnits));

        expect(parsed, {
          RawPdfImageId(objectNumber: 4, generationNumber: 0): PdfObject(
            lines: [
              '<</Type',
              '/XObject',
              '/Subtype',
              '/Image',
              '/Length',
              '3>>',
            ],
            stream: '\x00\x01\x02',
          ),
        });
      });
    }

    test('parse the list', () {
      final parsed = parser.parse(Uint8List.fromList('''
      1 0 obj
      [ /ICCBased 2 0 R ]
      endobj
      '''
          .codeUnits));

      expect(parsed, {
        RawPdfImageId(objectNumber: 1, generationNumber: 0): PdfObject(
          lines: ['[', '/ICCBased', '2', '0', 'R', ']'],
          stream: null,
        )
      });
    });
  });

  group('PdfTagParser', () {
    late PdfTagParser parser;

    setUp(() {
      parser = PdfTagParser();
    });

    test('parse a dictionary without white-space', () {
      final parsed = parser.parse([
        '<</Type',
        '/XObject',
        '/Subtype',
        '/Image',
        '/SMask',
        '5',
        '0',
        'R',
        '/Length',
        '3>>',
      ]);

      expect((parsed as PdfTagDictionary).value, {
        '/Type': ['/XObject'],
        '/Subtype': ['/Image'],
        '/SMask': ['5', '0', 'R'],
        '/Length': ['3'],
      });
    });

    test('parse a dictionary', () {
      final parsed = parser.parse([
        '<<',
        '/Type',
        '/XObject',
        '/Length',
        '0',
        '>>',
      ]);

      expect((parsed as PdfTagDictionary).value, {
        '/Type': ['/XObject'],
        '/Length': ['0'],
      });
    });

    test('parse a list', () {
      final parsed = parser.parse(['[', '/ICCBased', '2', '0', 'R', ']']);

      expect((parsed as PdfTagList).value, ['/ICCBased', '2', '0', 'R']);
    });
  });
}
