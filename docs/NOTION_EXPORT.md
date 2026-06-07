# Stellara 프로젝트 통합 정리본

## 1. 프로젝트 개요

Stellara는 사용자의 출생 정보(생년월일, 출생 시간, 출생지)를 바탕으로  
나탈 차트, 오늘의 운세, 친구 궁합, 랜덤 질문, 결과 공유를 제공하는 Flutter 앱이다.

현재는 학교 프로젝트용 프로토타입 단계이며,  
핵심 화면 흐름과 Firebase Auth/Firestore 연동은 이미 들어와 있다.  
다만 Prokerala 실응답 검증, 궁합 점수 고도화, 공유 범위 확장, 공개 배포 구조는 아직 정리 중이다.

## 2. 지금 상태 한 줄 요약

현재 기본 브랜치는 **Spark-only Firebase + fixture-first 앱 동작**을 기준으로 운영한다.

- Firebase는 Spark 플랜만 사용
- Prokerala 원격 호출은 기본 잠금
- AI 원격 호출도 기본 잠금
- 화면과 시연은 fixture / local question set 으로 유지

즉, **결제가 열릴 수 있는 경로는 기본 브랜치에서 닫아 둔 상태**다.

## 3. 현재 구현된 것

- Flutter 앱 기본 구조
- Riverpod 상태 관리 골격
- Prokerala 직접 호출 코드와 wrapper
- 나탈 차트 / 운세 / 궁합 fixture fallback
- Firebase Email/Password Auth + Firestore 사용자/친구 연동
- 로그인, 온보딩, 홈, 차트, 궁합, 친구, 랜덤 질문, 마이페이지 화면
- SharedPreferences 디스크 캐시
- 운세/랜덤 질문 공유 화면 + 궁합 텍스트 공유
- Android / Web 실행 검증

## 4. 아직 없는 것

- Prokerala 실응답 기준 parser 재검증
- 궁합 점수 산식 고도화
- 나탈 차트 전용 공유 화면
- 카카오 로그인
- 원격 AI 운영 정책 정리
- 후반부 컬러 디자인 / 애니메이션 마감

## 5. 이번 버전의 목표

이번 버전의 목표는 아래 핵심 흐름을 **끊기지 않게** 만드는 것이다.

1. 출생 정보 입력
2. 나탈 차트 확인
3. 오늘의 운세 확인
4. 친구 추가 및 궁합 확인
5. 결과 공유

화려한 연출 요소는 후반부에 구현하되,  
막판에 몰리지 않도록 12주차 후반부터 공유 레이아웃, 컬러 토큰, 애니메이션 자산 검토를 먼저 시작한다.

## 6. 현재 개발 원칙

- 기능 추가보다 리스크 제거를 우선한다
- 무료 플랜 기준에서는 Firestore는 붙이되 Cloud Functions는 쓰지 않는다
- Prokerala 원격 호출은 기본 브랜치에서 잠근다
- 원격 AI 호출도 기본 브랜치에서 잠근다
- 공개 배포용 빌드는 만들지 않는다
- 문서와 코드가 어긋나면 문서를 같이 갱신한다
- 비개발자도 읽을 수 있는 표현을 우선한다
- AI 협업 시 실제 secret 값은 프롬프트에 넣지 않는다

## 7. 실행 / 검증 방식

### 기본 개발 모드

기본은 **무과금 보호 모드**다.

```env
PROKERALA_REMOTE_ENABLED=false
USE_FIXTURE_IN_DEBUG=true
PROKERALA_CLIENT_ID=
PROKERALA_CLIENT_SECRET=
AI_REMOTE_ENABLED=false
```

이 모드에서는:

- Prokerala 원격 호출을 하지 않는다
- AI 원격 호출을 하지 않는다
- fixture와 local question set 만 사용한다
- 비개발자 검토, 화면 작업, 문서 작업, 구조 작업에 적합하다

### 실응답 검증 모드

실제 Prokerala 응답을 검증하거나 parser를 보정할 때만 아래처럼 잠깐 사용한다.

```env
PROKERALA_REMOTE_ENABLED=true
USE_FIXTURE_IN_DEBUG=false
PROKERALA_CLIENT_ID=...
PROKERALA_CLIENT_SECRET=...
AI_REMOTE_ENABLED=false
```

운영 규칙:

- owner 확인 후 짧은 검증 시간에만 켠다
- 검증이 끝나면 다시 `PROKERALA_REMOTE_ENABLED=false` 로 돌린다
- AI는 여전히 `AI_REMOTE_ENABLED=false` 유지

