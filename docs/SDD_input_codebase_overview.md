# Stellara — 코드베이스 분석 요약 (SDD 작성용)

> 분석 시점: 2026-05-08 / 분석 범위: `/Users/nywoo/proj/stellara` 전체 트리.
> 본 문서는 SDD 초안에 그대로 옮길 수 있도록 정리한 1차 자료이며,
> 코드는 아직 수정하지 않았습니다.

## 0. 한 줄 요약

Stellara는 **현재 “프론트엔드 단독” 단계의 Flutter 앱**입니다. 자체 백엔드 서버는 아직 없으며, 외부 점성술 API(Prokerala)를 앱에서 직접 호출하는 구조의 골격까지만 구현되어 있고, DB·인증·AI 생성 등은 미구현 상태입니다. (실측: `lib/` 아래 Dart 파일 33개, Prokerala 호출 wrapper와 Riverpod 골격만 동작.)

## 1. 기술 스택 (확실)

`pubspec.yaml` / `lib/main.dart` 기준.

| 영역 | 사용 기술 |
| --- | --- |
| 클라이언트 프레임워크 | Flutter (`environment.sdk: ^3.11.1`, Dart 3.5+) |
| 상태 관리 | `flutter_riverpod ^2.5.1` (+ `riverpod_annotation`은 등록만, 코드 생성은 아직 미사용) |
| 모델 직렬화 | `freezed_annotation`, `json_annotation` 등록은 되어 있으나 **현재 코드에선 아직 미사용** (도메인 모델 직접 작성) |
| HTTP | `dio ^5.7.0` + 커스텀 인터셉터 3종(Auth/RateLimit/Logging) |
| 환경 변수 | `flutter_dotenv ^5.2.1` (`assets`에 `.env` 등록) |
| 지오코딩 | `geocoding ^3.0.0` 패키지 등록만 되어 있음 — **실제 호출 코드는 아직 없음** (확실하지 않음: 앞으로 출생지 → 좌표 변환에 쓸 예정인 듯) |
| 날짜/포맷 | `intl ^0.19.0` |
| 빌드 타깃 | `android/`, `ios/`, `macos/`, `web/` 모두 Flutter 기본 템플릿 그대로. 9주차 주 타깃은 Android 에뮬레이터(`Medium_Phone_API_36.1`)와 Chrome. |

**아직 들어와 있지 않은 것 (README의 “예정 패키지” 항목)**: `kakao_flutter_sdk_user`, `firebase_core`, `cloud_firestore`, `firebase_messaging`, `flutter_secure_storage`, `lottie`, `share_plus`, `screenshot`, `go_router`, `shared_preferences`, `cached_network_image`, `flutter_local_notifications`. 즉 **인증·DB·푸시·공유·라우팅 패키지가 모두 미도입 상태**입니다.

## 2. 폴더 구조와 역할

루트 트리(상위 의미 단위만):

```
stellara/
├── lib/                          # 앱 본체 (Dart)
│   ├── main.dart                 # 진입점: dotenv 로드 + ProviderScope
│   ├── app.dart                  # MaterialApp + 흑백 ThemeData + 첫 화면=LoginScreen
│   ├── core/                     # 도메인 무관 공통 인프라
│   └── features/                 # 도메인별 화면+상태+데이터
├── test/                         # widget/유닛 테스트(2개)
├── assets/                       # 이미지 등 (현재 비어 있음 — `find` 결과 0건)
├── android/, ios/, macos/, web/  # Flutter 플랫폼 폴더(기본 템플릿)
├── pubspec.yaml / pubspec.lock
├── analysis_options.yaml
├── .env / .env.example           # Prokerala 키 (.env는 .gitignore)
├── README.md / WEEK9.md          # 실행 가이드 / 9주차 작업 노트
└── build/                        # 빌드 산출물 (분석 무관)
```

### 2.1 `lib/core/` — 공통 인프라

