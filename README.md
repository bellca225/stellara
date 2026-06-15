# Stellara ✨

> 출생 정보(생년월일·시간·장소)를 기반으로 한 점성술 모바일 앱 — Flutter로 제작했습니다.

Stellara는 사용자의 출생 차트(natal chart)를 계산해 별자리·운세 정보를 보여주고,
친구를 추가해 서로의 **궁합(synastry)** 을 확인하며, 매일의 운세와 랜덤 질문 콘텐츠를 즐길 수 있는 앱입니다.

---

## 주요 기능

- **출생 차트 / 점성술** — 생년월일·시간·출생지로 네이탈 차트를 계산해 시각화
- **로그인 / 회원가입** — Firebase Authentication 기반 계정 관리
- **친구 관리** — 친구 코드로 추가, 즐겨찾기, 받은 요청 수락/거절
- **궁합 보기** — 친구와의 별자리 궁합 분석
- **오늘의 운세 / 랜덤 질문** — 매일 즐기는 콘텐츠
- **마이페이지** — 프로필 및 출생 정보 관리

---

## 기술 스택

| 영역 | 사용 기술 |
|------|-----------|
| 프레임워크 | Flutter / Dart (`^3.11.1`) |
| 상태 관리 | Riverpod |
| 백엔드 | Firebase (Authentication, Cloud Firestore) |
| 외부 API | Prokerala(점성술), Gemini / OpenAI / Anthropic(AI 콘텐츠) — *선택* |

---

## 시작하기

### 1. 요구 환경

- Flutter SDK (Dart `^3.11.1` 이상, 최신 stable 권장)
- Android 에뮬레이터·기기 또는 Chrome(웹)

### 2. 의존성 설치

```bash
flutter pub get
```

### 3. 환경 변수 파일(`.env`) 생성 — **필수**

이 프로젝트는 `.env` 파일을 에셋으로 사용합니다. 보안상 실제 `.env`는 저장소에 포함하지 않으므로,
함께 제공되는 `.env.example`을 복사해 `.env`를 만들어야 합니다.

```bash
cp .env.example .env
```

기본 설정에서는 외부 유료 API를 호출하지 않고 **내장 샘플 데이터로 동작**하므로,
**키를 비워둔 채로도 앱이 정상 실행**됩니다. 실제 점성술/AI 기능을 켜려면 `.env`에 발급받은 키를 입력하세요.

| 키 | 발급처 | 형식 예시 |
|----|--------|-----------|
| `PROKERALA_CLIENT_ID` / `..._SECRET` | https://api.prokerala.com | 발급된 클라이언트 자격증명 |
| `GEMINI_API_KEY` | https://aistudio.google.com/app/apikey | `AIza...` |
| `OPENAI_API_KEY` | https://platform.openai.com/api-keys | `sk-...` |
| `ANTHROPIC_API_KEY` | https://console.anthropic.com/settings/keys | `sk-ant-...` |

> 키를 채운 뒤 실제 호출을 켜려면 `.env`의 `PROKERALA_REMOTE_ENABLED` / `AI_REMOTE_ENABLED`를 `true`로 변경하세요.

### 4. 실행

```bash
flutter run              # 연결된 기기/에뮬레이터
flutter run -d chrome    # 웹(Chrome)
```

---

## 프로젝트 구조

```
lib/
├─ core/            공통 테마·위젯·유틸·환경설정
└─ features/        기능별 모듈
   ├─ astrology/      출생 차트 / 점성술
   ├─ auth/           로그인 / 회원가입
   ├─ compatibility/  궁합
   ├─ content/        랜덤 질문 등 콘텐츠
   ├─ friends/        친구 관리
   ├─ home/           홈 화면
   ├─ horoscope/      오늘의 운세
   ├─ onboarding/     온보딩
   ├─ profile/        마이페이지
   ├─ share/          공유
   └─ users/          사용자 데이터
```

각 기능 모듈은 `presentation`(화면·위젯) · `application`(상태·로직) · `data`(저장소) · `domain`(모델) 계층으로 나뉩니다.

---

## 라이선스

학습/포트폴리오 목적으로 제작된 프로젝트입니다.
