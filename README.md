# pdf_image_extractor

A package to extract images from PDF.

> [!NOTE]
> This is experimental and I'm not sure if I'll continue developing it.

| FILTER name | Supported |
|:---|:---|
| ASCIIHexDecode | :white_check_mark: |
| ASCII85Decode | :negative_squared_cross_mark: |
| LZWDecode | :negative_squared_cross_mark: |
| FlateDecode | :white_check_mark: |
| RunLengthDecode | :negative_squared_cross_mark: |
| CCITTFaxDecode | :negative_squared_cross_mark: |
| JBIG2Decode | :negative_squared_cross_mark: |
| DCTDecode | :white_check_mark: |
| JPXDecode | :negative_squared_cross_mark: |
| Crypt | :negative_squared_cross_mark: |

You can still support filters even if this doesn't support it.

```dart
final class _FooImageDecoder implements PdfImageDecoder {
  @override
  bool canDecode(List<PdfImageFilterType> filter) =>
      filter.contains(PdfImageFilterType.runLength);

  @override
  List<int> decode(List<int> bytes) {
    throw UnimplementedError();
  }
}

void main(List<String> arguments) {
  final processor = PdfImageProcessor(
    rawImages,
    decoders: [_FooImageDecoder()],
  );
}
```