| 파일 | 역할 |
| --- | --- |
| `core/env/env.dart` | `.env` 키 단일 진입점. 필수 키(`PROKERALA_CLIENT_ID/SECRET`) 부재 시 `MissingEnvException` 발생 → 앱 부팅에서 친절한 에러 화면으로 바뀜. |
| `core/http/dio_client.dart` | Prokerala 전용 `Dio` 인스턴스 빌더. **AuthInterceptor**(Bearer 자동 주입 + 401시 1회 토큰 강제 갱신 후 재시도), **RateLimitInterceptor**(429+`Retry-After`), **LoggingInterceptor**(디버그 한정, X-RateLimit-* 헤더 출력)을 묶어둠. |
| `core/theme/app_theme.dart` | 흑백 단일 팔레트(`AppColors.ink/inkMuted/inkSubtle/line/paper/canvas/skeleton`) + 반경/간격 상수 + Material3 ColorScheme/TextTheme. |
| `core/ui/app_alerts.dart` | 글로벌 `appNavigatorKey` + 토큰 소진 다이얼로그 `AppAlerts.showTokenExhaustedDialog()`. 인터셉터에서 호출. |
| `core/utils/astro_text.dart` | 영문 별자리/행성/어스펙트/무드/색상 → 한글 라벨 매핑 (`zodiacNameKo`, `zodiacEmoji`, `zodiacLabelKo` 등). |
| `core/widgets/panel.dart` | 흑백 디자인 공용 위젯: `Panel`, `SectionTitle`, `WireframeHeader`, `KeyValueRow`, `SkeletonBox`, `ScreenCodeChip` (확실하지 않음: 마지막 위젯명은 화면 사용처에서 호출되는 것을 보고 추론). |

### 2.2 `lib/features/` — 도메인별 모듈 (관심사 분리: `application/data/domain/fixtures/presentation`)

| 도메인 | 폴더 구성 (실측) | 화면 ID |
| --- | --- | --- |
| `auth/` | `presentation/login_screen.dart` 만 존재 | `LOGIN-001` |
| `onboarding/` | `app_shell.dart` (하단 4탭 IndexedStack) + `presentation/onboarding_screen.dart` | `ONBOARDING-001`, `NAV-001` |
| `home/` | `presentation/main_home_screen.dart` | `MAIN-001` |
| `astrology/` | `application/astrology_providers.dart` · `data/{prokerala_token_repository, prokerala_api, astrology_repository}.dart` · `domain/{birth_info, natal_chart}.dart` · `fixtures/natal_chart_fixture.dart` · `presentation/{astrology_screen, natal_chart_painter}.dart` | `ASTROLOGY-001` |
| `horoscope/` | `application/horoscope_providers.dart` · `data/horoscope_repository.dart` · `domain/horoscope.dart` · `fixtures/horoscope_fixture.dart` · `presentation/today_screen.dart` | `TODAY-001` |
| `compatibility/` | `application/compatibility_providers.dart` · `data/synastry_repository.dart` · `domain/synastry_result.dart` · `fixtures/synastry_fixture.dart` · `presentation/match_screen.dart` | `MATCH-001` |
| `friends/` | `presentation/friend_screen.dart` 만 존재 (도메인/데이터 계층 없음) | `FRIEND-001` |
| `content/` | `presentation/random_question_screen.dart` 만 존재 | `CONTENT-001` |
| `profile/` | `presentation/my_page_screen.dart` 만 존재 | `MYPAGE-001` |

**아직 코드 자체가 없는 화면**: `SHARE-001`(공유). README에는 적혀 있으나 디렉토리/파일이 없습니다.

## 3. 데이터 / 상태 흐름

### 3.1 화면 진입 흐름 (확실)

`main.dart` → `Env.load()` → `ProviderScope` → `app.dart` → `LoginScreen`(`LOGIN-001`)
→ “시작하기” 버튼 → `OnboardingScreen`(`ONBOARDING-001`) `pushReplacement`
→ 입력값을 `currentBirthInfoProvider`(StateProvider)에 set + `myNatalChartProvider` invalidate
→ `AppShell`(하단 4탭: 홈/랜덤질문/오늘운세/마이페이지)
→ 홈에서 행성 아이콘 탭 시 `AstrologyScreen` 진입.

### 3.2 Riverpod Provider 전체 그래프

`features/astrology/application/astrology_providers.dart`가 사실상 앱 전체의 DI 루트입니다.

