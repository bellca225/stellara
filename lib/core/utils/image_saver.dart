// 플랫폼별 이미지 저장 구현을 조건부 import로 분기한다.
// - 웹(dart.library.html): 브라우저 다운로드
// - 그 외(모바일/데스크톱): 임시 파일로 저장 후 공유 시트(사진에 저장/공유)
export 'image_saver_io.dart' if (dart.library.html) 'image_saver_web.dart';
