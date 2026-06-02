# 도연 로컬 세팅 가이드

이 문서는 도연이 `main` 최신 작업을 받아서 디자인 작업을 이어갈 수 있도록, 맥 기준으로 처음부터 끝까지 따라가는 가이드입니다.

이 프로젝트는 다음 역할이 이미 나뉘어 있습니다.

1. 디자인 작업: 도연
2. Firebase/Auth/API/상태관리/로직 작업: `main`에 반영 완료

중요한 전제부터 먼저 적습니다.

1. 이 프로젝트는 `firebase_options.dart`를 쓰지 않습니다.
2. Android는 `android/app/google-services.json`으로 Firebase를 붙입니다.
3. Web은 `.env` 안의 `FIREBASE_WEB_*` 값으로 Firebase를 붙입니다.
4. 현재 레포에는 `ios/` 폴더가 없어서, 이 가이드는 Android와 Chrome 기준입니다.

## 1. 프로젝트 구조 먼저 이해하기

도연이 자주 보게 될 중요한 경로는 아래입니다.

```text
stellara/
├─ lib/
│  ├─ main.dart
│  ├─ app.dart
│  ├─ core/
│  │  ├─ env/env.dart
│  │  ├─ firebase/firebase_bootstrap.dart
│  │  ├─ http/dio_client.dart
│  │  └─ theme/app_theme.dart
│  └─ features/
│     ├─ auth/
│     ├─ onboarding/
│     ├─ friends/
│     ├─ astrology/
│     ├─ compatibility/
│     ├─ home/
│     └─ profile/
├─ android/
│  ├─ build.gradle.kts
│  └─ app/
│     ├─ build.gradle.kts
│     └─ google-services.json
├─ web/
├─ firestore.rules
├─ firestore.indexes.json
├─ firebase.json
├─ .env.example
└─ .env
```

실제 시작 흐름도 같이 알아두면 편합니다.

1. 앱 시작 파일: `lib/main.dart`
2. 앱 첫 화면 분기: `lib/app.dart`
3. 비로그인 첫 화면: `lib/features/auth/presentation/landing_screen.dart`
4. 로그인 화면: `lib/features/auth/presentation/login_screen.dart`
5. 회원가입 화면: `lib/features/auth/presentation/signup_screen.dart`
6. 온보딩 화면: `lib/features/onboarding/presentation/onboarding_screen.dart`

즉, 예전처럼 “데모로 둘러보기”가 아니라 지금은 `LandingScreen -> 로그인/회원가입 -> 온보딩 -> 메인` 구조입니다.

## 2. 처음 clone 받는 경우

### 2-1. 프로젝트 받기

터미널에서 아래를 순서대로 실행합니다.

```bash
git clone https://github.com/bellca225/stellara.git
cd stellara
git switch main
git pull origin main
```

### 2-2. 디자인 작업용 브랜치 만들기

도연이 바로 `main`에서 작업하지 않고, 본인 작업 브랜치에서 이어가는 것을 추천합니다.

```bash
git switch -c feature/doyeon-design-2026-06-02
```

브랜치 이름은 날짜만 바꿔도 됩니다.

## 3. 이미 clone 받아서 작업 중인 경우

이 경우에는 먼저 지금 작업 내용을 백업한 뒤 최신 `main`을 반영합니다.

### 3-1. 현재 작업 백업

```bash
git status
git branch --show-current
git add .
git commit -m "WIP: backup before syncing main"
```

아직 커밋하기 싫으면 최소한 `git status`로 변경 파일을 꼭 확인합니다.

### 3-2. 최신 main 받기

```bash
git fetch origin
git switch main
git pull origin main
```

### 3-3. 본인 브랜치에 main 합치기

도연이 기존 브랜치에서 계속 작업할 거라면, 다시 그 브랜치로 돌아가서 `main`을 합칩니다.

예시:

```bash
git switch feature/도연-친구추가-기능
git merge origin/main
```

새 브랜치에서 다시 시작할 거라면:

```bash
git switch -c feature/doyeon-design-2026-06-02 origin/main
```

### 3-4. 충돌이 나면

충돌이 나면 혼자 억지로 정리하지 말고 아래 두 가지만 바로 확인합니다.

1. 어떤 파일에서 충돌이 났는지
2. 충돌 표시(`<<<<<<<`, `=======`, `>>>>>>>`)가 어디에 생겼는지

