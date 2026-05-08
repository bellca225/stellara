# Stellara 프로젝트 정리본

## 1. 프로젝트 개요

Stellara는 사용자의 출생 정보(생년월일, 출생 시간, 출생지)를 바탕으로  
나탈 차트, 오늘의 운세, 친구 궁합, AI 질문, 결과 공유를 제공하는 Flutter 앱이다.

현재는 학교 프로젝트용 프로토타입 단계이며,  
핵심 화면 흐름과 Prokerala 연동 골격은 존재하지만 Firebase/Firestore 연동, AI, 공유 기능은 순차적으로 붙여가는 중이다.

## 2. 현재 상태

### 이미 구현된 것

- Flutter 앱 기본 구조
- Riverpod 상태 관리 골격
- Prokerala 직접 호출용 wrapper
- fixture fallback 기반 데모 데이터 흐름
- 로그인, 온보딩, 홈, 점성술 분석, 친구, 궁합, 랜덤 질문, 마이페이지 화면 프로토타입
- Android / Web 실행 검증

### 아직 미구현인 것

- Firebase 연동
- Blaze 기반 서버 프록시
- 카카오 로그인
- AI 질문 실연동
- 공유 화면 구현
- 후반부 컬러 디자인 / 애니메이션 마감

## 3. 이번 버전의 목표

이번 버전의 목표는

1. 출생 정보 입력
2. 나탈 차트 확인
3. 오늘의 운세 확인
4. 친구 추가 및 궁합 확인
5. 결과 공유

까지 이어지는 핵심 흐름을 끊기지 않게 만드는 것이다.

화려한 연출 요소는 후반부에 구현하되,  
막판에 몰리지 않도록 12주차 후반부터 공유 레이아웃, 컬러 토큰, 애니메이션 자산 검토를 미리 시작한다.

## 4. 현재 개발 원칙

- 기능 추가보다 리스크 제거를 우선한다
- 무료 플랜 기준에서는 Firestore는 붙이되 Cloud Functions 전환은 보류한다
- AI 질문은 내부 데모 빌드에서만 GPT/Claude direct call 을 허용하고, 메인 화면에는 `자동 / GPT / Claude` 정도의 provider 선택만 노출한다
- 문서와 코드가 어긋나면 문서를 같이 갱신한다
- 비개발자도 읽을 수 있는 표현을 우선한다
- AI 협업 시 실제 secret 값은 프롬프트에 넣지 않는다

## 5. 실행 / 검증 방식

### 기본 개발 모드

기본은 fixture 모드다.

```env
USE_FIXTURE_IN_DEBUG=true
PROKERALA_CLIENT_ID=
PROKERALA_CLIENT_SECRET=
```

이 모드에서는 디버그 환경에서 fixture가 있는 호출은 네트워크를 타지 않으므로,  
비개발자 검토, 화면 작업, 문서 작업, 구조 작업에 적합하다.

### 실응답 검증 모드

실제 Prokerala 응답을 검증하거나 parser를 보정할 때만 아래처럼 사용한다.

```env
USE_FIXTURE_IN_DEBUG=false
PROKERALA_CLIENT_ID=...
PROKERALA_CLIENT_SECRET=...
```

## 6. Prokerala key 운영 방식

현재는 무료 플랜과 짧은 프로젝트 기간을 고려해  
**primary key 1개 + backup key 최대 3개**를 순차 fallback 하는 임시 방식을 사용한다.

사용 순서:

1. primary
2. seoyeon
3. seonwoo
4. doyeon

운영 규칙:

- 기본은 primary key 사용
- 429가 발생하면 다음 backup credential 로 1회 전환 시도
- backup key가 없으면 기존 credential 기준으로 `Retry-After` 재시도
- 이 방식은 임시 운영이며, 장기적으로는 예산/플랜이 허용될 때 서버 프록시로 이전하는 것이 목표

## 7. 문서 역할

### README.md

- 저장소 개요
- 실행 방법
- 문서 읽는 순서
- 협업 원칙

### docs/MVP.md

- 이번 버전에서 반드시 할 것 / 미뤄도 되는 것
- 기능 우선순위
- 주차별 큰 흐름

### docs/SDD.md

- 시스템 구조
- API / DB 설계
- 리스크
- 일정

### docs/TASKS.md

- 협업자가 바로 가져갈 수 있는 작업 단위
- 선행 작업
- 예상 수정 파일
- 담당 역할

## 8. SDD를 어떻게 시작하면 되나

