# Stellara

Stellara는 **출생 정보 기반 점성술 콘텐츠 앱**입니다.  
사용자의 생년월일, 출생 시간, 출생지를 바탕으로 나탈 차트, 오늘의 운세, 친구 궁합, AI 질문, 결과 공유를 제공하는 것을 목표로 합니다.

이 저장소는 현재 **학교 프로젝트용 Flutter 앱 프로토타입** 단계이며,  
핵심 화면 흐름과 Prokerala 연동 골격은 존재하지만 Firebase/Firestore 연동, AI, 공유 기능은 아직 순차적으로 붙여가는 중입니다.

현재는 무료 플랜과 짧은 프로젝트 기간을 고려해, **Prokerala primary key 1개 + backup key 최대 3개**를 순차 fallback 하는 임시 운영 방식을 사용합니다.  
`Cloud Functions` 프록시는 **Blaze 업그레이드가 가능할 때의 후속 선택지**로 남겨둡니다.

## 한눈에 보기

### 지금 이미 있는 것

- Flutter 앱 기본 구조
- Riverpod 상태 관리 골격
- Prokerala 직접 호출용 wrapper
- 나탈 차트/운세/궁합용 fixture fallback
- 로그인, 온보딩, 홈, 차트, 궁합, 친구, 랜덤 질문, 마이페이지 화면 프로토타입
- Android/Web 실행 검증

### 아직 없는 것

- Firebase 연동
- Blaze 기반 서버 프록시
- 카카오 로그인
- AI 질문 실연동
- 공유 화면 구현
- 후반부 컬러 디자인 / 애니메이션 마감

### 이 문서가 누구를 위한 것인가

- **비개발자 팀원**: 프로젝트가 지금 어디까지 왔는지 빠르게 이해
- **개발자**: 실행 방법, 문서 읽는 순서, 현재 작업 기준 파악
- **AI 협업자**: 현재 소스 상태, 문서 기준, 작업 시작 순서 확인

## 문서 읽는 순서

문서는 아래 순서로 보면 가장 덜 헷갈립니다.

1. [docs/README.md](docs/README.md)  
   문서 전체 구조와 SDD 시작 방법
2. [docs/MVP.md](docs/MVP.md)  
   이번 버전에서 반드시 할 것 / 미룰 것
3. [docs/SDD.md](docs/SDD.md)  
   시스템 구조, API/DB 설계, 일정, 리스크
4. [docs/TASKS.md](docs/TASKS.md)  
   실제 협업용 작업 분해
5. [docs/NOTION_EXPORT.md](docs/NOTION_EXPORT.md)  
   노션 공유용 통합 정리본

## 지금 SDD를 어떻게 시작하면 되나

짧게 정리하면 아래 순서입니다.

1. `docs/MVP.md`에서 이번 주기 범위를 먼저 확인합니다.
2. `docs/SDD.md`에서 현재 구조와 리스크를 확인합니다.
3. `docs/TASKS.md`에서 선행 작업이 비어 있는 이슈를 하나 고릅니다.
4. 작업 중 설계가 바뀌면:
   - 범위 변경은 `docs/MVP.md`
   - API/DB/일정 변경은 `docs/SDD.md`
   - 작업 단위 변경은 `docs/TASKS.md`
   - 실행/온보딩 변경은 `README.md` 와 `docs/README.md`

자세한 가이드는 [docs/README.md](docs/README.md)에 정리되어 있습니다.

## 빠른 실행

### 1. 브랜치 이동

```sh
cd /Users/nywoo/proj/stellara
git checkout feature/week09-prokerala-api
```

### 2. `.env` 파일 만들기

```sh
cp .env.example .env
```

`.env` 파일은 **항상 필요**합니다.  
다만 이제는 **디버그 + fixture 모드**에서는 Prokerala 키를 비워 둔 상태로도 앱을 띄울 수 있습니다.

### 3. 개발 모드 선택

#### 권장: Fixture 모드

UI 작업, 문서 작업, 화면 흐름 확인, 비개발자 검토 때 권장합니다.

```env
USE_FIXTURE_IN_DEBUG=true
PROKERALA_CLIENT_ID=
PROKERALA_CLIENT_SECRET=
```

이 모드에서는 디버그 환경에서 fixture가 있는 호출은 네트워크를 타지 않습니다.
비개발자 검토, 화면 작업, 문서 작업은 이 모드를 기본으로 사용하면 됩니다.

#### 실응답 검증 모드

Prokerala 실제 응답을 확인하거나 parser를 보정할 때 사용합니다.

```env
USE_FIXTURE_IN_DEBUG=false
PROKERALA_CLIENT_ID=...
PROKERALA_CLIENT_SECRET=...
```

주의:

- 실응답이 기대와 다르거나 네트워크/크레딧 제약이 있으면 fixture fallback 이 발생할 수 있습니다.
- 실응답 검증은 필요한 시점에만 짧게 수행하는 것이 좋습니다.
- backup key를 넣어두면 primary key에서 429가 발생했을 때 `SEOYEON → SEONWOO → DOYEON` 순서로 다음 credential 전환을 시도합니다.

### 3-1. Prokerala key 운영 방식

현재 앱은 아래 순서로 Prokerala credential 을 사용합니다.

