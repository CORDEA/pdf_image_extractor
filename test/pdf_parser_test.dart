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
  });

  group('PdfDictionaryParser', () {
    late PdfDictionaryParser parser;

    setUp(() {
      parser = PdfDictionaryParser();
    });

    test('parse dictionary', () {
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

      expect(parsed, {
        '/Type': ['/XObject'],
        '/Subtype': ['/Image'],
        '/SMask': ['5', '0', 'R'],
        '/Length': ['3'],
      });
    });
  });
}
