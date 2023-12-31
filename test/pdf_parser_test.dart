import 'dart:typed_data';

import 'package:pdf_image_extractor/pdf_image_extractor.dart';
import 'package:pdf_image_extractor/src/pdf_parser.dart';
import 'package:test/test.dart';

void main() {
  group('PdfSplitter', () {
    late PdfSplitter splitter;

    setUp(() {
      splitter = PdfSplitter();
    });

    final tests = {
      'a\x09b\x0ac\x0cd\x0de\x20\x0a\x0c': [
        'a\x09',
        'b\x0a',
        'c\x0c',
        'd\x0d',
        'e\x20',
        '\x0a',
        '\x0c',
      ],
      '<<a>>': ['<<', 'a', '>>'],
      '<a>>': ['<a', '>>'],
      '<<[a>>]': ['<<', '[', 'a', '>>', ']'],
      '/a/b': ['/a', '/b'],
    };

    tests.forEach((key, value) {
      test('split $key', () {
        expect(splitter.split(Uint8List.fromList(key.codeUnits)), value);
      });
    });
  });

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
      test('parse an object delimited by $separator', () {
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
              '<<',
              '/Type',
              '/XObject',
              '/Subtype',
              '/Image',
              '/Length',
              '3',
              '>>',
            ],
            stream: '\x00\x01\x02',
          ),
        });
      });
    }

    test('parse an object without delimiter', () {
      final test = '''
      4 0 obj
      <</Type/XObject/Subtype/Image>>
      endobj
      ''';

      final parsed = parser.parse(Uint8List.fromList(test.codeUnits));

      expect(parsed, {
        RawPdfImageId(objectNumber: 4, generationNumber: 0): PdfObject(
          lines: [
            '<<',
            '/Type',
            '/XObject',
            '/Subtype',
            '/Image',
            '>>',
          ],
          stream: null,
        ),
      });
    });

    test('parse a list', () {
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

    test('parse an object containing a subdictionary', () {
      final parsed = parser.parse(Uint8List.fromList('''
      1 0 obj
      << /Type /Example
      /Key 1
      /Subdictionary << /Key1 2
      /Key2 true
      >>
      >>
      endobj
      '''
          .codeUnits));

      expect(parsed, {
        RawPdfImageId(objectNumber: 1, generationNumber: 0): PdfObject(
          lines: [
            '<<',
            '/Type',
            '/Example',
            '/Key',
            '1',
            '/Subdictionary',
            '<<',
            '/Key1',
            '2',
            '/Key2',
            'true',
            '>>',
            '>>',
          ],
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
        '<<',
        '/Type',
        '/XObject',
        '/Subtype',
        '/Image',
        '/SMask',
        '5',
        '0',
        'R',
        '/Length',
        '3',
        '>>',
      ]);

      expect((parsed as PdfTagDictionary).value, {
        '/Type': PdfTagList(['/XObject']),
        '/Subtype': PdfTagList(['/Image']),
        '/SMask': PdfTagList(['5', '0', 'R']),
        '/Length': PdfTagList(['3']),
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
        '/Type': PdfTagList(['/XObject']),
        '/Length': PdfTagList(['0']),
      });
    });

    test('parse a list', () {
      final parsed = parser.parse(['[', '/ICCBased', '2', '0', 'R', ']']);

      expect((parsed as PdfTagList).value, ['/ICCBased', '2', '0', 'R']);
    });

    test('parse an object containing a subdictionary', () {
      final parsed = parser.parse([
        '<<',
        '/Type',
        '/Example',
        '/Key1',
        '1',
        '/Subdictionary',
        '<<',
        '/Key2',
        '2',
        '/Key3',
        'true',
        '>>',
        '/Key4',
        'false',
        '>>',
      ]);

      expect((parsed as PdfTagDictionary).value, {
        '/Type': PdfTagList(['/Example']),
        '/Key1': PdfTagList(['1']),
        '/Subdictionary': PdfTagDictionary({
          '/Key2': PdfTagList(['2']),
          '/Key3': PdfTagList(['true']),
        }),
        '/Key4': PdfTagList(['false']),
      });
    });

    test('parse an object containing a sublist', () {
      final parsed = parser.parse([
        '<<',
        '/Type',
        '/Example',
        '/Key1',
        '1',
        '/Sublist',
        '[',
        '2',
        ']',
        '/Key4',
        'false',
        '>>',
      ]);

      expect((parsed as PdfTagDictionary).value, {
        '/Type': PdfTagList(['/Example']),
        '/Key1': PdfTagList(['1']),
        '/Sublist': PdfTagList(['2']),
        '/Key4': PdfTagList(['false']),
      });
    });
  });
}