1. `MVP.md`에서 이번 주기 범위를 먼저 확인한다
2. `SDD.md`에서 현재 구조, API/DB 설계, 리스크를 확인한다
3. `TASKS.md`에서 선행 작업이 없는 작업을 하나 고른다
4. 작업 중 설계가 바뀌면 문서를 같이 갱신한다

문서 갱신 원칙:

- 범위 변경: `MVP.md`
- API / DB / 구조 변경: `SDD.md`
- 작업 쪼개기 / 담당 변경: `TASKS.md`
- 실행 / 온보딩 변경: `README.md`, `docs/README.md`

## 9. 현재 우선순위

### P0

- Prokerala 실응답 검증 + parser / fixture 보정
- Firebase 프로젝트 설정 + users 컬렉션 시딩
- 무료 플랜 운영 규칙 고정
- 출생지 좌표 변환 + BirthInfo 저장 규칙 확정
- 출생 정보 입력 → Firestore 저장

### P1

- friendCodes 인덱스 + chartVersion 캐시 규칙
- 나탈 차트 조회 + 시각화
- 오늘의 운세 조회
- 친구 추가 + 즐겨찾기
- 궁합 분석 결과

### P2

- AI 랜덤 질문
- 결과 공유
- 마이페이지 수정

## 9-1. AI 질문 운영 방식

- 메인 화면에는 `자동(추천) / GPT / Claude` 정도의 provider 선택만 노출한다
- raw model id (`gpt-5-mini`, `claude-3-5-haiku-latest`) 는 `.env` 또는 개발자 전용 설정에서 관리한다
- 추천 기본 흐름은 `OpenAI → Anthropic → local fallback`
- provider 내부 backup key 는 `primary → seoyeon → seonwoo → doyeon`
- 앱 연동에는 ChatGPT / Claude 대화형 앱 구독이 아니라 각 서비스의 API key 가 필요하다
- 이 방식은 학교 프로젝트용 내부 데모 빌드 한정 임시 운영 규칙이다

### P3

- 운세 캐시 고도화
- 카카오 OAuth
- Lottie 애니메이션

## 10. 일정

### 10주차

- 응답 계약 검증
- Spark-only 운영 규칙 정리
- 사용자 / 차트 저장소 구조 확정
- 출생정보 Firestore 저장 연결

### 11주차

- 친구 관계 트랜잭션
- synastry cache
- 즐겨찾기 연결
- MATCH-001 실데이터 연결

### 12주차

- 운세 캐시 고도화
- AI 랜덤 질문
- 공유 / 디자인 선행 준비

### 13주차

- 공유 화면 구현
- 전체 디자인 마감
- 카카오 로그인 여부 최종 판단

### 14주차

- 테스트
- 버그 수정
- 발표 준비

## 11. 현재 가장 중요한 리스크

- Prokerala 응답 키 매핑이 아직 추정값인 부분이 있다
- 현재 구조는 Prokerala secret 을 앱에서 직접 다루므로 장기 운영 구조가 아니다
- 출생지 좌표 변환이 아직 완성되지 않았다
- 친구 코드 유일성과 friendship 중복 방지 규칙이 아직 확정 전이다
- chartVersion / chartPairVersion 규칙 확정이 필요하다

## 12. 현재 작업 시작 순서 추천

1. Prokerala 실응답 수집 및 parser 안정화
2. Firebase bootstrap
3. 출생지 좌표 변환 helper 구현
4. Android/iOS geocoding 연결
5. 출생정보 Firestore 저장
6. 나탈 / 운세 캐시 경로 정리
7. 친구 / 즐겨찾기 / 궁합 연결
8. AI 질문 연결
9. 공유 / 디자인 선행 준비
10. 공유 / 디자인 마감

## 13. 협업 방식

### 비개발자 팀원

- MVP 범위 점검
- 문서 표현 검수
- 화면 흐름 검토
- 발표 시나리오 피드백

### 개발자

- TASKS 기준으로 선행 작업이 없는 이슈부터 착수
- 코드 변경 시 문서 동시 갱신
- analyze / test / build 기준 확인

### AI 협업자

- 현재 코드 상태와 문서 상태를 같은 기준으로 유지
- 실제 secret 은 사용하지 않고 fixture 모드 우선
- 문서 기준을 벗어나는 설계 변경은 먼저 문서 반영

## 14. 검증 기준

현재 로컬 기준으로 아래 명령은 통과했다.

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build web
```

Android / Web 기준으로는 바로 개발 시작 가능하다.  
iOS / macOS는 Xcode / CocoaPods 준비 전에는 바로 개발 시작이 어렵다.