```
prokeralaTokenRepoProvider           // Provider<ProkeralaTokenRepository>
        │
        ▼ tokenProvider 콜백
prokeralaDioProvider                 // Provider<Dio> (인터셉터 부착)
        │
        ▼
prokeralaApiProvider                 // Provider<ProkeralaApi> (저수준 wrapper)
        │
        ├── astrologyRepositoryProvider
        │           │
        │           └── natalChartProvider.family<NatalChart, BirthInfo>
        │                        ↑
        │           myNatalChartProvider (현재 사용자 단축)
        │
        ├── horoscopeRepositoryProvider → todayHoroscopeProvider
        │                                  ↑ selectedSignSlugProvider
        │
        └── synastryRepositoryProvider → synastryProvider.family<…, PartnerPair>

currentBirthInfoProvider            // StateProvider<BirthInfo>  (앱 전역 사용자 출생정보)
```

확실하지 않음: `currentBirthInfoProvider`는 메모리 전용으로, 앱 종료 시 초기화됩니다. README/WEEK9.md에 따르면 **10주차에 Firestore와 연결**할 예정입니다.

### 3.3 외부 API 계약 (Prokerala)

`features/astrology/data/prokerala_api.dart`에서 호출하는 엔드포인트:

| 메서드 | HTTP / 경로 | 비고 |
| --- | --- | --- |
| `fetchNatalChart` | `GET /v2/astrology/natal-chart` | profile[datetime]+coordinates+ayanamsa=0+la=en. 코드 주석에 “경로/파라미터는 공식 문서 기반 추정” 명시. |
| `fetchPlanetPosition` | `GET /v2/astrology/planet-position` | Big 3 추출용. **현재 호출처 없음 — 정의만 되어 있음**. |
| `fetchDailyHoroscope` | `GET /v2/horoscope/daily` | sign=slug, datetime UTC, la=en. |
| `fetchSynastry` | `GET /v2/astrology/synastry-chart` | 두 사람 profile/partner_profile. |
| (별도) 토큰 발급 | `POST {PROKERALA_TOKEN_URL}` | `prokeralaTokenRepository`에서 client_credentials, 메모리 캐시, 만료 60초 전 자동 갱신, in-flight 중복 발급 차단. |

**모든 Repository가 동일한 fallback 패턴**을 가집니다: `kDebugMode && Env.useFixtureInDebug` ⇒ fixture 즉시 반환 / 실호출 실패 ⇒ catch 후 fixture 반환. 즉 **API가 죽어도 화면은 데모 데이터로 채워져 깨지지 않습니다.**

## 4. 데이터베이스 / 저장소 현황

| 계층 | 현재 상태 |
| --- | --- |
| 로컬 영속화 | **없음**. `shared_preferences`/`flutter_secure_storage`/`hive` 등 모두 미도입. |
| 원격 DB | **없음**. Firestore/RDBMS/자체 백엔드 모두 미도입. |
| 캐시 | Prokerala OAuth2 access_token만 메모리 캐시. natal/horoscope/synastry 결과는 Riverpod의 `FutureProvider` 캐시(앱 수명 동안만)만 존재. |

확실하지 않음: README의 “API 연결 계획”표에 Firestore 컬렉션 후보(`users`, `friendRequests`, `friendships`, `charts`, `dailyFortunes`)가 적혀 있지만 **스키마/마이그레이션/DAO 코드는 아직 0**입니다.

## 5. 설정 / 환경 변수 / 빌드

