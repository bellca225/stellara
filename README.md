# Stellara

Stellara는 출생 정보 기반 점성술 분석, 친구 궁합, 랜덤 질문, 오늘의 운세를 제공하는 Flutter 앱입니다.

현재 버전은 API 연결 전 단계의 화면 프로토타입입니다. Android 에뮬레이터와 Chrome에서 화면 흐름을 확인할 수 있고, Prokerala 연동을 위한 기본 구조와 Riverpod 상태 관리 골격이 포함되어 있습니다.

## 터미널에서 바로 실행하기

### 1. 브랜치 이동

```sh
cd /Users/nywoo/proj/stellara
git checkout feature/week09-prokerala-api
```

### 2. 환경 변수 준비

`.env` 파일이 이미 있으면 그대로 사용하면 됩니다. 처음 받는 환경이라면 `.env.example`을 복사해 `.env`를 만든 뒤 Prokerala 키를 채워주세요.

```sh
cp .env.example .env
```

필수 값:

- `PROKERALA_CLIENT_ID`
- `PROKERALA_CLIENT_SECRET`

### 3. 패키지 설치

```sh
flutter pub get
```

### 4. Android 에뮬레이터 실행

```sh
flutter emulators --launch Medium_Phone_API_36.1
flutter devices
flutter run -d emulator-5554
```

`flutter devices`에 표시되는 기기 ID가 다르면 마지막 줄의 `emulator-5554`만 해당 값으로 바꾸면 됩니다.

### 5. Chrome에서 빠르게 보기

```sh
flutter run -d chrome
```

## 현재 구현 상태

- Flutter 앱 생성 및 Android 에뮬레이터 실행 검증 완료
- 로그인, 온보딩, 메인 홈, 점성술 분석, 친구 관리, 마이페이지, 궁합, 랜덤 질문, 오늘의 운세 화면 프로토타입 구현
- 실제 API, Firebase, Kakao 로그인, 점성술 계산, AI 생성 기능은 아직 연결하지 않음
- 현재 앱 패키지명: `com.example.stellara`
- 현재 테스트 대상 에뮬레이터: `Medium_Phone_API_36.1`

## 핵심 기능 범위

| 기능명 | 설명 | 구현 계획 |
| --- | --- | --- |
| 회원가입 및 로그인 | 사용자가 카카오 계정으로 가입하고 개인 데이터를 안전하게 관리 | `kakao_flutter_sdk_user`로 Kakao OAuth 처리, 백엔드 또는 Firebase에서 앱 사용자 ID 발급, JWT/세션은 `flutter_secure_storage` 저장 |
| 출생 정보 입력 및 저장 | 생년월일, 출생 시간, 출생지를 입력하고 이후 운세 콘텐츠에 활용 | 회원 프로필에 출생 정보 저장, 개인정보 동의, 입력값 검증, 마이페이지 수정 기능 제공 |
| 점성술 봐주기 | 출생 정보를 기반으로 나탈 차트, 행성, 별자리, 하우스 분석 | 출생지 좌표 변환 후 Prokerala 또는 별도 점성술 API 호출, 결과를 Firestore 또는 캐시에 저장 |

## 화면 설계

| 화면 ID | 화면 | 현재 상태 |
| --- | --- | --- |
| `LOGIN-001` | 카카오 로그인 첫 진입 화면 | 목업 버튼 및 API 연결 구상 표시 |
| `ONBOARDING-001` | 최초 로그인 이후 출생 정보 입력 | 닉네임, 생년월일, 출생 시간, 출생지 입력 UI |
| `NAV-001` | 하단 네비게이션 | 홈, 랜덤 질문, 오늘의 운세, 마이페이지 탭 |
| `MAIN-001` | 메인 홈 | 나의 행성 시각화, Big 3, 즐겨찾기 친구, 친구 관리 이동 |
| `ASTROLOGY-001` | 상세 점성술 분석 | 나탈 차트 목업 및 행성별 해석 카드 |
| `FRIEND-001` | 친구 관리 | 친구 요청, 랜덤 코드 검색, 친구 목록, 즐겨찾기 3명 제한 UI |
| `MYPAGE-001` | 마이페이지 | 친구 코드, 출생 정보, 차트 재생성, 로그아웃 |
| `MATCH-001` | 친구와 궁합 결과 | 총점, 감정/대화/연애 점수, 요약, 공유 이동 |
| `CONTENT-001` | 랜덤 질문 | AI 생성 3개와 사용자 생성 1개 목업 |
| `TODAY-001` | 오늘의 운세 | 운세 한 줄, 감정 상태, 행운 요소 |
| `SHARE-001` | 결과 공유 | 공유 이미지 미리보기, 이미지 저장, SNS 공유 버튼 |

