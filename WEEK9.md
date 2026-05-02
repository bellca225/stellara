# Stellara — Week 9 작업 노트

브랜치: `feature/week09-prokerala-api`  
범위: Prokerala Astrology API 직접 연결 + 흑백 미니멀 UI 골격 + Riverpod 상태 관리 도입

## 1. 무엇이 바뀌었나

| 분류 | 변경 |
| --- | --- |
| 패키지 | `dio`, `flutter_dotenv`, `flutter_riverpod`, `freezed_annotation`, `json_annotation`, `geocoding`, `intl` 추가. dev에 `build_runner`, `freezed`, `json_serializable`, `riverpod_generator` 등록(현재는 사용 X, 향후 주차에서 활용). |
| 폴더 | 1782줄 단일 `lib/main.dart` → `lib/{core,features/*}` 로 완전 재구조화. |
| 환경 | `.env`(secret) + `.env.example`(템플릿). `.gitignore` 에 `.env` 추가. `pubspec.yaml`의 `assets` 에 `.env` 등록(런타임 로드 가능하게). |
| 상태 관리 | `ProviderScope` + `flutter_riverpod` 도입. `currentBirthInfoProvider`, `myNatalChartProvider`, `todayHoroscopeProvider`, `synastryProvider` 등록. |
| 디자인 | `core/theme/app_theme.dart` 흑백 단일 팔레트(잉크/페이퍼/라인). 컬러 테마는 13주차에 복구 예정. |
| API | Prokerala OAuth2 (`client_credentials`) 토큰 매니저 + Bearer 인터셉터 + 401 자동 재발급 + 429 retry. Natal/Daily Horoscope/Synastry 호출 wrapper. |
| Fixture | 디버그 모드에서 fixture 응답을 우선 사용 (`USE_FIXTURE_IN_DEBUG=true`) → credit 절약. |

## 2. 핵심 파일 지도

```
lib/
├── main.dart                                 # dotenv 로드 + ProviderScope
├── app.dart                                  # MaterialApp + 흑백 ThemeData
├── core/
│   ├── env/env.dart                          # .env 키 단일 진입점
│   ├── http/dio_client.dart                  # Bearer/RateLimit/Logging 인터셉터
│   ├── theme/app_theme.dart                  # 흑백 팔레트 + 텍스트/버튼 테마
│   └── widgets/panel.dart                    # Panel/SectionTitle/KeyValueRow/SkeletonBox
└── features/
    ├── auth/presentation/login_screen.dart   # LOGIN-001
    ├── home/presentation/main_home_screen.dart # MAIN-001
    ├── onboarding/
    │   ├── presentation/onboarding_screen.dart  # ONBOARDING-001
    │   └── app_shell.dart                       # NAV-001 (하단 4탭)
    ├── astrology/
    │   ├── data/prokerala_token_repository.dart # OAuth2 토큰 캐시/갱신
    │   ├── data/prokerala_api.dart              # 엔드포인트 wrapper
    │   ├── data/astrology_repository.dart       # JSON → NatalChart 매핑 + fallback
    │   ├── domain/{birth_info,natal_chart}.dart
    │   ├── application/astrology_providers.dart
    │   └── presentation/{astrology_screen,natal_chart_painter}.dart  # ASTROLOGY-001
    ├── horoscope/
    │   ├── data/horoscope_repository.dart
    │   ├── domain/horoscope.dart
    │   ├── application/horoscope_providers.dart
    │   └── presentation/today_screen.dart       # TODAY-001
    ├── content/presentation/random_question_screen.dart # CONTENT-001
    ├── profile/presentation/my_page_screen.dart # MYPAGE-001
    ├── friends/presentation/friend_screen.dart  # FRIEND-001
    └── compatibility/
        ├── data/synastry_repository.dart        # 어스펙트 → 4축 점수 변환
        ├── domain/synastry_result.dart
        ├── application/compatibility_providers.dart
        └── presentation/match_screen.dart       # MATCH-001
```

## 3. 실행

```bash
git checkout feature/week09-prokerala-api
flutter pub get
# .env 가 이미 있으면 그대로 둠. 없으면:
cp .env.example .env  # 그리고 PROKERALA_CLIENT_ID/SECRET 채우기

flutter analyze       # 정적 검사
flutter test          # 위젯/유닛 테스트
flutter emulators --launch Medium_Phone_API_36.1
flutter devices
flutter run -d emulator-5554
flutter run -d chrome # 웹에서 빠르게 확인 (또는 -d <에뮬레이터>)
```

현재 홈 탭은 `MAIN-001`이고, 점성술 상세 화면 `ASTROLOGY-001`은 홈에서 내 행성 아이콘을 눌렀을 때 진입합니다.

## 4. credit 사용량 가이드

> 9주차 단계 기준. 정확한 수치는 첫 실호출의 응답 헤더(X-RateLimit-Cost / Remaining)에서 확인.

| 호출 | 보수적 추정 (사용자 자료) | 검색 기준 (공식 페이지) |
| --- | --- | --- |
| OAuth `/token` | 0 credit | 0 credit |
| Natal Chart 1건 | ~500 | ~50 |
| Daily Horoscope 1건 | ~100 | ~50 |
| Synastry 1건 | ~800 | ~100 |

무료 플랜은 월 5,000 credits / 분당 5 호출 제한이 있으니 개발 중에는 fixture 모드를 켜두세요.

## 5. 검증 체크리스트 (5단계 자체 리뷰 결과)

1. **import 정합성** — 모든 import 경로 확인 완료. 순환 참조 없음.
2. **타입 일관성** — `Provider`/`FutureProvider.family` 의 타입 매개변수 일치.
3. **스크롤/비율** — `AspectRatio(1)` + `LayoutBuilder` 로 차트 비율 고정. `ListView` + `SafeArea` 로 안전 스크롤.
4. **fallback 동작** — API 실패 시 `kDebugMode`에서 fixture 로 graceful fallback. 사용자에게 빈 화면 보여지지 않음.
5. **secret 노출 금지** — `.env`는 `.gitignore`. 로그에 secret 출력 안 함. (release 빌드에선 secret 이 APK 에 포함되므로 추후 백엔드 분리 권장 — README에 명시.)

## 6. 9주차에서 의도적으로 미루는 것

- Kakao OAuth 실연동 → **10주차**
- Firebase / Firestore → **10~11주차**
- 친구 검색·요청·즐겨찾기 → **11주차**
- 랜덤 질문 (OpenAI/Claude) → **12주차**
- FCM 푸시 → **12주차**
- 공유 이미지 / Lottie / 컬러 디자인 복원 → **13주차**
- 통합 테스트 / 문서 폴리시 → **14주차**
