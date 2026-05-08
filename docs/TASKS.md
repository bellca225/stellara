# Stellara — 개발 작업 분해

> 기준 문서: `docs/SDD.md` v0.9, `docs/MVP.md`  
> 목적: 협업자가 바로 가져갈 수 있는 이슈 단위로 개발 작업을 분해한다.
>
> **2026-05-09 변경**: T16 / T18 / T27 의 Cloud Functions 경로를 제거하고 Firestore `runTransaction`(클라이언트) 으로 단일화. T16.5 (Firestore Security Rules 초안) 신설. 이유와 단점은 `docs/SDD.md` 7.4 마지막 박스 참고.

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

## T06. 무료 플랜 운영 규칙 문서화
- 작업명: 무료 플랜 운영 규칙 문서화
- 목적: Spark-only 전제를 팀이 같은 기준으로 이해하도록 한다.
- 구현 범위: direct Prokerala 호출 허용 범위, multi-key fallback, fixture 기본 전략, 공개 배포 금지 원칙을 README/SDD/MVP에 반영한다.
- 수정 예상 파일: `README.md`, `docs/SDD.md`, `docs/MVP.md`, `docs/README.md`
- 완료 기준: 팀원이 무료 플랜 기준 현재 운영 방식과 제한 사항을 문서만 보고 이해할 수 있다.
- 선행 작업: 없음
- 담당 가능 역할: 공통

## T07. 클라이언트 출생지 좌표 변환 helper 구현
- 작업명: 클라이언트 출생지 좌표 변환 helper 구현
- 목적: 무료 플랜 기준에서 가장 먼저 출생지 정확도를 높인다.
- 구현 범위: Android/iOS `geocoding` 기반 주소→좌표 helper 작성, 한국 입력 보정 쿼리 전략 정리, 실패 시 에러 메시지 정책 확정.
- 수정 예상 파일: `lib/features/onboarding/data/place_resolver.dart`, `docs/SDD.md`
- 완료 기준: `"서울특별시 강남구 역삼동"` 같은 입력으로 실제 위도/경도를 얻을 수 있다.
- 선행 작업: 없음
- 담당 가능 역할: FE

## T08. 온보딩 출생지 좌표 연동
- 작업명: 온보딩 출생지 좌표 연동
- 목적: 사용자가 입력한 출생지가 실제 `BirthInfo` 좌표로 반영되게 한다.
- 구현 범위: 온보딩 제출 시 geocoding helper 호출, `BirthInfo` 에 `dateTimeLocal + utcOffset + lat/lng` 저장 규칙 반영, Web 보조 타깃 안내 문구 처리.
- 수정 예상 파일: `lib/features/onboarding/presentation/onboarding_screen.dart`, `lib/features/astrology/domain/birth_info.dart`
- 완료 기준: Android/iOS 기준 온보딩에서 입력한 출생지가 실제 좌표로 저장되고, 서울 고정값이 기본 경로에서 제거된다.
- 선행 작업: `T07`
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
- 구현 범위: 현재 `시작하기` / `데모 데이터로 둘러보기` 흐름을 유지하면서, 필요 시 테스트 uid 연결 경로를 추가하고 Firestore 사용자 존재 여부를 확인한다.
- 수정 예상 파일: `lib/features/auth/presentation/login_screen.dart`, `lib/app.dart`, `lib/features/astrology/application/astrology_providers.dart`
- 완료 기준: 데모 버튼을 유지한 채 테스트 사용자로 `AppShell` 진입이 가능하다.
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

## T12. 나탈 차트 Firestore 캐시 구현
- 작업명: 나탈 차트 Firestore 캐시 구현
- 목적: 무료 플랜에서 중복 API 호출을 줄이고 `chartVersion` 기반 재사용 구조를 만든다.
- 구현 범위: `charts/{uid}` 저장, `chartVersion` 생성 규칙 적용, raw snapshot 저장 여부 확정, stale 처리 기준 정리.
- 수정 예상 파일: `lib/features/astrology/data/astrology_repository.dart`, `docs/SDD.md`, `docs/MVP.md`
- 완료 기준: 동일한 `birthInfo` 로 재조회 시 캐시 재사용 전략이 문서와 구현에 반영된다.
- 선행 작업: `T05`, `T09`
- 담당 가능 역할: 공통

## T13. Flutter 나탈 데이터 경로 캐시 연동
- 작업명: Flutter 나탈 데이터 경로 캐시 연동
- 목적: direct Prokerala 호출과 Firestore 차트 캐시를 함께 쓰도록 한다.
- 구현 범위: `AstrologyRepository` 와 Provider가 캐시 우선/실호출 fallback 흐름을 따르도록 조정한다.
- 수정 예상 파일: `lib/features/astrology/data/astrology_repository.dart`, `lib/features/astrology/application/astrology_providers.dart`
- 완료 기준: 앱에서 나탈 차트가 캐시 우선 전략으로 정상 조회된다.
- 선행 작업: `T12`
- 담당 가능 역할: 공통