그리고 그 화면을 캡처해서 공유받는 방식이 가장 안전합니다.

## 4. Flutter 의존성 설치

프로젝트 루트에서 아래를 실행합니다.

```bash
flutter pub get
```

문제가 있으면 한 번 더 아래 순서로 시도합니다.

```bash
flutter clean
flutter pub get
```

Flutter 자체 설치 상태가 의심되면:

```bash
flutter doctor
```

## 5. .env 파일 만들기

이 프로젝트는 `.env` 파일이 꼭 있어야 합니다.

`.env`는 Git에 올리면 안 되는 민감정보 파일입니다. 이미 `.gitignore`에 들어가 있으니, 절대 커밋하지 마세요.

### 5-1. 기본 파일 만들기

```bash
cp .env.example .env
```

### 5-2. 디자인 작업만 먼저 할 때 최소 설정

점성술 API를 바로 실호출하지 않고 화면만 먼저 보고 싶으면 `.env`를 아래처럼 맞춰두면 됩니다.

```env
PROKERALA_BASE_URL=https://api.prokerala.com
PROKERALA_TOKEN_URL=https://api.prokerala.com/token
PROKERALA_REMOTE_ENABLED=false
USE_FIXTURE_IN_DEBUG=true
AI_REMOTE_ENABLED=false
```

이렇게 두면 API 비용을 쓰지 않고도 화면 작업을 이어가기 쉽습니다.

### 5-3. Chrome에서 로그인/회원가입까지 테스트하려면 추가로 필요한 값

Web Firebase는 `.env`에서 읽습니다. 아래 값은 Git에 없으니, 프로젝트 소유자가 따로 안전하게 공유해줘야 합니다.

```env
FIREBASE_WEB_API_KEY=
FIREBASE_WEB_AUTH_DOMAIN=
FIREBASE_WEB_PROJECT_ID=
FIREBASE_WEB_STORAGE_BUCKET=
FIREBASE_WEB_MESSAGING_SENDER_ID=
FIREBASE_WEB_APP_ID=
```

중요:

1. `.env` 전체를 GitHub에 올리면 안 됩니다.
2. 메신저로 보내더라도 공개 채널보다는 개인 공유가 안전합니다.
3. 캡처를 올릴 때도 키 값이 보이지 않게 주의합니다.

## 6. Firebase 관련 필수 확인

### 6-1. Android Firebase

아래 파일이 있는지 확인합니다.

```text
android/app/google-services.json
```

이 파일이 있어야 Android에서 Firebase Auth / Firestore가 붙습니다.

현재 Android 패키지명 기준은 아래입니다.

```text
com.stellara.app
```

즉, `google-services.json`도 이 패키지명에 맞는 파일이어야 합니다.

### 6-2. Web Firebase

Web은 `google-services.json`이 아니라 `.env` 안의 `FIREBASE_WEB_*` 값으로 붙습니다.

즉, Chrome 테스트에서는 `.env`에 Firebase Web 키가 없으면 로그인/회원가입이 정상 동작하지 않을 수 있습니다.

### 6-3. firebase_options.dart 관련

이 프로젝트는 `flutterfire configure`로 생성한 `firebase_options.dart` 구조가 아닙니다.

찾아도 없는 게 정상입니다. 대신 아래 구조를 사용합니다.

1. Android: `android/app/google-services.json`
2. Web: `.env`의 `FIREBASE_WEB_*`
3. 초기화 코드: `lib/core/firebase/firebase_bootstrap.dart`

### 6-4. iOS 관련

현재 레포에는 `ios/` 폴더가 없습니다. 그래서 이 가이드에서는 iOS 설정은 제외합니다.

## 7. Android Emulator 실행 방법

Android Studio에서 에뮬레이터를 켜도 되고, 터미널에서 실행해도 됩니다.

### 7-1. 설치된 에뮬레이터 목록 보기

```bash
/Users/nywoo/Library/Android/sdk/emulator/emulator -list-avds
```

### 7-2. 에뮬레이터 실행

예시:

```bash
/Users/nywoo/Library/Android/sdk/emulator/emulator -avd Pixel_8
```

`Pixel_8` 대신 본인 환경의 AVD 이름을 넣습니다.

### 7-3. 연결된 기기 확인

```bash
flutter devices
```

## 8. adb / emulator PATH 문제 해결

터미널에서 `adb: command not found` 같은 에러가 나면 SDK 경로가 PATH에 안 잡힌 상태입니다.