## 8. Prokerala key 운영 방식

코드상으로는 아래 순서의 fallback 을 지원한다.

1. primary
2. seoyeon
3. seonwoo
4. doyeon

하지만 중요한 점은:

- **기본 브랜치에서는 이 key들을 사용하지 않는다**
- `PROKERALA_REMOTE_ENABLED=true` 로 열었을 때만 사용한다
- 429가 발생하면 다음 backup credential 로 1회 전환을 시도한다
- backup key가 없으면 기존 credential 기준으로 `Retry-After` 재시도한다

즉, 이 fallback 은 **학교 프로젝트 + 무료 플랜 + 임시 운영**을 위한 완충 장치다.

## 9. AI 운영 방식

현재 브랜치 기준 AI 정책은 아래와 같다.

- 체크인된 `.env.example` 기준 `AI_REMOTE_ENABLED=false` 유지
- 랜덤 질문 화면은 local question set 을 기본으로 사용한다
- 원격 AI를 열면 `Gemini → OpenAI → Anthropic` 순서로 시도한다
- Gemini / OpenAI / Anthropic key 는 `.env` 에만 두고 owner 승인 전까지 기본 시연 경로에서 사용하지 않는다

현재는 **모델 선택 UI도 노출하지 않는다.**

이유:

- 비개발자 기준 이해가 쉬운 흐름을 우선
- 원격 AI가 아직 실제 동작 범위가 아님
- provider/model 선택 UI는 나중에 실제 연동이 열릴 때 다시 검토

## 10. Firebase 상태

현재 확인된 Firebase 상태:

- Android 패키지명: `com.stellara.app`
- Android 로컬 `google-services.json` 반영
- Android 에서 `Firebase.initializeApp()` 연결
- Firebase Email/Password 회원가입/로그인 + 세션 복원 동작

아직 남은 것:

- Firestore 실데이터 저장/조회 연결
- Security Rules 실제 운영 정리
- iOS / Web Firebase 설정

## 11. 문서 역할

### docs/README.md

- 문서 전체 구조
- SDD 시작 순서
- 문서 갱신 규칙

### docs/MVP.md

- 이번 버전에서 반드시 할 것
- 미뤄도 되는 것
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

## 12. SDD를 어떻게 시작하면 되나

1. `MVP.md`에서 이번 주기 범위를 먼저 확인한다
2. `SDD.md`에서 현재 구조, API/DB 설계, 리스크를 확인한다
3. `TASKS.md`에서 선행 작업이 없는 이슈를 하나 고른다
4. 작업 중 설계가 바뀌면 문서를 같이 갱신한다

문서 갱신 기준:

- 범위 변경: `MVP.md`
- API / DB / 구조 변경: `SDD.md`
- 작업 쪼개기 / 담당 변경: `TASKS.md`
- 실행 / 온보딩 / 운영 규칙 변경: `docs/README.md`, `docs/SDD.md`

## 13. 현재 우선순위

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

- 랜덤 질문
- 결과 공유
- 마이페이지 수정

### P3

- 운세 캐시 고도화
- 카카오 OAuth
- Lottie 애니메이션

## 14. 일정

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
- local question engine
- 공유 / 디자인 선행 준비

### 13주차

- 공유 화면 구현
- 전체 디자인 마감
- 카카오 로그인 여부 최종 판단

### 14주차

- 테스트
- 버그 수정
- 발표 준비

## 15. 현재 가장 중요한 리스크

- Prokerala 응답 키 매핑이 아직 추정값인 부분이 있다
- Prokerala secret 을 앱에서 직접 다루는 구조이므로 장기 운영 구조가 아니다
- 출생지 좌표 변환 정확도는 플랫폼과 입력 구체성에 영향을 받는다
- 친구 코드 유일성과 friendship 중복 방지 규칙이 아직 확정 전이다
- Firestore 실데이터 연결이 아직 마무리되지 않았다

## 16. 꼭 기억할 운영 규칙

- 기본 브랜치에서는 `PROKERALA_REMOTE_ENABLED=false`
- 기본 브랜치에서는 `AI_REMOTE_ENABLED=false`
- 기본 브랜치에서는 Spark 유지, Blaze 금지
- 공개 배포 금지
- 현재 인증 진입은 `LandingScreen → 계정 만들기 / 로그인` 흐름을 사용
- 화려한 기능과 디자인은 후반부 구현, 대신 12주차 후반부터 선행 준비