## T14. 일일 운세 Firestore 캐시 구현
- 작업명: 일일 운세 Firestore 캐시 구현
- 목적: 운세 조회를 무료 플랜 범위 안에서 재사용 가능하게 만든다.
- 구현 범위: `dailyFortunes/{uid}_{signSlug}_{yyyyMMdd}` 저장, 같은 날짜/별자리 재호출 시 캐시 우선 전략 정의.
- 수정 예상 파일: `lib/features/horoscope/data/horoscope_repository.dart`, `docs/SDD.md`
- 완료 기준: 같은 날짜/같은 별자리 재호출 시 Firestore 또는 로컬 캐시 재사용 전략이 정리된다.
- 선행 작업: `T05`, `T09`
- 담당 가능 역할: 공통

## T15. Flutter 운세 데이터 경로 캐시 연동
- 작업명: Flutter 운세 데이터 경로 캐시 연동
- 목적: `TODAY-001` 이 direct 호출 + 캐시 조합으로 동작하게 한다.
- 구현 범위: `HoroscopeRepository` 와 `todayHoroscopeProvider` 의 캐시 우선 흐름, 로딩/에러 상태를 정리한다.
- 수정 예상 파일: `lib/features/horoscope/data/horoscope_repository.dart`, `lib/features/horoscope/application/horoscope_providers.dart`, `lib/features/horoscope/presentation/today_screen.dart`
- 완료 기준: 오늘의 운세 화면이 캐시 우선 전략으로 정상 렌더링된다.
- 선행 작업: `T14`
- 담당 가능 역할: FE

## Phase 2 — 친구 / 궁합 / 홈 실데이터 연결

## T16. 친구 코드 발급 및 검색
- 작업명: 친구 코드 발급 및 검색
- 목적: `friendCode` 유일성과 빠른 검색을 보장한다.
- 구현 범위: `friendCodes/{code}` 인덱스 설계, 코드 발급/재발급 로직, 코드 검색 규칙 정리. **Firestore `runTransaction`(클라이언트)** 으로 구현하고, Cloud Functions 경로는 Blaze 전환 시 후속.
- 수정 예상 파일: `lib/features/friends/data/friend_code_repository.dart`, `lib/features/friends/domain/friend_code.dart`, `firestore.rules`, `docs/SDD.md`
- 완료 기준: 중복 없는 친구 코드가 발급되고, 코드로 사용자 검색이 가능하다. 동시 발급 시도에서도 unique 제약이 깨지지 않는다.
- 선행 작업: `T06`, `T09`, `T16.5`
- 담당 가능 역할: 공통

## T16.5. Firestore Security Rules 초안
- 작업명: Firestore Security Rules 초안
- 목적: 클라이언트가 직접 Firestore 에 쓰는 경로를 안전하게 제한한다.
- 구현 범위: `users`, `friendCodes`, `friendRequests`, `friendships`, `charts`, `dailyFortunes`, `synastryCaches` 의 read/write 규칙 작성. 읽기는 본인 또는 friendship 상대만, 쓰기는 본인 또는 트랜잭션 조건만 허용. `friendCodes` 는 발급/재발급 트랜잭션 외에는 쓰기 금지. `favoriteIds.length <= 3` 강제.
- 수정 예상 파일: `firestore.rules`, `docs/SDD.md`
- 완료 기준: emulator(`firebase emulators:start --only firestore`) 또는 콘솔에서 의도된 권한 위반 케이스가 모두 거부된다.
- 선행 작업: `T05`, `T09`
- 담당 가능 역할: 공통

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
- 구현 범위: **Firestore `runTransaction`(클라이언트)** 으로 `friendRequests.status=accepted` 와 `friendships/{pairKey}` 생성을 한 번에 처리. `pairKey` 생성 규칙(`min(uidA,uidB)__max(uidA,uidB)`) 반영, 문서 ID 자체를 `pairKey` 로 두어 중복 friendship 방지. Functions 경로는 Blaze 전환 시 후속.
- 수정 예상 파일: `lib/features/friends/data/friend_repository.dart`, `firestore.rules`, `docs/SDD.md`
- 완료 기준: 요청 수락 시 `friendRequests.status=accepted` 와 `friendships/{pairKey}` 생성이 한 번에 처리된다. 동시 수락 시도에서도 friendship 이 1개만 생성된다.
- 선행 작업: `T16`, `T17`, `T16.5`
- 담당 가능 역할: 공통