- `.env` 키: `PROKERALA_CLIENT_ID`, `PROKERALA_CLIENT_SECRET`, `PROKERALA_BASE_URL`(기본값 https://api.prokerala.com), `PROKERALA_TOKEN_URL`(기본값 https://api.prokerala.com/token), `USE_FIXTURE_IN_DEBUG`(기본 false).
- `.env`는 `.gitignore` 처리되어 있고, `.env.example`이 템플릿으로 커밋됨. `pubspec.yaml`의 `assets`에 `.env`를 등록해 런타임에 로드.
- 안드로이드 패키지명: `com.example.stellara` (README 기준).
- 빌드 검증 명령(README 기준): `flutter analyze`, `flutter test`, `flutter build apk --debug`, `flutter build web` — 통과 확인됨.

## 6. 테스트 현황

`test/` 폴더에 두 개:

1. `widget_test.dart` — `LoginScreen` 첫 화면 렌더링 smoke test (텍스트 4개 존재 검증).
2. `astrology_repository_test.dart` — fixture(`demoNatalChart` / `demoHoroscope` / `demoSynastry`) 형태 검증만. **실제 `_parseNatalChart`/`_scoreFromJson` 등 매핑 로직은 private이라 미검증** (코드 주석에 “응답 모양 확정 후 `@visibleForTesting`으로 노출 예정” 명시).

통합/네트워크/HTTP mock 테스트는 없습니다.

## 7. 구현된 기능 vs 비어 있는 기능 (SDD 표 그대로 사용 가능)

| 기능 | 상태 | 근거 |
| --- | --- | --- |
| 흑백 디자인 시스템 (Theme/Panel/Skeleton 등) | **구현됨** | `core/theme`, `core/widgets/panel.dart` |
| 환경 변수 로딩 + 누락 시 안내 화면 | **구현됨** | `core/env/env.dart`, `main.dart` |
| Prokerala OAuth2 토큰 발급/갱신/캐시 | **구현됨** | `prokeralaTokenRepository.dart` |
| Prokerala 호출용 Dio 인터셉터 (Auth/Retry/Log) | **구현됨** | `core/http/dio_client.dart` |
| 나탈 차트 fetch + JSON→도메인 매핑 + fixture fallback | **부분 구현** | `astrology_repository.dart`. 응답 키 매핑은 “문서 기반 추정”이라 첫 실호출 검증 필요(코드 주석 TODO). |
| 출생 차트 360° 시각화 | **구현됨** | `natal_chart_painter.dart` (CustomPainter). |
| Daily Horoscope fetch + fallback | **구현됨(추정 매핑)** | `horoscope_repository.dart` |
| Synastry fetch + 4축 점수 휴리스틱 | **구현됨(휴리스틱)** | `synastry_repository.dart`. 어스펙트 가중치는 임의값이라 추후 정교화 예정. |
| 화면 프로토타입 9종 (LOGIN/ONBOARDING/MAIN/ASTROLOGY/TODAY/MATCH/FRIEND/CONTENT/MYPAGE) | **구현됨(목업 위주)** | `features/*/presentation/*.dart` |
| 하단 4탭 네비게이션 | **구현됨** | `onboarding/app_shell.dart` |
| 카카오 OAuth 로그인 | **미구현** | `kakao_flutter_sdk_user` 미설치, `LoginScreen`은 “데모 데이터로 시작” 버튼 1개. |
| 회원/세션/JWT 저장 | **미구현** | `flutter_secure_storage` 미설치. |
| Firebase / Firestore 연동 | **미구현** | 패키지/`google-services.json` 등 없음. |
| 친구 검색·요청·즐겨찾기·랜덤 코드 | **미구현** | `friends/presentation/friend_screen.dart`만 정적 UI. data/domain 폴더 자체 없음. |
| 출생지 주소 → 좌표 변환 | **미구현** | `geocoding` 패키지만 등록. 실제 호출 코드 없음. 입력 화면은 텍스트로만 받고 좌표는 `BirthInfo.demo()`(서울)로 폴백 — 확실하지 않음(폴백 로직 자체는 코드 주석/README 기반 추정). |
| AI 랜덤 질문 / 성격 리포트 | **미구현** | `random_question_screen.dart`는 정적 카드, OpenAI 등 클라이언트 없음. |
| 결과 공유(스크린샷/SNS) | **미구현** | `SHARE-001` 화면 자체 없음. `screenshot`/`share_plus` 미설치. |
| 푸시 알림(FCM/Local) | **미구현** | 패키지 없음. |
| 선언적 라우팅 / 딥링크 | **미구현** | `go_router` 미설치, 현재는 `Navigator.push` 직접 호출. |
| 결과 캐싱 / 차트 버전 관리 | **미구현** | Riverpod의 in-memory 캐시만 존재. |
| 다크 모드 / 컬러 테마 | **미구현(의도적 보류)** | WEEK9.md “13주차 복구 예정”. |
| 통합 테스트 / Repository 매핑 단위 테스트 | **미구현** | private 매핑 로직 미노출. |

## 8. 코드 안의 “위험/주의” 메모 (SDD의 ‘제약/리스크’ 절에 활용 가능)

1. **Prokerala 응답 키 매핑이 추정값**입니다. `prokeralaApi.fetchNatalChart` 주석과 `_parseNatalChart` 주석 모두 “첫 실호출 후 보정 필요(TODO)”로 명시. SDD에는 “응답 스키마 검증 단계 필요”로 적어두는 것이 안전합니다.
2. **Synastry 4축 점수는 휴리스틱**(어스펙트 종류별 가중치). 점성술 일반 통념 기반 임의값이라고 코드 주석에 명시.
3. **client_secret이 앱 바이너리에 포함**되는 구조입니다(현재 9주차 단계 결정). README와 코드 주석 모두 “공개 배포용 구조는 아님”을 전제로 봐야 하며, SDD에는 “학교 데모용 내부 빌드 한정” 운영 원칙을 명시하는 편이 안전합니다.
4. **Prokerala 제약 메모**: 실호출 실패나 응답 차이는 fixture fallback 으로 흡수하고 있지만, `1월 1일만 허용` 같은 제한은 공식 문서로 확인된 규칙이 아니므로 사실처럼 전제하지 않는 편이 안전합니다.
5. **사용자 데이터 영속성 0**. 앱을 재실행하면 출생정보·친구·즐겨찾기·운세 캐시가 모두 사라집니다. SDD의 “데이터 모델/생명주기” 절에 반드시 반영 필요.
6. **`SHARE-001` 화면 미존재**: 기획서에는 있지만 코드에는 없음 → SDD의 화면 매트릭스에서 “구현 보류” 또는 “Phase 2”로 분류 권장.

## 9. SDD에 그대로 인용해도 좋은 짧은 설명문 4개

- **시스템 개요**: “Stellara는 출생 정보 기반 점성술 분석을 제공하는 Flutter 모바일/웹 앱이다. 현재 단계에서는 자체 백엔드 없이 Prokerala Astrology API를 클라이언트가 직접 호출하며, 인증·DB·AI 생성 기능은 향후 단계에서 도입할 계획이다.”
- **아키텍처 스타일**: “기능별(feature-first) 폴더링 + 레이어드(`application`/`data`/`domain`/`fixtures`/`presentation`) 구조이며, 의존 방향은 `presentation → application → data → domain`으로 단방향이다. 횡단 관심사(테마, HTTP, env, 알림)는 `lib/core` 아래에 모인다.”
- **상태 관리**: “Riverpod 2의 `Provider`/`FutureProvider`/`StateProvider`만 사용하며, 코드 생성 어노테이션(`@riverpod`)은 도입 보류 상태이다. 화면이 `myNatalChartProvider`/`todayHoroscopeProvider`/`synastryProvider`를 watch하면 Repository → Prokerala API 호출이 트리거된다.”
- **회복 탄력성**: “모든 외부 API 호출은 ‘fixture fallback’ 패턴을 갖는다 — 디버그 모드에서 `USE_FIXTURE_IN_DEBUG=true`이면 네트워크를 타지 않고 데모 응답을 반환하며, 실호출이 실패해도 사용자는 빈 화면 대신 데모 차트를 본다.”

## 10. 분석 시 확인하지 못해 “확실하지 않음”으로 둔 것

- `assets/` 폴더는 존재하지만 `find` 결과 파일이 0건이었습니다. 추후 이미지/Lottie 자산 위치는 별도 확인 필요.
- `geocoding` 패키지가 어떤 화면에서 호출될 예정인지(추정: 온보딩 화면의 출생지 입력란)는 코드에서 직접 호출처를 찾지 못했습니다. README 기준의 “계획”입니다.
- `_AstrologyProviders`의 코드 생성기(`riverpod_generator`)는 `dev_dependencies`에 등록되어 있으나, 실제 `*.g.dart` 산출물은 분석 시점에 없었습니다. 즉 현재는 **수기 작성 Provider만 사용**.
- `test/astrology_repository_test.dart`라는 파일명에도 불구하고 실제로는 fixture 검사용 라이트 테스트라는 점.
- 친구/마이페이지/랜덤질문 화면의 “목업 데이터”가 어디에 정의되어 있는지는 화면 파일 내부에 하드코딩된 값으로 추정됩니다(전수 확인은 하지 않았습니다).

---

위 자료를 바탕으로 SDD 초안의 §1 시스템 개요, §2 아키텍처, §3 모듈 명세, §4 데이터 모델, §5 외부 인터페이스, §6 비기능 요구사항, §7 구현 현황 및 후속 작업 목록을 채울 수 있습니다.