현재 세션에서만 임시로 해결하려면:

```bash
export PATH=$PATH:/Users/nywoo/Library/Android/sdk/platform-tools:/Users/nywoo/Library/Android/sdk/emulator
```

그다음 확인:

```bash
adb devices
flutter devices
```

굳이 PATH를 안 잡고 바로 전체 경로로 실행해도 됩니다.

```bash
/Users/nywoo/Library/Android/sdk/platform-tools/adb devices
/Users/nywoo/Library/Android/sdk/emulator/emulator -list-avds
```

## 9. 프로젝트 실행 방법

## 9-1. Chrome으로 실행

```bash
flutter run -d chrome
```

Chrome은 빠르게 화면을 보기 좋습니다. 다만 로그인/회원가입까지 테스트하려면 `.env`에 `FIREBASE_WEB_*`가 들어 있어야 합니다.

## 9-2. Android Emulator로 실행

에뮬레이터를 먼저 켠 뒤 아래를 실행합니다.

```bash
flutter run
```

혹은 기기를 명시해도 됩니다.

```bash
flutter run -d emulator-5554
```

## 10. 자주 발생하는 오류와 해결 방법

### 10-1. `adb: command not found`

원인:

1. Android SDK `platform-tools` 경로가 PATH에 없음

해결:

```bash
export PATH=$PATH:/Users/nywoo/Library/Android/sdk/platform-tools:/Users/nywoo/Library/Android/sdk/emulator
adb devices
```

### 10-2. `Cannot resolve external dependency com.google.gms:google-services... because no repositories are defined`

원인:

1. 오래된 브랜치 기준 Android Gradle 설정

해결:

1. 최신 `main`을 다시 pull 받기
2. `android/build.gradle.kts`에 `google()` / `mavenCentral()`이 들어 있는지 확인
3. 다시 실행

```bash
git pull origin main
flutter clean
flutter pub get
flutter run
```

### 10-3. Firebase 초기화 실패

원인 후보:

1. Android에서 `android/app/google-services.json`이 없거나 다른 프로젝트 파일임
2. Chrome에서 `.env`에 `FIREBASE_WEB_*` 값이 없음
3. `.env` 파일 자체가 없음

확인할 것:

1. `.env`가 프로젝트 루트에 있는지
2. Android는 `android/app/google-services.json`이 있는지
3. Chrome은 `FIREBASE_WEB_API_KEY` 등 Web Firebase 값이 채워졌는지

### 10-4. `flutter pub get` 실패

먼저 아래를 확인합니다.

```bash
flutter doctor
flutter pub get
```

그래도 안 되면:

```bash
flutter clean
flutter pub get
```

원인 후보:

1. Flutter SDK 문제
2. 네트워크 문제
3. 패키지 캐시 문제

### 10-5. Chrome은 되는데 Android가 안 됨

원인 후보:

1. 에뮬레이터 미실행
2. `google-services.json` 문제
3. Android SDK / adb PATH 문제
4. 오래 설치된 예전 앱 패키지 충돌

예전 앱이 남아 있으면 아래처럼 삭제 후 다시 설치합니다.

```bash
/Users/nywoo/Library/Android/sdk/platform-tools/adb uninstall com.example.stellara
/Users/nywoo/Library/Android/sdk/platform-tools/adb uninstall com.stellara.app
flutter run
```

### 10-6. Android는 되는데 Chrome에서 로그인/회원가입이 안 됨

원인 후보:

1. Web Firebase 환경변수가 `.env`에 없음

즉, Chrome 테스트는 Android보다 `.env` 의존성이 더 큽니다.

### 10-7. `No matching client found for package name`

원인:

1. `google-services.json` 안의 패키지명과 앱 패키지명이 다름

현재 앱 패키지명 기준은 `com.stellara.app` 입니다.

즉, 이 에러가 뜨면 최신 `google-services.json`을 다시 받아야 합니다.

## 11. 디자인 작업자가 건드리면 안 되는 영역

아래는 디자인 수정 중 실수로 건드리면 앱 동작이 깨질 가능성이 높은 영역입니다.

### 건드리지 않는 것을 권장하는 파일/폴더

```text
lib/core/env/env.dart
lib/core/firebase/firebase_bootstrap.dart
lib/core/http/dio_client.dart
lib/features/*/application/*
lib/features/*/data/*
firestore.rules
firestore.indexes.json
firebase.json
android/build.gradle.kts
android/app/build.gradle.kts
android/app/google-services.json
.env
```

