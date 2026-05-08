# Stellara — 개발 작업 분해

> 기준 문서: `docs/SDD.md` v0.4, `docs/MVP.md`  
> 목적: 협업자가 바로 가져갈 수 있는 이슈 단위로 개발 작업을 분해한다.

## Phase 1 — 기반 안정화 / 백엔드 전환

## T01. Prokerala 실응답 수집 및 fixture 갱신
- 작업명: Prokerala 실응답 수집 및 fixture 갱신
- 목적: 현재 추정 기반인 응답 계약을 실제 응답 기준으로 고정한다.
- 구현 범위: `natal-chart`, `daily`, `synastry` 실응답을 1회씩 확보하고, 현재 fixture 데이터와 문서의 리스크 메모를 갱신한다.
- 수정 예상 파일: `docs/SDD.md`, `docs/MVP.md`, `docs/SDD_input_codebase_overview.md`, `lib/features/astrology/fixtures/natal_chart_fixture.dart`, `lib/features/horoscope/fixtures/horoscope_fixture.dart`, `lib/features/compatibility/fixtures/synastry_fixture.dart`
- 완료 기준: 세 API의 raw 응답 샘플이 확보되고, fixture가 실제 응답 형태와 어긋나지 않게 정리되어 있다.
- 선행 작업: 없음
- 담당 가능 역할: 공통

## T02. Natal parser 안정화
- 작업명: Natal parser 안정화
- 목적: `AstrologyRepository` 의 JSON 매핑을 실제 응답 기준으로 보정한다.
- 구현 범위: `planet_position`, `houses`, `aspects`, `ascendant` 키를 검증하고 `_parseNatalChart` 의 방어 로직을 정리한다.
- 수정 예상 파일: `lib/features/astrology/data/astrology_repository.dart`, `lib/features/astrology/data/prokerala_api.dart`, `test/astrology_repository_test.dart`
- 완료 기준: 실제 natal 응답으로 `NatalChart` 가 안정적으로 생성되고, `sunSign`, `moonSign`, `ascendantSign` 값이 기대대로 매핑된다.
- 선행 작업: `T01`
- 담당 가능 역할: 공통

## T03. Horoscope parser 안정화
- 작업명: Horoscope parser 안정화
- 목적: 일일 운세 응답의 키 이름 차이로 인한 화면 깨짐을 방지한다.
- 구현 범위: `horoscope`, `summary`, `prediction`, `lucky_color`, `lucky_number`, `mood` 매핑을 실제 응답 기준으로 보정한다.
- 수정 예상 파일: `lib/features/horoscope/data/horoscope_repository.dart`, `lib/features/astrology/data/prokerala_api.dart`, `test/astrology_repository_test.dart`
- 완료 기준: 실제 horoscope 응답으로 `Horoscope` 가 안정적으로 생성되고, fallback 없이 화면이 채워진다.
- 선행 작업: `T01`
- 담당 가능 역할: 공통

## T04. Synastry parser 및 점수 baseline 안정화
- 작업명: Synastry parser 및 점수 baseline 안정화
- 목적: 궁합 결과가 실제 어스펙트 응답을 기준으로 계산되도록 만든다.
- 구현 범위: `aspects` 응답 구조를 검증하고, 현재 휴리스틱 점수 산식을 최소한의 baseline으로 정리한다.
- 수정 예상 파일: `lib/features/compatibility/data/synastry_repository.dart`, `lib/features/astrology/data/prokerala_api.dart`, `test/astrology_repository_test.dart`
- 완료 기준: 실제 synastry 응답으로 `SynastryResult` 가 생성되고, 점수 계산이 예외 없이 동작한다.
- 선행 작업: `T01`
- 담당 가능 역할: 공통

