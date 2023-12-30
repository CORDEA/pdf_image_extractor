import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:pdf_image_extractor/pdf_image_extractor.dart';

class _Splitter {
  static const _separators = [
    0x09,
    0x0a,
    0x0c,
    0x0d,
    0x20,
  ];

  List<String> split(Uint8List bytes) {
    return bytes
        .splitAfter((e) => _separators.contains(e))
        .map((e) => String.fromCharCodes(e))
        .toList(growable: false);
  }
}

class PdfObjectParser {
  final _splitter = _Splitter();

  Map<RawPdfImageId, PdfObject> parse(Uint8List bytes) {
    final lines = _splitter.split(bytes);
    final Map<RawPdfImageId, PdfObject> objects = {};
    RawPdfImageId? currentId;
    StringBuffer? stream;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.endsWith('obj')) {
        if (line.startsWith('end')) {
          currentId = null;
        } else {
          currentId = RawPdfImageId(
            objectNumber: int.parse(lines[i - 2]),
            generationNumber: int.parse(lines[i - 1]),
          );
        }
        continue;
      }
      if (currentId == null) {
        continue;
      }
      final value = objects.putIfAbsent(
        currentId,
        () => PdfObject(lines: [], stream: null),
      );
      if (line.endsWith('stream')) {
        if (line.startsWith('end')) {
          if (stream != null) {
            objects[currentId] =
                value.copyWith(stream: stream.toString().trim());
            stream = null;
          }
        } else {
          stream = StringBuffer();
        }
        continue;
      }
      if (stream != null) {
        stream.write(lines[i]);
        continue;
      }
      if (line.isEmpty) {
        continue;
      }
      objects[currentId] = value.copyWith(lines: value.lines + [line]);
    }
    return objects;
  }
}

class PdfObject {
  PdfObject({required this.lines, required this.stream});

  final List<String> lines;
  final String? stream;

  PdfObject copyWith({
    List<String>? lines,
    String? stream,
  }) =>
      PdfObject(lines: lines ?? this.lines, stream: stream ?? this.stream);

  @override
  int get hashCode => Object.hash(lines, stream);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfObject &&
          IterableEquality().equals(lines, other.lines) &&
          stream == other.stream;

  @override
  String toString() => 'PdfObject(lines: $lines, stream: $stream)';
}

class PdfTagParser {
  PdfTag parse(List<String> lines) {
    PdfTag? tag;
    String? key;
    List<String>? value;
    for (final v in lines) {
      var line = v.trim();
      if (line.startsWith('<<')) {
        tag = PdfTagDictionary({});
        line = line.substring(2);
      }
      if (line.startsWith('[')) {
        tag = PdfTagList([]);
        line = line.substring(1);
      }
      if (tag == null) {
        continue;
      }
      if (line.endsWith('>>')) {
        line = line.substring(0, line.length - 2);
      }
      if (line.endsWith(']')) {
        line = line.substring(0, line.length - 1);
      }
      if (line.isEmpty) {
        continue;
      }
      switch (tag) {
        case PdfTagDictionary():
          if (line.startsWith('/') && key != null && value != null) {
            key = null;
            value = null;
          }
          if (key == null) {
            key = line;
            continue;
          }
          value = (value ?? []) + [line];
          tag.value[key] = value;
        case PdfTagList():
          tag.value.add(line);
      }
    }
    return tag!;
  }
}

sealed class PdfTag {}

final class PdfTagDictionary extends PdfTag {
  PdfTagDictionary(this.value);

  final Map<String, List<String>> value;
}

final class PdfTagList extends PdfTag {
  PdfTagList(this.value);

  final List<String> value;
}