특히 아래 개념은 디자인 작업 중 수정하지 않는 것이 안전합니다.

1. auth/provider/service
2. firebase config
3. api/service
4. firestore logic
5. state management

## 12. 디자인 작업자가 수정해도 되는 영역

아래는 도연이 주로 수정해도 되는 영역입니다.

### 주로 수정해도 되는 파일

```text
lib/features/auth/presentation/landing_screen.dart
lib/features/auth/presentation/login_screen.dart
lib/features/auth/presentation/signup_screen.dart
lib/features/onboarding/presentation/onboarding_screen.dart
lib/features/friends/presentation/friend_screen.dart
lib/features/home/presentation/main_home_screen.dart
lib/features/profile/presentation/my_page_screen.dart
lib/features/astrology/presentation/astrology_screen.dart
lib/features/compatibility/presentation/match_screen.dart
lib/core/theme/app_theme.dart
```

### 수정해도 되는 항목

1. widget layout
2. style/theme
3. spacing/font
4. animation
5. image asset
6. 텍스트 문구
7. 버튼/카드/리스트의 시각적 구성

단, 아래는 지우거나 바꾸지 않도록 주의합니다.

1. `onPressed`
2. `Navigator`
3. `ref.watch(...)`
4. `ref.read(...)`
5. Firebase/Auth/Firestore 호출
6. Repository / Provider 연결 코드

즉, “보이는 것”은 수정해도 되지만, “동작하는 방식”은 건드리지 않는 편이 안전합니다.

## 13. Android 한글 입력 체크

앱 코드 기준으로 일반 텍스트 필드에서는 한글 입력을 막지 않습니다.

하지만 Android 에뮬레이터에는 기본적으로 한글 키보드가 꺼져 있을 수 있습니다.

에뮬레이터에서 한글 입력이 안 되면 아래를 확인합니다.

1. `Settings`
2. `System`
3. `Languages & input`
4. `On-screen keyboard`
5. `Gboard`
6. `Languages`
7. `Add keyboard`
8. `Korean` 추가

필요하면 물리 키보드 사용을 잠깐 끄고 화면 키보드로 먼저 테스트합니다.

## 14. 실행 후 반드시 확인할 체크리스트

아래는 도연이 세팅 직후 직접 체크해야 하는 항목입니다.

### 기본 실행 체크

1. 앱이 켜지는지
2. 첫 화면이 `LandingScreen`인지
3. 콘솔에 `.env` 누락 오류가 없는지

### 로그인/회원가입 체크

1. 회원가입이 되는지
2. 로그인이 되는지
3. 로그인 후 온보딩으로 넘어가는지

### 친구 기능 체크

1. 친구 추가 화면이 열리는지
2. 친구 코드 입력이 되는지
3. 실제 다른 계정과 친구 추가가 되는지

### 점성술 체크

1. 출생정보 입력 후 결과가 보이는지
2. 마이페이지에서 출생정보 수정 후 결과가 다시 갱신되는지
3. Chrome과 Android에서 모두 결과 로드가 되는지

### Android 입력 체크

1. 이름/닉네임/출생지에 한글 입력이 되는지
2. 로그인 아이디는 영문/숫자 규칙이 유지되는지

## 15. 가장 추천하는 시작 순서

도연이 처음 세팅할 때는 아래 순서가 가장 안전합니다.

1. `git clone`
2. `git switch main`
3. `git pull origin main`
4. `git switch -c feature/doyeon-design-날짜`
5. `cp .env.example .env`
6. `.env` 최소 설정 입력
7. `flutter pub get`
8. Android Emulator 실행
9. `flutter run`
10. 로그인/회원가입/친구 추가/점성술/한글 입력 체크

## 16. 마지막으로 꼭 기억할 것

1. `.env`는 Git에 올리면 안 됩니다.
2. Firebase 키, API 키, 비밀번호 같은 민감정보는 공개 채널에 올리면 안 됩니다.
3. 도연은 우선 `presentation`, `theme`, `layout` 중심으로 수정합니다.
4. `provider`, `repository`, `firebase`, `api`, `firestore` 관련 파일은 수정 전 꼭 확인받는 것이 안전합니다.

이 문서를 기준으로 세팅하다가 막히면, 막힌 지점의 터미널 에러 로그를 그대로 복사해서 공유받는 방식이 가장 빠릅니다.