## T19. 친구 목록 및 즐겨찾기 연동
- 작업명: 친구 목록 및 즐겨찾기 연동
- 목적: 정적 UI인 FRIEND-001 과 MAIN-001 을 실데이터와 연결한다.
- 구현 범위: 친구 목록 조회, 받은 요청 표시, 수락 액션 연결, `favoriteIds` 최대 3명 제한 반영.
- 수정 예상 파일: `lib/features/friends/presentation/friend_screen.dart`, `lib/features/home/presentation/main_home_screen.dart`, `lib/features/friends/application/friend_providers.dart`, `lib/features/friends/data/friend_repository.dart`
- 완료 기준: 친구 목록이 실데이터로 표시되고 즐겨찾기 3명 제한이 동작한다.
- 선행 작업: `T17`, `T18`
- 담당 가능 역할: FE

## T20. 궁합 캐시 구현
- 작업명: 궁합 캐시 구현
- 목적: `chartPairVersion` 기반으로 Synastry 재호출을 줄인다.
- 구현 범위: 두 사용자 birthInfo 비교, direct Prokerala 호출 결과를 `synastryCaches/{pairKey}|{chartPairVersion}` 구조에 저장하는 전략 정리.
- 수정 예상 파일: `lib/features/compatibility/data/synastry_repository.dart`, `docs/SDD.md`
- 완료 기준: 같은 쌍/같은 차트 버전 재조회 시 캐시 재사용 전략이 문서와 구현에 반영된다.
- 선행 작업: `T09`, `T12`
- 담당 가능 역할: 공통

## T21. MATCH-001 실친구 기반 연동
- 작업명: MATCH-001 실친구 기반 연동
- 목적: 현재 직접 입력형 궁합 화면을 친구 선택 기반 흐름으로 바꾼다.
- 구현 범위: 친구 목록에서 상대 선택, 상대 birthInfo 로 synastry 호출, 결과 화면 로딩/에러/캐시 흐름 정리.
- 수정 예상 파일: `lib/features/compatibility/presentation/match_screen.dart`, `lib/features/compatibility/application/compatibility_providers.dart`, `lib/features/compatibility/data/synastry_repository.dart`, `lib/features/friends/presentation/friend_screen.dart`
- 완료 기준: 친구를 선택해 궁합 점수를 조회할 수 있다.
- 선행 작업: `T19`, `T20`
- 담당 가능 역할: 공통

## Phase 3 — AI / 운세 고도화 / 후반부 준비

## T22. AI provider / env / fallback 정책 정리
- 작업명: AI provider / env / fallback 정책 정리
- 목적: GPT/Claude 연결 시 팀이 같은 기준으로 키, provider, fallback 흐름을 이해하도록 한다.
- 구현 범위: `.env.example` 키 이름 확정, `자동/GPT/Claude` UX 원칙, `OpenAI → Anthropic → local fallback` 기본 순서, `primary → seoyeon → seonwoo → doyeon` backup 규칙을 문서에 반영한다.
- 수정 예상 파일: `.env.example`, `README.md`, `docs/SDD.md`, `docs/MVP.md`, `docs/TASKS.md`
- 완료 기준: 팀원이 문서만 보고 AI 질문의 키 관리 방식과 사용자 노출 정책을 이해할 수 있다.
- 선행 작업: 없음
- 담당 가능 역할: 공통

## T23. CONTENT-001 실데이터 연동
- 작업명: 랜덤 질문 화면 실데이터 연동
- 목적: 정적 카드 UI를 실제 AI 질문 호출 화면으로 바꾸되, 메인 UX는 단순하게 유지한다.
- 구현 범위: `자동(추천) / GPT / Claude` 선택 UI, OpenAI/Anthropic client adapter, provider별 key fallback, local fallback 질문 세트, 질문 3개 표시, 사용자 직접 질문 1개 입력, 재생성 버튼 상태 처리.
- 수정 예상 파일: `lib/features/content/presentation/random_question_screen.dart`, `lib/features/content/application/question_providers.dart`, `lib/features/content/data/question_repository.dart`
- 완료 기준: 화면에서 AI 질문 3개가 생성되어 보이고, 실패 시 local fallback 으로 비어 있지 않으며, 사용자에게는 provider 수준의 선택지만 노출된다.
- 선행 작업: `T22`
- 담당 가능 역할: 공통

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
- 구현 범위: `MYPAGE-001` 수정 액션 저장, `users.birthInfo` 갱신, `activeChartVersion`/`charts` stale 처리, 재조회 트리거. 차트 재계산은 클라이언트 `AstrologyRepository` 의 캐시 무효화 경로로 처리하고, Functions 프록시 이전은 Blaze 전환 시 후속.
- 수정 예상 파일: `lib/features/profile/presentation/my_page_screen.dart`, `lib/features/onboarding/presentation/onboarding_screen.dart`, `lib/features/astrology/application/astrology_providers.dart`, `lib/features/astrology/data/astrology_repository.dart`
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