## T05. Flutter Firebase bootstrap
- 작업명: Flutter Firebase bootstrap
- 목적: 앱에서 Firestore 기반 저장 흐름을 시작할 수 있는 최소 환경을 만든다.
- 구현 범위: `firebase_core`, `cloud_firestore`, `flutter_secure_storage` 의존성 추가, Firebase 초기화, 플랫폼 설정 반영.
- 수정 예상 파일: `pubspec.yaml`, `lib/main.dart`, `android/app/build.gradle.kts`, `android/build.gradle.kts`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`
- 완료 기준: 앱이 Firebase 초기화에 성공하고, 런타임 에러 없이 실행된다.
- 선행 작업: 없음
- 담당 가능 역할: 공통

## T06. Cloud Functions 스캐폴드 및 secret 이관
- 작업명: Cloud Functions 스캐폴드 및 secret 이관
- 목적: 앱에서 Prokerala secret 을 제거할 준비를 한다.
- 구현 범위: `functions/` 초기 구조 생성, Node/TypeScript 설정, Prokerala secret 환경 변수 정의, 공통 에러 응답 형식 정리.
- 수정 예상 파일: `functions/package.json`, `functions/tsconfig.json`, `functions/src/index.ts`, `functions/src/config.ts`, `docs/SDD.md`
- 완료 기준: Functions 프로젝트가 빌드 가능하고, secret 을 앱 `.env` 대신 Functions 설정으로 관리할 수 있다.
- 선행 작업: 없음
- 담당 가능 역할: BE

## T07. `places-resolve` Function 구현
- 작업명: 출생지 좌표 변환 Function 구현
- 목적: 서울/부산 하드코딩 폴백을 제거하고 실제 좌표를 저장한다.
- 구현 범위: 출생지 텍스트를 좌표로 변환하는 `places-resolve` API 구현, 실패 시 표준 에러 응답 또는 fallback 전략 정의.
- 수정 예상 파일: `functions/src/index.ts`, `functions/src/places_resolve.ts`, `docs/SDD.md`
- 완료 기준: `"서울특별시"` 같은 입력으로 `placeName`, `latitude`, `longitude` 가 반환된다.
- 선행 작업: `T06`
- 담당 가능 역할: BE

## T08. 온보딩 출생지 좌표 연동
- 작업명: 온보딩 출생지 좌표 연동
- 목적: 사용자가 입력한 출생지가 실제 `BirthInfo` 좌표로 반영되게 한다.
- 구현 범위: 온보딩 제출 시 `places-resolve` 호출, `BirthInfo` 에 `dateTimeLocal + utcOffset + lat/lng` 저장 규칙 반영, 실패 메시지 처리.
- 수정 예상 파일: `lib/features/onboarding/presentation/onboarding_screen.dart`, `lib/features/astrology/domain/birth_info.dart`, `lib/core/http/dio_client.dart`
- 완료 기준: 온보딩에서 입력한 출생지가 실제 좌표로 저장되고, 서울/부산 고정값을 기본 경로에서 사용하지 않는다.
- 선행 작업: `T05`, `T07`
- 담당 가능 역할: FE

## T09. Firestore 스키마 초안 반영 및 시딩 데이터 준비
- 작업명: Firestore 스키마 초안 반영 및 시딩 데이터 준비
- 목적: `users`, `charts`, `friendCodes` 의 초기 문서 구조를 팀이 바로 사용할 수 있게 한다.
- 구현 범위: 문서형 스키마 확정, 팀원용 샘플 uid/출생정보/친구코드 정리, 시딩 절차 문서화.
- 수정 예상 파일: `docs/SDD.md`, `docs/MVP.md`, `docs/TASKS.md`
- 완료 기준: 팀원이 Firebase Console 기준으로 같은 구조의 테스트 데이터를 수동 생성할 수 있다.
- 선행 작업: `T05`
- 담당 가능 역할: 공통

## T10. 개발 모드 로그인 진입
- 작업명: 개발 모드 로그인 진입
- 목적: 카카오 로그인 없이도 Firestore 사용자로 앱에 진입할 수 있게 한다.
- 구현 범위: `LoginScreen` 에 uid 선택 또는 입력 기반 개발 모드 진입 추가, Firestore 사용자 존재 여부 확인.
- 수정 예상 파일: `lib/features/auth/presentation/login_screen.dart`, `lib/app.dart`, `lib/features/astrology/application/astrology_providers.dart`
- 완료 기준: 테스트 uid로 로그인 화면에서 바로 `AppShell` 로 진입할 수 있다.
- 선행 작업: `T05`, `T09`
- 담당 가능 역할: FE

## T11. `currentBirthInfoProvider` Firestore 연동
- 작업명: 현재 사용자 출생정보 Firestore 연동
- 목적: 앱 재실행 후에도 출생정보가 유지되게 한다.
- 구현 범위: Firestore에서 `users/{uid}.birthInfo` 를 읽고 `currentBirthInfoProvider` 와 연결, 초기 fetch 또는 stream 구조 선택.
- 수정 예상 파일: `lib/features/astrology/application/astrology_providers.dart`, `lib/features/astrology/domain/birth_info.dart`, `lib/main.dart`
- 완료 기준: 앱을 재실행해도 마지막 저장된 출생정보가 다시 로드된다.
- 선행 작업: `T05`, `T09`, `T10`
- 담당 가능 역할: 공통

## T12. `prokerala-natal` Function 및 차트 캐시 구현
- 작업명: 나탈 차트 Function 및 차트 캐시 구현
- 목적: Prokerala secret 을 서버로 옮기고 `chartVersion` 기반 캐시를 만든다.
- 구현 범위: `prokerala-natal` API 구현, Prokerala 호출, `charts/{uid}` 저장, `chartVersion` 생성, raw snapshot 임시 저장.
- 수정 예상 파일: `functions/src/index.ts`, `functions/src/prokerala_natal.ts`, `docs/SDD.md`
- 완료 기준: 동일한 `birthInfo` 로 재호출 시 캐시가 동작하고, `charts/{uid}` 문서가 생성된다.
- 선행 작업: `T06`, `T09`
- 담당 가능 역할: BE

## T13. Flutter 나탈 데이터 경로 Functions 로 이관
- 작업명: Flutter 나탈 데이터 경로 Functions 로 이관
- 목적: 앱이 더 이상 Prokerala 직접 호출에 의존하지 않게 한다.
- 구현 범위: `ProkeralaApi` 또는 `AstrologyRepository` 가 `prokerala-natal` 응답을 사용하도록 교체하고, `NatalChart` 정규화 응답에 맞춰 조정한다.
- 수정 예상 파일: `lib/features/astrology/data/prokerala_api.dart`, `lib/features/astrology/data/astrology_repository.dart`, `lib/features/astrology/application/astrology_providers.dart`
- 완료 기준: 앱에서 나탈 차트가 Cloud Functions 경유로 정상 조회된다.
- 선행 작업: `T12`
- 담당 가능 역할: 공통

## T14. `prokerala-horoscope` Function 및 운세 캐시 구현
- 작업명: 일일 운세 Function 및 운세 캐시 구현
- 목적: 운세 조회를 서버 경유로 전환하고 날짜별 캐시를 만든다.
- 구현 범위: `prokerala-horoscope` API 구현, Prokerala 호출, `dailyFortunes/{uid}_{signSlug}_{yyyyMMdd}` 저장, force refresh 전략 정의.
- 수정 예상 파일: `functions/src/index.ts`, `functions/src/prokerala_horoscope.ts`, `docs/SDD.md`
- 완료 기준: 같은 날짜/같은 별자리 재호출 시 Firestore 캐시를 재사용한다.
- 선행 작업: `T06`, `T09`
- 담당 가능 역할: BE

## T15. Flutter 운세 데이터 경로 Functions 로 이관
- 작업명: Flutter 운세 데이터 경로 Functions 로 이관
- 목적: `TODAY-001` 이 서버 경유 캐시 응답을 사용하게 한다.
- 구현 범위: `HoroscopeRepository` 와 `todayHoroscopeProvider` 를 `prokerala-horoscope` 응답 형식으로 교체하고, 로딩/에러 상태를 정리한다.
- 수정 예상 파일: `lib/features/horoscope/data/horoscope_repository.dart`, `lib/features/horoscope/application/horoscope_providers.dart`, `lib/features/horoscope/presentation/today_screen.dart`
- 완료 기준: 오늘의 운세 화면이 Cloud Functions 응답으로 정상 렌더링된다.
- 선행 작업: `T14`
- 담당 가능 역할: FE

## Phase 2 — 친구 / 궁합 / 홈 실데이터 연결

## T16. 친구 코드 발급 및 검색 백엔드
- 작업명: 친구 코드 발급 및 검색 백엔드
- 목적: `friendCode` 유일성과 빠른 검색을 보장한다.
- 구현 범위: `friendCodes/{code}` 인덱스 설계, 코드 발급/재발급 로직, 코드 검색 규칙 정리.
- 수정 예상 파일: `functions/src/index.ts`, `functions/src/friend_code_issue.ts`, `docs/SDD.md`
- 완료 기준: 중복 없는 친구 코드가 발급되고, 코드로 사용자 검색이 가능하다.
- 선행 작업: `T06`, `T09`
- 담당 가능 역할: BE

## T17. 친구 요청 전송 흐름 구현
- 작업명: 친구 요청 전송 흐름 구현
- 목적: FRIEND-001 에서 실제 요청 생성이 가능하게 한다.
- 구현 범위: 친구 코드 입력, 코드 검색, `friendRequests` 문서 생성, 요청 중복 방지 UI 처리.
- 수정 예상 파일: `lib/features/friends/presentation/friend_screen.dart`, `lib/features/friends/application/friend_providers.dart`, `lib/features/friends/data/friend_repository.dart`, `lib/features/friends/domain/friend_request.dart`
- 완료 기준: 코드 입력 후 친구 요청이 Firestore 또는 백엔드 경유로 생성된다.
- 선행 작업: `T16`, `T10`
- 담당 가능 역할: 공통

## T18. 친구 요청 수락 트랜잭션 구현
- 작업명: 친구 요청 수락 트랜잭션 구현
- 목적: 요청 수락 시 `friendships` 와 요청 상태가 일관되게 갱신되게 한다.
- 구현 범위: `friend-request-accept` Function 또는 Firestore transaction 구현, `pairKey` 생성 규칙 반영, 중복 friendship 방지.
- 수정 예상 파일: `functions/src/index.ts`, `functions/src/friend_request_accept.ts`, `docs/SDD.md`
- 완료 기준: 요청 수락 시 `friendRequests.status=accepted` 와 `friendships/{pairKey}` 생성이 한 번에 처리된다.
- 선행 작업: `T16`, `T17`
- 담당 가능 역할: BE

## T19. 친구 목록 및 즐겨찾기 연동
- 작업명: 친구 목록 및 즐겨찾기 연동
- 목적: 정적 UI인 FRIEND-001 과 MAIN-001 을 실데이터와 연결한다.
- 구현 범위: 친구 목록 조회, 받은 요청 표시, 수락 액션 연결, `favoriteIds` 최대 3명 제한 반영.
- 수정 예상 파일: `lib/features/friends/presentation/friend_screen.dart`, `lib/features/home/presentation/main_home_screen.dart`, `lib/features/friends/application/friend_providers.dart`, `lib/features/friends/data/friend_repository.dart`
- 완료 기준: 친구 목록이 실데이터로 표시되고 즐겨찾기 3명 제한이 동작한다.
- 선행 작업: `T17`, `T18`
- 담당 가능 역할: FE

## T20. `prokerala-synastry` Function 및 궁합 캐시 구현
- 작업명: 궁합 Function 및 궁합 캐시 구현
- 목적: 궁합 계산을 서버 경유로 전환하고 `chartPairVersion` 기반 캐시를 만든다.
- 구현 범위: `prokerala-synastry` API 구현, 두 사용자 birthInfo 비교, Prokerala 호출, `synastryCaches/{pairKey}_{chartPairVersion}` 저장.
- 수정 예상 파일: `functions/src/index.ts`, `functions/src/prokerala_synastry.ts`, `docs/SDD.md`
- 완료 기준: 같은 쌍/같은 차트 버전 재조회 시 캐시가 재사용된다.
- 선행 작업: `T06`, `T09`, `T12`
- 담당 가능 역할: BE

## T21. MATCH-001 실친구 기반 연동
- 작업명: MATCH-001 실친구 기반 연동
- 목적: 현재 직접 입력형 궁합 화면을 친구 선택 기반 흐름으로 바꾼다.
- 구현 범위: 친구 목록에서 상대 선택, 상대 birthInfo 로 synastry 호출, 결과 화면 로딩/에러/캐시 흐름 정리.
- 수정 예상 파일: `lib/features/compatibility/presentation/match_screen.dart`, `lib/features/compatibility/application/compatibility_providers.dart`, `lib/features/compatibility/data/synastry_repository.dart`, `lib/features/friends/presentation/friend_screen.dart`
- 완료 기준: 친구를 선택해 궁합 점수를 조회할 수 있다.
- 선행 작업: `T19`, `T20`
- 담당 가능 역할: 공통

## Phase 3 — AI / 운세 고도화 / 후반부 준비

## T22. `ai-questions` Function 구현
- 작업명: AI 질문 생성 Function 구현
- 목적: 랜덤 질문 3개를 백엔드에서 안전하게 생성한다.
- 구현 범위: OpenAI 호출, 프롬프트 고정, 응답 정규화, 실패 시 fallback 문구 전략 정의.
- 수정 예상 파일: `functions/src/index.ts`, `functions/src/ai_questions.ts`, `docs/SDD.md`
- 완료 기준: 요청 시 질문 3개가 일관된 JSON 형식으로 반환된다.
- 선행 작업: `T06`
- 담당 가능 역할: BE

## T23. CONTENT-001 실데이터 연동
- 작업명: 랜덤 질문 화면 실데이터 연동
- 목적: 정적 카드 UI를 실제 AI 질문 호출 화면으로 바꾼다.
- 구현 범위: `ai-questions` 호출, 질문 3개 표시, 사용자 직접 질문 1개 입력, 재생성 버튼 상태 처리.
- 수정 예상 파일: `lib/features/content/presentation/random_question_screen.dart`, `lib/features/content/application/question_providers.dart`, `lib/features/content/data/question_repository.dart`
- 완료 기준: 화면에서 AI 질문 3개가 생성되어 보이고 재요청이 가능하다.
- 선행 작업: `T22`
- 담당 가능 역할: FE

## T24. SHARE-001 와이어프레임 및 디자인 토큰 선행 준비
- 작업명: SHARE-001 와이어프레임 및 디자인 토큰 선행 준비
- 목적: 공유/디자인 작업이 13주차에 몰리지 않도록 구조를 먼저 고정한다.
- 구현 범위: 공유 카드 레이아웃 초안, 컬러 토큰 초안, 모션/Lottie 적용 후보 정리, 디자인 가이드 문서화.
- 수정 예상 파일: `docs/SDD.md`, `docs/MVP.md`, `lib/core/theme/app_theme.dart`, `lib/core/widgets/panel.dart`
- 완료 기준: 공유 카드 형태와 후반부 디자인 적용 기준이 문서와 토큰 수준에서 정리되어 있다.
- 선행 작업: `T13`, `T15`
- 담당 가능 역할: FE

## Phase 4 — 공유 / 디자인 마감 / 마이페이지

## T25. SHARE-001 구현
- 작업명: SHARE-001 구현
- 목적: 운세/궁합/나탈 차트 결과를 실제 이미지 공유 가능한 화면으로 만든다.
- 구현 범위: 공유 화면 생성, 결과 카드 렌더링, `screenshot` 기반 캡처, `share_plus` 호출 연결.
- 수정 예상 파일: `pubspec.yaml`, `lib/features/share/presentation/share_screen.dart`, `lib/features/compatibility/presentation/match_screen.dart`, `lib/features/horoscope/presentation/today_screen.dart`, `lib/features/astrology/presentation/astrology_screen.dart`
- 완료 기준: 결과 카드가 이미지로 캡처되고 SNS 공유 시트가 열린다.
- 선행 작업: `T24`
- 담당 가능 역할: FE

## T26. 후반부 디자인 폴리시 반영
- 작업명: 후반부 디자인 폴리시 반영
- 목적: 흑백 프로토타입을 발표 가능한 시각 완성도로 끌어올린다.
- 구현 범위: 컬러 토큰 반영, 주요 화면 타이포/간격 정리, Lottie 적용 가능 지점 반영, 과한 범위 확장 없이 핵심 화면 위주로 마감.
- 수정 예상 파일: `lib/core/theme/app_theme.dart`, `lib/features/home/presentation/main_home_screen.dart`, `lib/features/astrology/presentation/astrology_screen.dart`, `lib/features/compatibility/presentation/match_screen.dart`, `lib/features/share/presentation/share_screen.dart`
- 완료 기준: 홈/차트/궁합/공유 핵심 화면의 디자인 톤이 일관되고, 후반부 연출 요소가 과밀 일정 없이 반영된다.
- 선행 작업: `T24`
- 담당 가능 역할: FE

## T27. 마이페이지 출생정보 수정 및 차트 무효화
- 작업명: 출생정보 수정 및 차트 무효화
- 목적: 마이페이지 수정이 실제 Firestore 데이터와 차트 재계산으로 이어지게 한다.
- 구현 범위: `MYPAGE-001` 수정 액션 저장, `users.birthInfo` 갱신, `activeChartVersion`/`charts` stale 처리, 재조회 트리거.
- 수정 예상 파일: `lib/features/profile/presentation/my_page_screen.dart`, `lib/features/onboarding/presentation/onboarding_screen.dart`, `lib/features/astrology/application/astrology_providers.dart`, `functions/src/prokerala_natal.ts`
- 완료 기준: 출생정보 수정 후 차트와 궁합 캐시가 새 버전 기준으로 다시 계산된다.
- 선행 작업: `T11`, `T12`, `T20`
- 담당 가능 역할: 공통

## Phase 5 — 테스트 / 회귀 / 발표 준비

## T28. 매핑 테스트 및 회귀 점검 보강
- 작업명: 매핑 테스트 및 회귀 점검 보강
- 목적: 파서/캐시/핵심 흐름의 회귀를 빠르게 잡을 수 있게 한다.
- 구현 범위: natal/horoscope/synastry 매핑 테스트 추가, 주요 provider smoke test 보강, fixture fallback 회귀 확인.
- 수정 예상 파일: `test/astrology_repository_test.dart`, `test/widget_test.dart`, `docs/SDD.md`
- 완료 기준: 핵심 매핑과 최소 화면 진입 테스트가 자동화되어 있다.
- 선행 작업: `T02`, `T03`, `T04`, `T13`, `T15`, `T21`
- 담당 가능 역할: 공통

## T29. 데모 체크리스트 및 발표 시나리오 정리
- 작업명: 데모 체크리스트 및 발표 시나리오 정리
- 목적: 발표 직전 확인해야 할 흐름과 계정을 한 번에 점검할 수 있게 한다.
- 구현 범위: 데모 사용자 목록, 시연 순서, 실패 시 fallback 시나리오, 환경 준비 순서 문서화.
- 수정 예상 파일: `README.md`, `docs/MVP.md`, `docs/TASKS.md`
- 완료 기준: 출생정보 입력 → 운세 확인 → 친구 궁합 → 공유 흐름의 발표 체크리스트가 문서로 정리되어 있다.
- 선행 작업: `T25`, `T26`, `T27`, `T28`
- 담당 가능 역할: 공통
