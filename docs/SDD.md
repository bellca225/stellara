# Stellara — Software Design Document (SDD)

> **문서 버전**: v0.6  
> **최초 작성**: 2026-05-08 / **최종 수정**: 2026-05-08  
> **기준 브랜치**: `feature/week09-prokerala-api`  
> **팀명**: 물병 안 물고기  
> **팀원**: 우나영, 김도연, 배서연, 이선우  
>
> ⚠️ 실제 코드에서 확인된 내용을 기준으로 작성했습니다.  
> 코드에 없는 예정 사항은 **[예정]**, 불확실한 항목은 **[추후 확인 필요]** 로 표시했습니다.

---

## 목차

1. [프로젝트 개요](#1-프로젝트-개요)
2. [개발 범위](#2-개발-범위)
3. [기술 스택](#3-기술-스택)
4. [백엔드 구조](#4-백엔드-구조)
5. [시스템 구조](#5-시스템-구조)
6. [화면/기능 구조](#6-화면기능-구조)
7. [API 설계 보강](#7-api-설계-보강)
8. [DB 설계 보강](#8-db-설계-보강)
9. [예외 처리 방향](#9-예외-처리-방향)
10. [협업 규칙](#10-협업-규칙)
11. [개발 일정 초안](#11-개발-일정-초안)

---

## 1. 프로젝트 개요

### 1.1 앱 소개

Stellara는 사용자의 출생 정보(생년월일, 출생 시간, 출생지)를 기반으로 점성술 해석을 시각적 UI로 제공하는 Flutter 모바일 앱이다. 나탈 차트 분석, 오늘의 운세, 친구 궁합 비교, AI 랜덤 질문, 결과 공유 등의 기능을 통해 점성술 콘텐츠를 소셜하게 즐길 수 있는 서비스를 목표로 한다.

### 1.2 현재 개발 단계 (9주차 기준)

현재 단계는 **"프론트엔드 단독" 골격 구현** 단계이다. 자체 백엔드 서버는 아직 없으며, 외부 점성술 API(Prokerala)를 클라이언트에서 직접 호출하는 구조까지만 구현되어 있다.

- `lib/` 아래 Dart 파일 33개 (실측)
- 화면 프로토타입 9종 구현 완료 (목업 위주)
- Prokerala API 호출 wrapper 및 Riverpod 상태 관리 골격 동작 확인

### 1.3 빌드 타깃

| 플랫폼 | 상태 |
|--------|------|
| Android | 주 개발 타깃. 에뮬레이터 `Medium_Phone_API_36.1` 검증 완료 |
| Chrome (Web) | 보조 개발 타깃. `flutter run -d chrome` 검증 완료 |
| iOS / macOS | Flutter 기본 템플릿 존재, 별도 검증 미진행 |

---

## 2. 개발 범위

### 2.1 핵심 기능 (필수 구현)

> 로그인/회원가입은 **구조(화면+라우팅)만 먼저 구성**하고, 초기에는 Firestore에 테스트 사용자 데이터를 직접 입력하는 방식으로 진행한다. 카카오 OAuth는 후순위로 미룬다.

| 기능 | 설명 | 현재 상태 | 목표 주차 |
|------|------|-----------|-----------|
| 로그인 화면 구조 | 로그인 UI 구조만 구성, 실 인증 없이 Firestore 직접 입력으로 사용자 세팅 | UI 목업 구현됨 | 10주차 |
| 출생 정보 입력 및 Firestore 저장 | 생년월일·출생시간·출생지 입력 후 Firestore 저장 | 입력 UI 구현됨, 저장 미구현 | **10주차 (앞당김)** |
| 나탈 차트 / 점성술 분석 | Prokerala API로 행성·하우스·Ascendant 계산, 360° 시각화 | API 부분 구현 (응답 키 검증 필요) | 10주차 검증 |
| 오늘의 운세 | Prokerala Daily Horoscope + 캐시 | 부분 구현 | 12주차 캐시 |
| **궁합 분석 (Synastry)** | 두 사용자 나탈 차트 비교, 4축 점수 및 설명 제공 | 화면 + API 부분 구현 (점수 휴리스틱) | **11주차 실데이터 연결** |
| **친구 추가 및 소셜 연결** | 랜덤 코드 검색, 친구 요청·수락, 즐겨찾기 3명 | 정적 UI만 존재 | **11주차** |
| **AI 랜덤 질문** | AI 생성 질문 3개 + 사용자 질문 1개, Firebase Function 경유 | 정적 카드 UI | **12주차** |
| **SNS 공유 이미지 생성** | 운세·궁합 결과를 이미지 카드로 만들어 공유 | 폴더만 존재, 미구현 | **13주차** |

### 2.2 선택 기능 (추가 구현 — 일정 여유 시)

| 기능 | 설명 | 예정 주차 |
|------|------|-----------|
| 카카오 OAuth 실 로그인 | `kakao_flutter_sdk_user` 연동 | 13주차 이후 또는 후속 |
| AI 성격 리포트 (장문) | 나탈 차트 기반 LLM 분석 (약 1,000자 이상) | 13주차 여유 시 |
| Lottie 우주 애니메이션 | 나의 행성, 친구 차트 인터랙션 애니메이션 | 12주차 후반 준비, 13주차 적용 |
| 푸시 알림 (FCM) | 오늘의 운세 도착, 친구 요청 수락 이벤트 | 12주차 선택 |
| 다크 모드 / 컬러 테마 | 흑백 이외 색상 테마 | 12주차 후반 시안, 13주차 적용 |

### 2.3 명시적 제외 사항

- 자체 백엔드 REST 서버 구축 (Firebase 관리형 서비스로 대체)
- go_router 선언형 라우팅 [추후 확인 필요: 도입 주차 미결정]
- 결제/구독 기능

### 2.4 실행 우선순위 재정렬 원칙

이번 버전에서는 화면 수를 더 늘리기보다, **나중 기능이 막히는 지점을 먼저 제거하는 순서**로 실행한다.

| 우선순위 | 먼저 처리할 항목 | 이유 |
|---------|------------------|------|
| **P0** | Prokerala 실응답 검증 + 파서 보정 + fixture 갱신 | 현재 `natal-chart`, `daily`, `synastry` 응답 키가 일부 추정값이라, 이 검증이 늦어지면 뒤 기능이 전부 추정 데이터 위에 쌓인다 |
| **P0** | `client_secret` 제거 + Cloud Functions 프록시 이전 | 현재 구조는 릴리즈 불가 수준의 보안 리스크를 가진다 |
| **P0** | `users` / `charts` / `friendCodes` 스키마 확정 | 출생정보 저장, 친구 검색, 차트 캐시가 전부 이 스키마 위에 올라간다 |
| **P0** | 출생지 → 좌표 변환(`places-resolve`) 도입 | 지금은 서울/부산 폴백이라 차트 정확도가 보장되지 않는다 |
| **P1** | `chartVersion` / `chartPairVersion` 기반 캐시 무효화 | 중복 API 호출과 잘못된 궁합 캐시를 막는다 |
| **P1** | 친구 코드 유일성 + 요청 수락 트랜잭션 | Firestore에서 중복 친구 코드/중복 friendship이 생기기 쉬운 구간이다 |
| **P2** | AI 질문, 공유 이미지, 카카오 OAuth, 디자인 확장 | 핵심 흐름이 안정된 뒤 붙이되, 12주차 후반부터 자산/토큰/레이아웃 초안을 미리 준비해 13주차 과밀을 피한다 |

---

## 3. 기술 스택

### 3.1 현재 도입된 스택 (pubspec.yaml 실측)

| 영역 | 기술 | 버전 |
|------|------|------|
| 클라이언트 프레임워크 | Flutter / Dart | SDK `^3.11.1`, Dart 3.5+ |
| 상태 관리 | flutter_riverpod | ^2.5.1 |
| HTTP 클라이언트 | dio | ^5.7.0 |
| 환경 변수 | flutter_dotenv | ^5.2.1 |
| 날짜/포맷 | intl | ^0.19.0 |
| 지오코딩 | geocoding | ^3.0.0 (등록만, 호출 코드 없음) |
| 모델 어노테이션 | freezed_annotation, json_annotation | 등록만, 코드 생성 미사용 |
| 코드 생성 (dev) | build_runner, freezed, json_serializable, riverpod_generator | - |

### 3.2 예정 도입 스택

| 패키지 | 용도 | 도입 예정 |
|--------|------|-----------|
| firebase_core | Firebase 초기화 | **10주차** |
| cloud_firestore | 사용자·차트·친구·운세 저장 | **10주차** |
| flutter_secure_storage | 토큰 등 민감 정보 저장 | 10주차 |
| firebase_messaging | FCM 푸시 알림 | 12주차 선택 |
| shared_preferences | 운세 캐시, 앱 설정 | 12주차 |
| share_plus / screenshot | 결과 이미지 공유 | 13주차 |
| lottie | 우주·행성 애니메이션 | 13주차 |
| kakao_flutter_sdk_user | 카카오 소셜 로그인 | 후순위 |
| go_router | 선언형 라우팅 | [추후 확인 필요] |
| cached_network_image | 프로필 이미지 캐싱 | [추후 확인 필요] |

---

## 4. 백엔드 구조

### 4.1 백엔드 선택 배경

**조건**: 백엔드 개발자 없음, AI 코드 생성으로 개발, 무료 플랜, Docker 고려, 현재 일정 유지.

아래 주요 옵션을 비교 검토했다.

| 항목 | Firebase | Supabase Cloud | Appwrite Cloud | PocketBase + Railway |
|------|----------|----------------|----------------|----------------------|
| 무료 플랜 | ✅ Spark (관대함) | ✅ Free (500MB) | ✅ Free (75K MAU) | ⚠️ Railway $5 크레딧/월 |
| Docker 지원 | ❌ (관리형) | ✅ (self-host) / Cloud도 가능 | ✅ Docker Compose | ✅ 단일 바이너리 |
| Flutter 공식 SDK | ✅ 최고 수준 | ✅ `supabase_flutter` | ✅ `appwrite` | ⚠️ 비공식 REST |
| API 프록시 기능 | ✅ Cloud Functions | ✅ Edge Functions | ✅ Functions | ⚠️ 제한적 |
| AI 코드 생성 용이성 | ✅ 학습 데이터 매우 풍부 | ✅ 풍부 | 보통 | 보통 |
| 기존 계획과 연계 | ✅ 이미 계획됨 | 교체 필요 | 교체 필요 | 교체 필요 |
| 운영 복잡도 | 최저 (서버리스) | 낮음 | 낮음 | 중간 |

### 4.2 결정: Firebase + Cloud Functions

**Firebase (Firestore + Auth + Cloud Functions)** 를 주 백엔드로 채택한다.

**선택 이유:**
1. **일정 무중단**: 이미 계획된 스택이므로 일정 변경 없음
2. **Flutter SDK 최고 수준**: `firebase_core`, `cloud_firestore` 등 공식 SDK로 AI 코드 생성이 가장 쉬움
3. **API 프록시 가능**: Cloud Functions(Node.js/TypeScript)로 Prokerala `client_secret` 서버에 격리 — APK 바이너리 노출 문제 해결
4. **관리형 서비스**: Docker/서버 운영 불필요 → 백엔드 개발자 없는 환경에 최적
5. **무료 Spark 플랜 충분**: MVP 범위에서 충분 (Firestore 1GB, 읽기 50K/일, Cloud Functions 125K 호출/월)

> ⚠️ Docker를 꼭 사용해야 할 경우: **Supabase Cloud Free** 또는 **Appwrite Cloud Free** 를 대안으로 고려할 수 있다. 단, Flutter SDK 전환 비용(약 1~2주)이 발생한다.

### 4.3 Firebase 무료 플랜 (Spark) 한도

| 항목 | 무료 한도 | MVP 예상 사용량 |
|------|-----------|-----------------|
| Firestore 저장 | 1 GB | ~수십 MB |
| Firestore 읽기 | 50,000 건/일 | ~수백~수천 건/일 |
| Firestore 쓰기 | 20,000 건/일 | ~수십~수백 건/일 |
| Cloud Functions 호출 | 125,000 건/월 | ~수천 건/월 |
| Cloud Functions 컴퓨팅 | 40,000 GB-초/월 | 충분 |
| FCM 푸시 | 무제한 | - |

### 4.4 Cloud Functions 활용 계획

Prokerala API 및 OpenAI API 를 클라이언트가 직접 호출하는 대신, **Cloud Functions를 프록시로 사용**하여 API 키 노출을 방지한다. AI(GPT-4/Claude)로 Function 코드를 생성하면 된다.

```
[Flutter App]
    │
    ├── Firebase Firestore      (사용자·차트·친구·운세 저장)
    ├── Firebase Auth           (세션 관리, 추후 카카오 custom token)
    │
    └── Firebase Cloud Functions (Node.js / TypeScript)
            ├── prokerala-natal    → Prokerala /v2/astrology/natal-chart
            ├── prokerala-horoscope → Prokerala /v2/horoscope/daily
            ├── prokerala-synastry → Prokerala /v2/astrology/synastry-chart
            ├── ai-questions       → OpenAI API (랜덤 질문 생성)
            └── [예정] ai-report   → OpenAI API (성격 리포트)
```

> **10주차 전환 계획**: 현재 앱에서 Prokerala를 직접 호출하는 `ProkeralaApi` 클래스를 Cloud Functions 호출로 교체한다. `.env` 의 `PROKERALA_CLIENT_SECRET` 을 Firebase 환경 변수로 이전한다.

### 4.5 초기 DB 시딩 전략 (로그인 없이 개발 진행)

카카오 OAuth 실 연동 전까지, 다음 방법으로 테스트 사용자 데이터를 직접 입력하여 개발을 진행한다.

1. **Firebase Console** → Firestore → `users` 컬렉션에 테스트 문서 직접 생성
2. 앱 로그인 화면은 "개발 모드 진입" 버튼으로 하드코딩된 uid로 진입
3. 실제 출생 정보는 `BirthInfo.demo()` 서울 기본값 또는 온보딩 입력값 활용
4. 카카오 OAuth는 13주차 이후 연결

---

## 5. 시스템 구조

### 5.1 전체 아키텍처

```
┌─────────────────────────────────┐
│          Flutter App            │
│  (Android / iOS / Web)         │
└────────────┬────────────────────┘
             │
     ┌───────┴────────┐
     │  Firebase SDK  │
     └───────┬────────┘
             │
    ┌────────┴──────────────────────────┐
    │         Firebase (Google Cloud)   │
    │                                   │
    │  ┌──────────────┐                 │
    │  │  Firestore   │  사용자·차트·   │
    │  │     DB       │  친구·운세      │
    │  └──────────────┘                 │
    │  ┌──────────────┐                 │
    │  │ Firebase Auth│  세션 관리      │
    │  └──────────────┘                 │
    │  ┌──────────────────────────────┐ │
    │  │   Cloud Functions (Node.js)  │ │
    │  │  - Prokerala API 프록시      │ │
    │  │  - OpenAI API 프록시         │ │
    │  └──────────────────────────────┘ │
    │  ┌──────────────┐                 │
    │  │     FCM      │  푸시 알림      │
    │  └──────────────┘                 │
    └───────────────────────────────────┘

    외부 API (Cloud Functions 경유)
    ┌──────────────────────┐
    │ Prokerala Astrology  │
    │ OpenAI GPT-4o        │
    │ Google Geocoding     │
    │ (추후) Kakao Login   │
    └──────────────────────┘
```

### 5.2 폴더 구조 (실측)

```
stellara/
├── lib/
│   ├── main.dart               # 진입점: dotenv 로드 + ProviderScope
│   ├── app.dart                # MaterialApp + 흑백 ThemeData
│   ├── core/                   # 도메인 무관 공통 인프라
│   │   ├── env/env.dart        # .env 키 단일 진입점
│   │   ├── http/dio_client.dart # Prokerala 전용 Dio + 인터셉터
│   │   ├── theme/app_theme.dart # 흑백 팔레트 + Material3
│   │   ├── ui/app_alerts.dart
│   │   ├── utils/astro_text.dart
│   │   └── widgets/panel.dart
│   └── features/               # 도메인별 모듈
│       ├── auth/               # LOGIN-001
│       ├── onboarding/         # ONBOARDING-001, NAV-001
│       ├── home/               # MAIN-001
│       ├── astrology/          # ASTROLOGY-001
│       ├── horoscope/          # TODAY-001
│       ├── compatibility/      # MATCH-001
│       ├── friends/            # FRIEND-001
│       ├── content/            # CONTENT-001
│       ├── profile/            # MYPAGE-001
│       └── share/              # SHARE-001 (폴더만, 파일 없음)
├── functions/                  # [예정 10주차] Firebase Cloud Functions
│   ├── src/
│   │   ├── prokerala.ts        # Prokerala API 프록시
│   │   └── ai.ts               # OpenAI 프록시
│   └── package.json
├── test/
├── assets/                     # [추후 확인 필요: 현재 파일 0건]
├── pubspec.yaml
├── .env / .env.example
└── docs/
    ├── README.md
    ├── SDD.md
    ├── MVP.md
    ├── TASKS.md
    └── SDD_input_codebase_overview.md
```

### 5.3 레이어드 아키텍처 (features 내부)

의존 방향: `presentation → application → data → domain` (단방향)

| 레이어 | 역할 |
|--------|------|
| `presentation` | 화면 위젯, UI 로직 |
| `application` | Provider 정의, 상태 조합 |
| `data` | Repository, API 호출, JSON 파싱 |
| `domain` | 순수 데이터 모델 |
| `fixtures` | 오프라인/디버그 더미 데이터 |

### 5.4 Riverpod Provider 의존 그래프 (실측)

```
prokeralaTokenRepoProvider
        │ tokenProvider 콜백
prokeralaDioProvider (인터셉터 부착)
        │
prokeralaApiProvider
        ├── astrologyRepositoryProvider
        │         └── natalChartProvider.family<NatalChart, BirthInfo>
        │                    ↑
        │         myNatalChartProvider
        │
        ├── horoscopeRepositoryProvider → todayHoroscopeProvider
        │                                  ↑ selectedSignSlugProvider
        └── synastryRepositoryProvider
                  └── synastryProvider.family<SynastryResult, PartnerPair>

currentBirthInfoProvider  // StateProvider<BirthInfo>
// ⚠️ 메모리 전용. 앱 종료 시 초기화. 10주차 Firestore 연결 예정
```

> **10주차 이후**: `prokeralaApiProvider` 아래의 `data` 계층은 Cloud Functions 호출로 교체되고, `currentBirthInfoProvider`는 Firestore Stream으로 교체될 예정이다.

### 5.5 화면 진입 흐름 (실측)

```
main.dart → Env.load() → ProviderScope → StellaraApp
  └─ LoginScreen [LOGIN-001]
        └─ "시작하기" (현재: 데모 버튼)
              └─ OnboardingScreen [ONBOARDING-001]
                    └─ 출생정보 입력 → currentBirthInfoProvider.set()
                          └─ AppShell [NAV-001] (하단 4탭)
                                ├─ MainHomeScreen [MAIN-001]
                                │       └─ 행성 탭 → AstrologyScreen [ASTROLOGY-001]
                                ├─ RandomQuestionScreen [CONTENT-001]
                                ├─ TodayScreen [TODAY-001]
                                └─ MyPageScreen [MYPAGE-001]
```

---

## 6. 화면/기능 구조

### 6.1 화면 매트릭스

| 화면 ID | 화면명 | 파일 경로 | 구현 상태 | 레이어 완성도 |
|---------|--------|-----------|-----------|---------------|
| LOGIN-001 | 로그인 | `auth/presentation/login_screen.dart` | 목업 UI | presentation만 |
| ONBOARDING-001 | 출생 정보 입력 | `onboarding/presentation/onboarding_screen.dart` | UI 구현 | presentation만 |
| NAV-001 | 하단 4탭 | `onboarding/app_shell.dart` | **구현됨** | - |
| MAIN-001 | 메인 홈 | `home/presentation/main_home_screen.dart` | 목업 UI | presentation만 |
| ASTROLOGY-001 | 나탈 차트 | `astrology/presentation/astrology_screen.dart` | 부분 구현 | 전 레이어 (API 매핑 추정) |
| TODAY-001 | 오늘의 운세 | `horoscope/presentation/today_screen.dart` | 부분 구현 | 전 레이어 (API 매핑 추정) |
| MATCH-001 | 궁합 결과 | `compatibility/presentation/match_screen.dart` | 부분 구현 | 전 레이어 (점수 휴리스틱) |
| FRIEND-001 | 친구 관리 | `friends/presentation/friend_screen.dart` | 정적 UI | presentation만 |
| CONTENT-001 | 랜덤 질문 | `content/presentation/random_question_screen.dart` | 정적 UI | presentation만 |
| MYPAGE-001 | 마이페이지 | `profile/presentation/my_page_screen.dart` | 목업 UI | presentation만 |
| SHARE-001 | 결과 공유 | `share/presentation/` (폴더만, 파일 없음) | **미구현** | - |

### 6.2 주요 화면 기능 상세

#### LOGIN-001 — 로그인
- **현재**: "데모 데이터로 시작" 버튼 1개 (목업)
- **10주차**: Firestore 직접 시딩 방식으로 로그인 우회, 구조만 유지
- **후순위**: 카카오 OAuth 실 연동

#### ONBOARDING-001 — 출생 정보 입력
- 닉네임, 생년월일, 출생시간, 출생지 입력 UI 구현됨
- 현재 좌표 폴백: `BirthInfo.demo()` → 서울특별시 (37.5665, 126.9780, UTC+09:00) (코드 실측)
- 출생지 → 좌표 변환: `geocoding` 패키지 등록만 됨, 실제 호출 없음 [추후 확인 필요]

#### ASTROLOGY-001 — 나탈 차트
- `NatalChart` → `natal_chart_painter.dart` (CustomPainter) 360° 시각화
- API: Cloud Functions 프록시 경유 예정 (10주차)
- Fixture fallback 패턴 유지

#### MATCH-001 — 궁합 결과
- Synastry 4축 점수: 감정/대화/연애/총점
- ⚠️ 어스펙트 가중치 임의값 (코드 주석 명시) → 11주차 실데이터 연결 시 정교화

#### CONTENT-001 — 랜덤 질문
- **12주차**: Cloud Functions → OpenAI API 호출로 AI 질문 3개 생성
- 사용자 직접 질문 1개 입력 기능

#### SHARE-001 — 결과 공유
- **13주차**: `screenshot` + `share_plus` 패키지로 구현
- 오늘의 운세, 궁합 결과, 나탈 차트 이미지 공유

---

## 7. API 설계 보강

### 7.1 설계 기준

- **[실구현]**: 현재 소스코드에 존재하는 네트워크 계약
- **[제안]**: 10주차 이후 바로 구현해야 하는 Cloud Functions 계약
- UI는 계속 `presentation → application → data → domain` 흐름을 유지하고, 화면은 **정규화된 도메인 응답**만 소비한다
- 외부 API raw 응답은 Cloud Functions 또는 Repository에서 정규화한다. 화면은 Prokerala raw JSON에 직접 의존하지 않는다

### 7.2 [실구현] 현재 존재하는 외부 API 목록

> 현재 자체 백엔드 API는 없고, 앱이 Prokerala를 직접 호출한다. 아래 목록은 `lib/features/astrology/data/prokerala_api.dart` 와 각 Repository 실구현 기준이다.

Base URL: `https://api.prokerala.com`  
인증: OAuth2 `client_credentials` → Bearer Token

| 구분 | HTTP | 경로/함수 | 현재 사용처 | 요청 핵심 필드 | 앱이 실제로 쓰는 응답 필드 | 상태 |
|------|------|-----------|-------------|----------------|----------------------------|------|
| 토큰 발급 | POST | `{PROKERALA_TOKEN_URL}` | `ProkeralaTokenRepository.getToken()` | `grant_type`, `client_id`, `client_secret` | `access_token`, `expires_in`, `token_type` | **구현됨** |
| 나탈 차트 | GET | `/v2/astrology/natal-chart` | `AstrologyRepository.getNatalChart()` | `datetime`, `coordinates`, `profile[datetime]`, `profile[coordinates]`, `ayanamsa=0`, `la=en` | `planet_position/planets`, `houses/house_cusps`, `aspects`, `ascendant.sign` | **부분 구현** |
| 행성 위치 | GET | `/v2/astrology/planet-position` | 현재 호출처 없음 | 나탈 차트와 동일 | Big 3 추출 후보 | **정의만 존재** |
| 일일 운세 | GET | `/v2/horoscope/daily` | `HoroscopeRepository.getDaily()` | `sign`, `datetime(UTC)`, `la=en` | `sign`, `horoscope/summary/prediction`, `lucky_color`, `lucky_number`, `mood` | **부분 구현** |
| 궁합 차트 | GET | `/v2/astrology/synastry-chart` | `SynastryRepository.compare()` | `profile[*]`, `partner_profile[*]`, `ayanamsa=0`, `la=en` | `aspects` | **부분 구현** |

> ⚠️ 현재 리스크
> 1. `natal-chart` / `daily` / `synastry` 응답 키는 첫 실호출 검증이 아직 필요하다  
> 2. `planet-position` 은 정의만 있고 미사용 상태라 실제 필요성이 다시 검토돼야 한다  
> 3. `client_secret` 이 앱 런타임에 존재하므로 10주차 이전 구조는 릴리즈 대상이 아니다

### 7.3 [실구현] 앱 내부 서비스 계약

> Cloud Functions 도입 후에도 아래 Dart 메서드 시그니처와 리턴 도메인은 유지하는 것을 기본 원칙으로 한다. 이렇게 해야 UI/Provider 수정 범위를 최소화할 수 있다.

| 레이어 진입점 | 입력 | 출력 | 비고 |
|--------------|------|------|------|
| `ProkeralaTokenRepository.getToken({bool forceRefresh = false})` | 강제 갱신 여부 | `Future<String>` | 메모리 캐시 + 만료 60초 전 재발급 |
| `AstrologyRepository.getNatalChart(BirthInfo birth)` | `BirthInfo` | `Future<NatalChart>` | 실패 시 fixture fallback |
| `HoroscopeRepository.getDaily({required String signSlug, DateTime? date})` | `signSlug`, `date` | `Future<Horoscope>` | 실패 시 fixture fallback |
| `SynastryRepository.compare({required BirthInfo me, required BirthInfo partner})` | `BirthInfo` 2개 | `Future<SynastryResult>` | 실패 시 fixture fallback |

### 7.4 [제안] 우선 구현할 Cloud Functions API

> 아래는 **기술 부채 / 리스크 / 구현 난이도** 기준으로 정리한 10~12주차 대상 API이다.  
> 단순 Firestore read/write 로 끝나는 경우는 DB 섹션에서 다루고, **secret 보호 / 외부 API 호출 / 유일성 보장 / 트랜잭션 집중** 이 필요한 항목만 Functions 로 둔다.

| 우선순위 | Function 이름 | HTTP | 역할 | 구현 이유 |
|---------|---------------|------|------|-----------|
| **P0** | `places-resolve` | POST | 출생지 텍스트 → 좌표 정규화 | 현재 서울/부산 폴백 제거 |
| **P0** | `prokerala-natal` | POST | 나탈 차트 조회 + `chartVersion` 캐시 | 응답 스키마 확정, secret 보호 |
| **P0** | `prokerala-horoscope` | POST | 일일 운세 조회 + 일자별 캐시 | secret 보호, 크레딧 절약 |
| **P1** | `prokerala-synastry` | POST | 궁합 조회 + `chartPairVersion` 캐시 | synastry 비용 절감, 점수 계산 일원화 |
| **P1** | `friend-code-issue` | POST | 유일한 친구 코드 발급/재발급 | Firestore 단독으로는 유일성 레이스가 생기기 쉬움 |
| **P1** | `friend-request-accept` | POST | 요청 상태 변경 + friendship 생성 | 중복 friendship 방지용 트랜잭션 |
| **P2** | `ai-questions` | POST | AI 랜덤 질문 3개 생성 | 12주차 기능 |
| **P3** | `ai-report` | POST | 장문 성격 리포트 생성 | 선택 기능 |

### 7.5 [제안] 요청/응답 형식 초안

> 응답은 모두 `data` 래퍼를 사용한다. 현재 Repository가 `(json['data'] as Map?) ?? json` 패턴을 사용하므로, 이 구조를 지키면 마이그레이션이 쉽다.

#### `places-resolve` [제안]

요청:

```json
{
  "query": "서울특별시",
  "locale": "ko-KR"
}
```

응답:

```json
{
  "data": {
    "placeName": "서울특별시",
    "latitude": 37.5665,
    "longitude": 126.9780,
    "countryCode": "KR",
    "source": "google-geocoding"
  }
}
```

비고:
- MVP에서는 한국 사용자 기준으로 `utcOffset="+09:00"` 를 앱에서 유지해도 된다
- 해외 지역까지 확장할 경우 timezone lookup API를 별도 추가한다

#### `prokerala-natal` [제안]

요청:

```json
{
  "uid": "demo-una",
  "birthInfo": {
    "nickname": "물병자리의 꿈",
    "dateTimeLocal": "1995-02-15T14:30:00",
    "latitude": 37.5665,
    "longitude": 126.9780,
    "utcOffset": "+09:00",
    "placeName": "서울특별시"
  },
  "forceRefresh": false
}
```

응답:

```json
{
  "data": {
    "chartVersion": "1995-02-15T14:30:00_37.5665_126.9780_+09:00",
    "source": "live",
    "cachedAt": "2026-05-08T11:30:00Z",
    "chart": {
      "ascendantSign": "Libra",
      "sunSign": "Aquarius",
      "moonSign": "Cancer",
      "planets": [
        { "name": "Sun", "sign": "Aquarius", "degree": 326.4, "house": 5 }
      ],
      "houses": [
        { "house": 1, "degree": 180.0, "sign": "Libra" }
      ],
      "aspects": [
        {
          "planetA": "Sun",
          "planetB": "Moon",
          "aspect": "Square",
          "orb": 1.2
        }
      ]
    }
  }
}
```

비고:
- Function 내부에서 Prokerala raw 응답을 저장/검증하고, 앱에는 `NatalChart` 형태의 정규화 응답만 내려준다
- 10주차 초기에는 `rawSnapshot` 을 개발 환경에 한해 Firestore에 함께 저장해 파서 검증에 사용한다

#### `prokerala-horoscope` [제안]

요청:

```json
{
  "uid": "demo-una",
  "signSlug": "aquarius",
  "date": "2026-05-08",
  "forceRefresh": false
}
```

응답:

```json
{
  "data": {
    "cacheKey": "demo-una_aquarius_2026-05-08",
    "source": "live",
    "horoscope": {
      "signSlug": "aquarius",
      "signName": "Aquarius",
      "date": "2026-05-08",
      "summary": "조용하지만 흐름이 안정적인 하루예요.",
      "luckyColor": "indigo",
      "luckyNumber": 7,
      "mood": "calm"
    }
  }
}
```

#### `prokerala-synastry` [제안]

요청:

```json
{
  "me": {
    "nickname": "물병자리의 꿈",
    "dateTimeLocal": "1995-02-15T14:30:00",
    "latitude": 37.5665,
    "longitude": 126.9780,
    "utcOffset": "+09:00",
    "placeName": "서울특별시"
  },
  "partner": {
    "nickname": "바다고래",
    "dateTimeLocal": "1996-08-21T09:15:00",
    "latitude": 35.1796,
    "longitude": 129.0756,
    "utcOffset": "+09:00",
    "placeName": "부산광역시"
  },
  "forceRefresh": false
}
```

응답:

```json
{
  "data": {
    "pairKey": "demo-una__demo-whale",
    "chartPairVersion": "v1__v2",
    "source": "live",
    "result": {
      "totalScore": 78,
      "emotionScore": 84,
      "communicationScore": 71,
      "romanceScore": 80,
      "summary": "서로의 결이 비교적 잘 맞는 편입니다."
    }
  }
}
```

비고:
- 점수 산출 로직은 클라이언트가 아니라 Function 또는 공용 Repository에서 한 곳만 관리한다
- 친구 기능이 붙기 전에는 현재 `MATCH-001` 처럼 직접 입력값을 사용하고, 이후에는 친구 프로필을 Firestore에서 읽어 동일 형식으로 호출한다

#### `friend-code-issue` [제안]

요청:

```json
{
  "uid": "demo-una",
  "nickname": "물병자리의 꿈",
  "regenerate": false
}
```

응답:

```json
{
  "data": {
    "uid": "demo-una",
    "friendCode": "AQU2024",
    "issuedAt": "2026-05-08T11:30:00Z"
  }
}
```

#### `friend-request-accept` [제안]

요청:

```json
{
  "requestId": "req_20260508_001",
  "actedByUid": "demo-una"
}
```

응답:

```json
{
  "data": {
    "requestId": "req_20260508_001",
    "status": "accepted",
    "friendshipId": "demo-una__demo-whale",
    "uids": ["demo-una", "demo-whale"],
    "acceptedAt": "2026-05-08T11:31:00Z"
  }
}
```

---

## 8. DB 설계 보강

> **현재 원격 DB는 아직 미도입 상태**이며, 아래는 `BirthInfo`, `NatalChart`, `Horoscope`, `SynastryResult` 도메인 모델을 그대로 수용하도록 보강한 Firestore 설계안이다.

### 8.1 저장 원칙

| 저장소 | 용도 | 도입 시점 | 비고 |
|--------|------|-----------|------|
| Firebase Firestore | 사용자 프로필, 차트 캐시, 친구 관계, 운세 캐시 | **10주차** | 앱의 주 저장소 |
| flutter_secure_storage | 카카오/커스텀 토큰 등 민감 정보 | 10주차 이후 | 현재는 실사용 없음 |
| SharedPreferences | 당일 운세 로컬 캐시, 앱 설정 | 12주차 | Firestore 읽기 절약용 보조 캐시 |

설계 원칙:

1. `BirthInfo` 는 **`dateTimeLocal + utcOffset`** 형태를 유지한다  
   이유: Prokerala 호출 시 출생 "현지 시각"과 offset이 모두 필요하다. Timestamp 하나만 저장하면 원래 입력 시각 의미가 흐려질 수 있다.

2. 차트/궁합 캐시는 **버전 문자열 기반**으로 무효화한다  
   이유: birthInfo 변경 시 오래된 차트를 TTL만으로 관리하면 잘못된 결과가 남을 수 있다.

3. 유일성 보장이 필요한 값은 **보조 인덱스 컬렉션**으로 분리한다  
   이유: `friendCode` 는 단일 `users` 컬렉션 필드만으로는 충돌 방지와 빠른 조회가 어렵다.

### 8.2 주요 컬렉션 요약

| 컬렉션 | 상태 | 역할 | 핵심 관계 |
|--------|------|------|-----------|
| `users` | **[제안] 필수** | 사용자 프로필 + 출생정보 + 즐겨찾기 | 1 user ↔ 1 current chart |
| `friendCodes` | **[제안] 필수** | 친구 코드 유일성 보장용 인덱스 | 1 code ↔ 1 user |
| `charts` | **[제안] 필수** | 현재 사용자 나탈 차트 캐시 | 1 user ↔ 1 chart snapshot |
| `dailyFortunes` | **[제안] 필수** | 날짜별 운세 캐시 | 1 user ↔ N fortunes |
| `friendRequests` | **[제안] 필수** | 친구 요청 상태 관리 | user ↔ user |
| `friendships` | **[제안] 필수** | 수락된 친구 관계 | N:M 관계 연결 |
| `synastryCaches` | **[제안] 권장** | 궁합 결과 캐시 | pairKey + chartPairVersion |
| `aiQuestionSets` | **[제안] 선택** | AI 질문 결과 저장/재사용 | 12주차 이후 |

### 8.3 컬렉션 구조 초안

#### `users/{uid}` — 사용자 프로필

```yaml
users/{uid}
  uid: String
  authProvider: String           # "dev" | "kakao" | "firebase"
  nickname: String
  friendCode: String             # 현재 활성 코드
  profileCompleted: bool
  birthInfo:
    dateTimeLocal: String        # "1995-02-15T14:30:00"
    utcOffset: String            # "+09:00"
    placeName: String
    latitude: double
    longitude: double
    geocodingSource: String      # "manual" | "google-geocoding" | "fallback"
    lastResolvedAt: Timestamp?
  favoriteIds: [String]          # 최대 3명
  activeChartVersion: String?    # charts/{uid}.chartVersion 과 동기화
  createdAt: Timestamp
  updatedAt: Timestamp
```

주의:
- `favoriteIds` 는 반드시 **수락된 friendship 의 상대 uid만** 포함해야 한다
- `profileCompleted=false` 이면 로그인 후 온보딩으로 유도한다

#### `friendCodes/{code}` — 친구 코드 인덱스

```yaml
friendCodes/{code}
  code: String
  uid: String
  nicknameSnapshot: String
  active: bool
  createdAt: Timestamp
  updatedAt: Timestamp
```

주의:
- `friend-code-issue` Function 또는 Firestore transaction 으로만 생성/재발급한다
- 코드 검색은 `users.friendCode` 스캔이 아니라 이 컬렉션 단건 조회를 사용한다

#### `charts/{uid}` — 현재 차트 캐시

```yaml
charts/{uid}
  uid: String
  chartVersion: String
  birthInfoSnapshot:
    dateTimeLocal: String
    utcOffset: String
    latitude: double
    longitude: double
    placeName: String
  source: String                 # "live" | "fixture"
  provider: String               # "prokerala"
  sunSign: String
  moonSign: String
  ascendantSign: String
  planets: [
    { name: String, sign: String, degree: double, house: int? }
  ]
  houses: [
    { house: int, degree: double, sign: String }
  ]
  aspects: [
    { planetA: String, planetB: String, aspect: String, orb: double }
  ]
  rawSnapshot: Map?              # 10주차 파서 검증용, 안정화 후 제거 가능
  cachedAt: Timestamp
  updatedAt: Timestamp
```

주의:
- `chartVersion` 예시: `1995-02-15T14:30:00_37.5665_126.9780_+09:00`
- `users.activeChartVersion` 과 같지 않으면 stale 데이터로 간주한다

#### `dailyFortunes/{uid}_{signSlug}_{yyyyMMdd}` — 운세 캐시

```yaml
dailyFortunes/{uid}_{signSlug}_{yyyyMMdd}
  uid: String
  signSlug: String
  signName: String
  date: String                   # "2026-05-08"
  summary: String
  luckyColor: String
  luckyNumber: int
  mood: String
  source: String                 # "live" | "fixture"
  cachedAt: Timestamp
```

주의:
- 앱 재실행 전후 모두 같은 날짜/같은 별자리면 이 문서를 먼저 확인한다
- 로컬 `SharedPreferences` 는 이 문서의 보조 캐시로만 사용한다

#### `friendRequests/{requestId}` — 친구 요청

```yaml
friendRequests/{requestId}
  fromUid: String
  toUid: String
  pairKey: String                # min(uidA, uidB)__max(uidA, uidB)
  status: String                 # "pending" | "accepted" | "rejected" | "canceled"
  message: String?
  createdAt: Timestamp
  actedAt: Timestamp?
  updatedAt: Timestamp
```

주의:
- 동일 `pairKey` 에 대해 동시에 `pending` 이 2개 생기지 않도록 막아야 한다
- `accepted` 로 바뀌는 순간 `friendships/{pairKey}` 생성이 함께 일어나야 한다

#### `friendships/{pairKey}` — 수락된 친구 관계

```yaml
friendships/{pairKey}
  pairKey: String
  uids: [String, String]         # 정렬 보장
  createdAt: Timestamp
  createdFromRequestId: String
```

주의:
- 문서 ID 자체를 `pairKey` 로 쓰면 중복 friendship 생성이 자연스럽게 방지된다
- 친구 목록은 `uids array-contains {myUid}` 쿼리로 조회한다

#### `synastryCaches/{pairKey}_{chartPairVersion}` — 궁합 캐시

```yaml
synastryCaches/{pairKey}_{chartPairVersion}
  pairKey: String
  userIds: [String, String]
  myChartVersion: String
  partnerChartVersion: String
  totalScore: int
  emotionScore: int
  communicationScore: int
  romanceScore: int
  summary: String
  source: String                 # "live" | "fixture"
  cachedAt: Timestamp
```

주의:
- 둘 중 한 명이라도 출생정보를 수정하면 `chartPairVersion` 이 바뀌므로 자동으로 cache miss 가 난다
- Synastry API 비용이 높을 가능성이 크므로 11주차 이전에 구조를 먼저 확정한다

### 8.4 데이터 관계 정리

| 관계 | 설명 |
|------|------|
| `users 1 : 1 charts` | 각 사용자는 현재 차트 스냅샷 1개를 가진다 |
| `users 1 : N dailyFortunes` | 사용자/별자리/날짜 조합마다 운세 캐시가 1개 생긴다 |
| `users 1 : N friendRequests(sent)` | 사용자는 여러 요청을 보낼 수 있다 |
| `users 1 : N friendRequests(received)` | 사용자는 여러 요청을 받을 수 있다 |
| `users N : M friendships` | `friendships/{pairKey}` 로 친구 관계를 표현한다 |
| `users N : M synastryCaches` | 친구 쌍과 차트 버전 조합별로 궁합 캐시가 생긴다 |
| `users 1 : 1 friendCodes` | 활성 친구 코드는 보조 인덱스로 관리한다 |

### 8.5 구현 시 필요한 제약 / 인덱스 / 트랜잭션

필수 제약:

1. `favoriteIds.length <= 3`
2. `favoriteIds` 는 반드시 `friendships` 에 존재하는 상대 uid만 허용
3. `friendCodes/{code}` 는 활성 사용자 하나에만 연결
4. `friendships/{pairKey}` 는 중복 생성 금지
5. `charts.chartVersion` 이 바뀌면 기존 `synastryCaches` 는 재사용하지 않음

권장 인덱스:

- `friendRequests`: `(toUid, status, createdAt desc)`
- `friendRequests`: `(fromUid, status, createdAt desc)`
- `friendships`: `uids array-contains`

권장 트랜잭션 위치:

- 친구 코드 발급/재발급: `friendCodes` + `users.friendCode` 동시 갱신
- 친구 요청 수락: `friendRequests.status` 변경 + `friendships/{pairKey}` 생성
- 출생정보 수정: `users.birthInfo` 변경 + `users.activeChartVersion` 갱신 + `charts/{uid}` stale 처리

### 8.6 초기 데이터 시딩 방법 (10주차)

1. Firebase Console 에서 `users` 4건을 먼저 생성한다
2. 각 사용자에 대해 `friendCodes/{code}` 인덱스를 같이 만든다
3. `charts/{uid}` 는 첫 앱 실행 또는 `prokerala-natal` 첫 성공 시 자동 생성한다
4. `LoginScreen` 의 개발 모드 진입은 uid 입력 또는 하드코딩 uid 선택 방식으로 시작한다

### 8.7 현재 로컬 데이터 생명주기

| 데이터 | 저장 위치 | 앱 종료 시 |
|--------|-----------|------------|
| 사용자 출생정보 | `currentBirthInfoProvider` (메모리) | **소멸** |
| 나탈 차트 결과 | `FutureProvider` 캐시 | **소멸** |
| Prokerala 토큰 | 메모리 캐시 | **소멸** |

---

## 9. 예외 처리 방향

### 9.1 현재 구현된 예외 처리

| 상황 | 처리 방식 | 구현 위치 |
|------|-----------|-----------|
| 환경 변수 누락 | `_EnvErrorApp` 안내 화면 표시 | `core/env/env.dart` |
| API 401 인증 실패 | 토큰 갱신 1회 재시도 → 실패 시 다이얼로그 | `AuthInterceptor` |
| API 429 요청 제한 | `Retry-After` 대기 후 재시도 | `RateLimitInterceptor` |
| API 호출 실패 전반 | fixture 데이터 fallback (빈 화면 방지) | 각 Repository |

### 9.2 Fixture Fallback 패턴 (모든 Repository 공통)

```
kDebugMode && USE_FIXTURE_IN_DEBUG=true → fixture 즉시 반환 (네트워크 미사용)
실호출 실패 (네트워크 오류 / 파싱 실패) → catch → fixture 반환
```

> Prokerala sandbox의 1월 1일 제약도 이 패턴으로 처리됨.

### 9.3 예정 예외 처리

| 상황 | 처리 방향 |
|------|-----------|
| Firestore 연결 실패 | 로컬 캐시 우선, 오프라인 안내 배너 |
| Cloud Functions 타임아웃 | "잠시 후 다시 시도" 메시지 표시 |
| 출생지 좌표 변환 실패 | 서울 기본 좌표 폴백 (BirthInfo.demo() 값) |
| JWT 만료 | 자동 갱신 → 실패 시 로그인 화면 이동 |

### 9.4 주요 리스크

| 리스크 | 심각도 | 대응 방안 |
|--------|--------|-----------|
| Prokerala 응답 키 매핑 추정값 | 높음 | 첫 실호출 raw 응답 저장 → parser 보정 → fixture 갱신 → 매핑 테스트 추가 |
| `client_secret` 앱 내 포함 (현재) | 높음 | **10주차 첫 작업으로 Cloud Functions 프록시 이전** |
| 출생지 좌표 미해결(서울/부산 폴백) | 높음 | `places-resolve` 구현 후 `BirthInfo` 저장 전에 좌표 확정 |
| `BirthInfo` 를 Timestamp 하나로 저장할 위험 | 높음 | `dateTimeLocal + utcOffset` 동시 저장 원칙 적용 |
| 친구 코드 유일성/중복 friendship | 중간 | `friendCodes` 인덱스 + `pairKey` 기반 transaction 적용 |
| `chartVersion` 없는 캐시 재사용 | 중간 | `charts` / `synastryCaches` 에 버전 문자열 도입 |
| Synastry 점수 가중치 임의값 | 중간 | 11주차 실데이터 연결 시 가중치/설명문 재조정 |
| 사용자 데이터 영속성 없음 (현재) | 중간 | 10주차 Firestore 연결 + Provider stream 교체 |
| SHARE-001 미구현 | 낮음 | 13주차 계획, 핵심 흐름 안정 후 구현 |

---

## 10. 협업 규칙

### 10.1 브랜치 전략

| 브랜치 유형 | 네이밍 | 예시 |
|-------------|--------|------|
| 주차별 기능 | `feature/week{N}-{기능명}` | `feature/week10-firestore-db` |
| 버그 수정 | `fix/{설명}` | `fix/natal-chart-parse-error` |
| 핫픽스 | `hotfix/{설명}` | `hotfix/env-missing-crash` |

### 10.2 커밋 메시지 규칙

```
타입(범위): 설명

타입: feat | fix | refactor | style | test | chore | docs
예시:
  feat(firestore): users 컬렉션 초기 시딩 스크립트 추가
  feat(functions): Prokerala natal-chart 프록시 Function 추가
  fix(synastry): 어스펙트 가중치 점수 계산 오류 수정
```

### 10.3 코드 스타일

- `flutter_lints` + `riverpod_lint` 규칙 준수 (`analysis_options.yaml` 기준)
- `flutter analyze`, `flutter test` 통과 후 커밋
- Provider 이름: `{기능}Provider` 규칙
- API 키 및 secret은 코드에 직접 포함 금지 (`.env` 또는 Firebase 환경 변수)

### 10.4 환경 변수 관리

- `.env`는 절대 커밋하지 않는다 (`.gitignore` 처리됨)
- 새 키 추가 시 `.env.example`에 키 이름만 추가 후 커밋
- Prokerala credential 은 `primary → seoyeon → seonwoo → doyeon` 순서의 backup set 을 둘 수 있다
- backup credential 은 무료 플랜과 짧은 프로젝트 기간을 위한 임시 운영 방식이며, 장기적으로는 Cloud Functions 로 이전한다
- Firebase 환경 변수는 `firebase functions:config:set` 으로 설정

### 10.5 개발 시 주의 사항

- 개발 중 `USE_FIXTURE_IN_DEBUG=true`로 Prokerala 크레딧 절약
- Prokerala sandbox는 1월 1일 날짜만 허용 → 다른 날짜는 fixture fallback 자동 처리
- 실응답 검증 시 429가 발생하면 앱은 다음 backup credential 로 1회 전환을 시도한다
- 차트 계산 결과는 `chartVersion` 해시 기반으로 Firestore 캐싱 (중복 API 호출 방지)
- AI (GPT/Claude)로 코드 생성 시 `.env`의 실제 키값은 절대 프롬프트에 포함하지 말 것

---

## 11. 개발 일정 초안

> 일정은 이제 "UI 추가"보다 **막히는 리스크 제거** 순서로 재배치한다.

| 주차 | 기간 | 주요 목표 | 핵심 결과물 |
|------|------|-----------|-------------|
| **9주차** | 5/2~5/8 | Prokerala API + Riverpod 골격 + 흑백 UI | OAuth2 토큰 매니저, 화면 9종 프로토타입 |
| **10주차** | 5/9~5/15 | **응답 계약 검증 + Cloud Functions 프록시 + 사용자/차트 저장소 확정** | Prokerala raw 응답 저장, parser 보정, `places-resolve`, `prokerala-natal`, `prokerala-horoscope`, `users/charts/friendCodes` 스키마, 출생정보 Firestore 저장 |
| **11주차** | 5/16~5/22 | **친구 관계 트랜잭션 + Synastry 캐시 + 즐겨찾기 연결** | `friendRequests`, `friendships`, `synastryCaches`, 친구 코드 검색/수락, MAIN-001 즐겨찾기, MATCH-001 실데이터 연결 |
| **12주차** | 5/23~5/29 | 운세 캐시 고도화 + AI 랜덤 질문 + 후반부 디자인 선행 준비 | `dailyFortunes` 최종화, SharedPreferences 보조 캐시, `ai-questions`, 공유 레이아웃 초안, 컬러/모션 토큰 정리, FCM (선택) |
| **13주차** | 5/30~6/5 | 공유 화면 + 전체 디자인 마감 + 카카오(선택) | SHARE-001 구현, Lottie 애니메이션 적용, 디자인 폴리시 반영, 카카오 OAuth (여유 시) |
| **14주차** | 6/6~ [추후 확인 필요] | 테스트·버그픽스·발표 준비 | 매핑 테스트 보강, README 최종화, 시연 영상, 회귀 점검 |

### 11.1 선행 실행 순서 (리스크 기준)

1. Prokerala 실응답 1회 확보 → raw JSON 저장 → `AstrologyRepository` / `HoroscopeRepository` / `SynastryRepository` 매핑 키 보정
2. `client_secret` 제거 → `prokerala-natal` / `prokerala-horoscope` Cloud Functions 로 이전
3. `users`, `charts`, `friendCodes` 스키마와 문서 ID 규칙 확정
4. `places-resolve` 구현 → 온보딩 입력 시 `BirthInfo.latitude/longitude` 실제값 반영
5. `currentBirthInfoProvider` 를 Firestore 기반으로 교체하고 앱 재실행 유지 확인
6. `friendRequests`, `friendships`, `synastryCaches` 관계와 `pairKey/chartPairVersion` 규칙 확정
7. 이후에 FRIEND-001, MATCH-001, CONTENT-001 순으로 UI 연결
8. 12주차 후반부터 SHARE-001 레이아웃, 컬러 토큰, Lottie 자산 연결점을 선행 준비하고 13주차에 최종 반영

### 11.2 10주차 상세 작업 순서

1. `firebase_core`, `cloud_firestore`, `flutter_secure_storage` 패키지 추가
2. Firebase 프로젝트 연결 + Android/iOS 설정 파일 반영
3. `functions/` 초기화 + Prokerala secret 환경 변수 이전
4. `places-resolve` / `prokerala-natal` / `prokerala-horoscope` Function 작성
5. Prokerala 첫 실응답을 fixture/raw snapshot 으로 저장하고 parser 보정
6. `users`, `charts`, `friendCodes` 문서 구조 확정 + 팀원 4명 시딩
7. 온보딩 입력 → Firestore 저장 연결
8. `currentBirthInfoProvider` → Firestore stream 또는 초기 fetch 기반으로 교체
9. 최소 매핑 테스트 추가 (`natal`, `horoscope`, `synastry`)

### 11.3 후반부 기능 운영 원칙

- 공유, 애니메이션, 컬러 디자인 같은 화려한 요소는 **핵심 데이터 흐름이 안정된 뒤 후반부에 구현**한다
- 다만 13주차에 한꺼번에 몰리지 않도록 **12주차 후반부터 디자인 토큰, 공유 화면 레이아웃, 애니메이션 자산 검토를 선행**한다
- 즉, “후반부 구현”과 “막판 몰아치기 방지”를 동시에 만족하는 완충 일정을 사용한다

### 11.4 기술 부채 관리

| 항목 | 우선순위 | 처리 예정 |
|------|----------|-----------|
| Prokerala 응답 키 매핑 검증 | **높음** | 10주차 첫 실응답 확보 직후 |
| `client_secret` → Cloud Functions 이전 | **높음** | 10주차 |
| `BirthInfo.dateTimeLocal + utcOffset` 저장 규칙 확정 | **높음** | 10주차 |
| `friendCodes` 유일성 인덱스 도입 | **높음** | 10~11주차 |
| `chartVersion` / `chartPairVersion` 캐시 무효화 | **높음** | 10~11주차 |
| `places-resolve` 실호출 코드 작성 | **높음** | 10주차 |
| multi-key fallback 의존 임시 운영 해소 | 중간 | 10주차 Cloud Functions 전환 후 |
| Synastry 점수 가중치 재조정 | 중간 | 11주차 |
| `@visibleForTesting` 또는 parser helper 노출 + 단위 테스트 | 중간 | 10~14주차 |
| freezed 모델 코드 생성 전환 | 중간 | 12주차 이후 |
| go_router 도입 | 낮음 | [추후 확인 필요] |

---

*최초 작성: 2026-05-08 v0.1 / 수정: 2026-05-08 v0.6*  
*기준 브랜치: `feature/week09-prokerala-api`*
