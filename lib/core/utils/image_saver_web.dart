// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

/// 웹: PNG 바이트를 Blob으로 만들어 브라우저 다운로드를 트리거한다.
/// shareText는 웹 다운로드에서는 사용하지 않는다(시그니처 호환용).
Future<void> saveImageBytes(
  Uint8List bytes,
  String fileName, {
  String? shareText,
}) async {
  final blob = html.Blob(<dynamic>[bytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