## AI 협업 컨텍스트

다음 개발자나 AI가 이어서 작업할 때는 아래 전제를 유지하세요.

- 현재 목표는 화면 프로토타입과 Prokerala 연결 준비입니다. 실제 사용자 인증, Firebase 저장, AI 질문 생성은 아직 연결하지 않습니다.
- 화면 구조는 `lib/features/*` 아래로 이미 분리되어 있습니다. 현재 핵심 흐름은 `auth -> onboarding -> app_shell -> home/astrology/today/profile` 순서입니다.
- 홈 탭은 `MAIN-001`이고, 점성술 분석 화면은 홈에서 내 행성 아이콘을 눌렀을 때 들어가는 상세 화면 `ASTROLOGY-001`입니다.
- 상태 관리는 Riverpod을 사용합니다. 현재 `currentBirthInfoProvider`, `myNatalChartProvider`, `todayHoroscopeProvider`, `synastryProvider`가 기본 흐름을 담당합니다.
- Firestore, Kakao, Prokerala, OpenAI 키는 앱에 직접 넣지 마세요. 앱은 백엔드 또는 보안 설정 파일을 통해 필요한 최소 데이터만 받아야 합니다.
- 점성술 계산 결과는 앱에서 매번 새로 계산하지 말고, 사용자 birth profile 해시 또는 chart version 기준으로 캐시하세요.
- 공유 화면은 `screenshot`으로 위젯을 이미지화하고 `share_plus`로 공유하는 구조를 예상합니다.

## 예정 패키지

아래 패키지는 실제 기능 연결 단계에서 추가할 예정입니다. 현재 프로토타입은 Flutter 기본 패키지 위주로 동작합니다.

| 패키지 | 용도 |
| --- | --- |
| `kakao_flutter_sdk_user` | 카카오 소셜 로그인 |
| `flutter_riverpod`, `riverpod_annotation`, `build_runner` | 상태 관리 및 코드 생성 |
| `firebase_core`, `cloud_firestore`, `firebase_messaging` | Firebase 초기화, 데이터 저장, 푸시 |
| `flutter_secure_storage` | JWT, 카카오 토큰 등 민감 정보 저장 |
| `dio` | 점성술 백엔드, OpenAI 백엔드, 외부 API HTTP 통신 |
| `geocoding` | 출생지 주소를 좌표로 변환 |
| `lottie` | 우주, 행성 애니메이션 |
| `share_plus`, `screenshot` | 결과 이미지 저장 및 SNS 공유 |
| `intl` | 날짜, 시간, 다국어 형식 |
| `go_router` | 선언형 라우팅 및 딥링크 |
| `shared_preferences` | 오늘의 운세 캐시, 앱 설정 |
| `freezed`, `freezed_annotation`, `json_serializable` | 불변 모델 및 JSON 변환 |
| `cached_network_image` | 프로필 이미지 캐싱 |
| `flutter_local_notifications` | 로컬 알림 |

## API 연결 계획

| API | 용도 | 연결 방식 |
| --- | --- | --- |
| Kakao Login API | 소셜 로그인, 사용자 고유 ID, 프로필 조회 | 앱에서 Kakao OAuth 진행 후 백엔드/Firebase 사용자 문서와 매핑 |
| Google Geocoding API | 출생지 주소를 위도/경도로 변환 | 앱 또는 백엔드에서 주소 검색, 좌표를 birth profile에 저장 |
| Prokerala Astrology API | 행성 위치, 하우스, Ascendant, 나탈 차트, 궁합 계산 | `dio`로 백엔드 프록시 호출 권장. API 키는 앱에 직접 포함하지 않음 |
| OpenAI API | 성격 리포트, 랜덤 질문 생성 | 백엔드에서 호출하고 앱은 결과 텍스트만 수신 |
| Firebase Firestore | 사용자, 친구, 차트, 운세 결과 저장 | `users`, `friendRequests`, `friendships`, `charts`, `dailyFortunes` 컬렉션 예상 |

## Mac에서 처음 실행하기

### 1. 사전 설치

Mac에는 아래가 필요합니다.

- Git
- Flutter SDK
- Android Studio
- Android SDK Platform Tools
- Android Emulator
- Android SDK Command-line Tools
- Chrome

설치 확인:

```sh
git --version
flutter --version
flutter doctor -v
```

