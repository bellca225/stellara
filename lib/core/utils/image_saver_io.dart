import 'dart:io';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// 모바일/데스크톱: PNG 바이트를 임시 파일로 저장한 뒤 공유 시트로 내보낸다.
/// 사용자는 시트에서 "이미지 저장" 또는 공유 대상 선택이 가능하다.
Future<void> saveImageBytes(
  Uint8List bytes,
  String fileName, {
  String? shareText,
}) async {
  final path = '${Directory.systemTemp.path}/$fileName';
  final file = await File(path).writeAsBytes(bytes, flush: true);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'image/png')],
    text: shareText,
  );
}