1. `PROKERALA_CLIENT_ID` / `PROKERALA_CLIENT_SECRET`
2. `PROKERALA_CLIENT_ID_SEOYEON` / `PROKERALA_CLIENT_SECRET_SEOYEON`
3. `PROKERALA_CLIENT_ID_SEONWOO` / `PROKERALA_CLIENT_SECRET_SEONWOO`
4. `PROKERALA_CLIENT_ID_DOYEON` / `PROKERALA_CLIENT_SECRET_DOYEON`

운영 원칙:

- 기본은 primary key 사용
- Prokerala API에서 429가 발생하면 다음 backup credential로 1회 전환 시도
- backup key가 없으면 기존 credential로 `Retry-After` 기준 재시도
- 이 방식은 **학교 프로젝트 + 무료 플랜 + 임시 운영**을 위한 완충 장치이며, 정식 운영 구조는 아닙니다

### 3-2. 무료 플랜 운영 원칙

- Firebase는 우선 `Firestore` 중심으로만 사용하고, `Cloud Functions` 는 MVP 기본 경로에서 제외합니다
- Prokerala는 당분간 클라이언트 직접 호출을 유지하되, **학교 데모용 내부 빌드**로만 사용합니다
- `client_secret` 이 앱 안에 있으므로 공개 배포용 APK/IPA 기준으로는 안전한 구조가 아닙니다
- AI 질문은 **학교 데모용 내부 빌드에 한해 GPT/Claude direct call** 을 허용하고, 실패 시 local fallback 으로 화면이 비지 않게 유지합니다
- `LoginScreen` 의 `데모 데이터로 둘러보기` 버튼은 최종 마감 직전까지 유지하고, 마지막 정리 단계에서 제거합니다

### 3-3. AI 질문 운영 방식

- 메인 사용자 화면에는 raw model id 대신 `자동(추천) / GPT / Claude` 정도의 **provider 선택만 노출**하는 것을 권장합니다
- `자동(추천)` 의 기본 흐름은 `OpenAI → Anthropic → local fallback` 순서로 둡니다
- 같은 provider 안에서는 `primary → seoyeon → seonwoo → doyeon` 순서의 backup key 를 둘 수 있습니다
- 실제 model id (`gpt-5-mini`, `claude-3-5-haiku-latest` 등)는 메인 화면이 아니라 `.env` 또는 개발자 전용 설정에서 관리하는 편이 UX와 협업에 유리합니다
- 앱 연동에는 ChatGPT / Claude 대화형 앱 구독이 아니라 **각 서비스의 API key** 가 필요합니다
- 이 방식도 Prokerala 와 마찬가지로 **학교 프로젝트용 내부 데모 빌드 한정 임시 운영 방식**입니다

### 4. 패키지 설치

```sh
flutter pub get
```

### 5. 실행

Android 에뮬레이터:

```sh
flutter emulators --launch Medium_Phone_API_36.1
flutter devices
flutter run -d emulator-5554
```

Chrome:

```sh
flutter run -d chrome
```

기기 ID가 다르면 `flutter devices` 출력값을 사용하세요.

## 개발 검증 명령

작업 전후로 아래 명령을 기준으로 확인합니다.

```sh
flutter analyze
flutter test
flutter build apk --debug
flutter build web
```

## 현재 로컬에서 확인된 결과

이 브랜치 기준으로 아래 명령이 통과했습니다.

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build web
```

추가 메모:

- Android/Web 기준으로는 바로 개발 시작 가능
- iOS/macOS는 Xcode/CocoaPods 미설치 상태에서는 바로 개발 불가

## 저장소 구조

```text
stellara/
├── lib/
│   ├── core/          # 테마, env, HTTP, 공용 위젯
│   └── features/      # 기능별 모듈
├── test/              # 위젯/유닛 테스트
├── docs/              # SDD, MVP, TASKS, 문서 시작 가이드
├── android/ ios/ web/ macos/
├── .env.example
└── README.md
```

### 앱 구조 원칙

- `lib/core`: 앱 전반 공통 인프라
- `lib/features`: 기능 단위 모듈
- 각 feature는 가능하면 `presentation → application → data → domain` 흐름 유지

## 현재 기준 작업 원칙

- **기능 추가보다 리스크 제거를 우선**합니다.
- 무료 플랜 기준에서는 `Firestore` 는 붙이되 `Cloud Functions` 전환은 보류합니다.
- 화려한 디자인과 공유 기능은 후반부에 구현하되, 12주차 후반부터 선행 준비를 시작합니다.
- 문서와 코드가 어긋나면 문서를 같이 갱신합니다.

## 협업 시 꼭 기억할 것

- `docs/` 문서가 현재 작업 기준입니다.
- 비개발자도 문서를 읽고 참여할 수 있게 **문서 언어는 최대한 명확하게 유지**합니다.
- AI 협업 시에는 실제 secret 값을 프롬프트에 넣지 않습니다.
- 범위가 바뀌면 문서부터 고치고 작업합니다.

## 아직 결정되지 않은 것

아래 항목은 아직 최종 고정 전입니다.

- Firebase Auth 전략
- 친구 코드 생성 규칙
- `chartVersion` / `chartPairVersion` 규칙
- Web에서의 출생지 좌표 변환 보완 방식
- 카카오 로그인 포함 시점
- 공개 배포 전 AI / Prokerala secret 프록시 이전 시점

이 항목들은 `docs/SDD.md` 와 `docs/TASKS.md` 기준으로 순차 확정합니다.