`flutter doctor -v`에서 Android toolchain이 통과해야 Android 에뮬레이터 실행이 편합니다. iOS 개발까지 할 경우에만 Xcode와 CocoaPods를 추가로 설치하세요.

### 2. 소스 받기

```sh
git clone <repository-url>
cd stellara
flutter pub get
```

### 3. 에뮬레이터 확인

```sh
flutter emulators
flutter devices
```

현재 이 Mac에서 확인한 에뮬레이터 이름은 다음과 같습니다.

```sh
Medium_Phone_API_36.1
```

### 4. 에뮬레이터 켜기

```sh
flutter emulators --launch Medium_Phone_API_36.1
```

에뮬레이터가 완전히 켜진 뒤 다시 확인합니다.

```sh
flutter devices
```

예시 출력에 `emulator-5554`가 보이면 실행할 수 있습니다.

### 5. 앱 실행

```sh
flutter run -d emulator-5554
```

기기 ID가 다르면 `emulator-5554` 대신 `flutter devices`에 표시된 ID를 사용하세요.

### 6. 에뮬레이터가 검은 화면일 때

에뮬레이터는 켜져 있는데 캡처나 화면이 검게 보이면 화면을 깨웁니다.

```sh
adb shell input keyevent KEYCODE_WAKEUP
adb shell input swipe 540 2100 540 500 300
```

`adb`가 명령어로 잡히지 않으면 Android SDK의 platform-tools 경로를 PATH에 추가하세요.

## Windows에서 처음 실행하기

### 1. 사전 설치

Windows에는 아래가 필요합니다.

- Git for Windows
- Flutter SDK
- Android Studio
- Android SDK Platform Tools
- Android Emulator
- Android SDK Command-line Tools
- Chrome

PowerShell에서 확인합니다.

```powershell
git --version
flutter --version
flutter doctor -v
```

Android Studio에서 `SDK Manager`를 열고 아래 항목이 설치되어 있는지 확인하세요.

- Android SDK Platform
- Android SDK Build-Tools
- Android SDK Command-line Tools
- Android Emulator
- Android SDK Platform-Tools

### 2. 소스 받기

```powershell
git clone <repository-url>
cd stellara
flutter pub get
```

### 3. 에뮬레이터 만들기

Android Studio에서 만드는 방법이 가장 쉽습니다.

1. Android Studio 실행
2. `More Actions` 또는 `Tools`에서 `Device Manager` 열기
3. `Create Virtual Device`
4. Pixel 계열 디바이스 선택
5. API 35 이상 이미지 선택
6. 생성 후 실행

CLI에서 확인:

```powershell
flutter emulators
flutter devices
```

### 4. 에뮬레이터 켜기

목록에 보이는 에뮬레이터 ID를 사용합니다.

```powershell
flutter emulators --launch <emulator-id>
flutter devices
```

예를 들어 기기 ID가 `emulator-5554`라면:

```powershell
flutter run -d emulator-5554
```

### 5. Windows에서 adb가 안 잡힐 때

Android SDK platform-tools 경로를 PATH에 추가하세요. 보통 아래 위치 중 하나입니다.

```text
C:\Users\<사용자명>\AppData\Local\Android\Sdk\platform-tools
```

새 PowerShell을 열고 확인합니다.

```powershell
adb devices
```

## Chrome으로 빠르게 실행

에뮬레이터가 무겁거나 설치가 덜 된 경우 Chrome으로 먼저 UI를 볼 수 있습니다.

```sh
flutter run -d chrome
```

Windows PowerShell도 동일합니다.

```powershell
flutter run -d chrome
```

## 개발 검증 명령

커밋이나 PR 전에 아래를 실행하세요.

```sh
flutter analyze
flutter test
flutter build apk --debug
flutter build web
```

Windows PowerShell에서도 동일합니다.

```powershell
flutter analyze
flutter test
flutter build apk --debug
flutter build web
```

## 자주 쓰는 에뮬레이터 명령

```sh
flutter emulators
flutter emulators --launch <emulator-id>
flutter devices
flutter run -d <device-id>
adb devices
adb shell monkey -p com.example.stellara 1
```

`adb shell monkey -p com.example.stellara 1`은 이미 설치된 Stellara 앱을 에뮬레이터에서 다시 앞으로 띄울 때 사용합니다.

## 현재 확인된 검증 결과

이 로컬 환경에서 아래 명령이 통과했습니다.

```sh
flutter analyze
flutter test
flutter build apk --debug
flutter build web
```
