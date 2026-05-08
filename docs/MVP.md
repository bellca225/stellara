# Stellara — MVP 기능 범위 정의

> **작성 기준**: SDD v0.8 + 코드베이스 실측 (2026-05-08)  
> **목표**: 14주차 발표까지 1차 완성 가능한 범위로 제한  
> **원칙**: 기능보다 동작하는 흐름 우선 / 나중에 합류하는 팀원도 이해할 수 있게 작성

---

## 1. MVP 정의

MVP(Minimum Viable Product)는 **"4명의 팀원이 실제로 앱을 통해 서로의 궁합과 운세를 확인하고 공유할 수 있는 상태"** 를 기준으로 한다.

- 화려한 애니메이션 없어도 됨
- 카카오 로그인 없어도 됨 (Firestore 직접 시딩으로 대체)
- 단, **핵심 흐름(출생정보 입력 → 나탈 차트 → 운세 → 친구 궁합 → 공유)이 끊기지 않고 동작**해야 함

---

## 2. 반드시 구현해야 하는 기능 (Must Have)

> 이 기능들이 없으면 MVP가 아니다.

| # | 기능 | 화면 ID | 구현 완료 기준 |
|---|------|---------|---------------|
| M1 | 출생 정보 입력 + Firestore 저장 | ONBOARDING-001 | 닉네임·생년월일·출생시간·출생지 입력 → Firestore `users` 컬렉션 저장 성공 |
| M2 | 나탈 차트 조회 및 360° 시각화 | ASTROLOGY-001 | Prokerala API(또는 fixture) → `NatalChart` 도메인 모델 → CustomPainter 화면 표시 |
| M3 | 오늘의 운세 조회 | TODAY-001 | Prokerala Horoscope API → 운세 텍스트·감정·행운 요소 화면 표시 |
| M4 | 친구 추가 (랜덤 코드 기반) | FRIEND-001 | 코드 검색 → 요청 전송 → 수락 → `friendships` 컬렉션 생성 |
| M5 | 즐겨찾기 친구 3명 설정 | MAIN-001 | `favoriteIds` 업데이트 → 홈 화면에 즐겨찾기 친구 행성 표시 |
| M6 | 궁합 분석 결과 조회 | MATCH-001 | Synastry API(또는 fixture) → 4축 점수(감정/대화/연애/총점) + 설명 표시 |
| M7 | AI 랜덤 질문 3개 생성 | CONTENT-001 | `자동/GPT/Claude` provider 선택 + 질문 3개 화면 표시 + 사용자 질문 1개 입력 + 실패 시 local fallback |
| M8 | 결과 공유 (이미지 캡처 + SNS) | SHARE-001 | `screenshot` → 이미지 생성 → `share_plus` → SNS 공유 성공 |
| M9 | 마이페이지 (출생 정보 수정) | MYPAGE-001 | 출생정보 수정 → Firestore 업데이트 → 차트 재계산 트리거 |

---

## 3. 있으면 좋은 기능 (Should Have)

> 시간이 허락하면 포함. 없어도 MVP 기준은 충족.

| # | 기능 | 화면 | 이유 |
|---|------|------|------|
| S1 | 오늘의 운세 당일 캐시 | TODAY-001 | Prokerala 크레딧 절약. SharedPreferences로 당일 재호출 방지 |
| S2 | Lottie 우주 애니메이션 | MAIN-001, ASTROLOGY-001 | 시각적 완성도 향상. 13주차에 추가 |
| S3 | 카카오 OAuth 로그인 | LOGIN-001 | 데모 완성도 향상. 시간 여유 시 13주차 |
| S4 | 푸시 알림 (FCM) | - | 운세 도착, 친구 요청 수락 알림. 12주차 선택 구현 |
| S5 | AI 성격 리포트 (장문) | MYPAGE-001 또는 ASTROLOGY-001 | 외부 LLM 기반 장문 분석. 예산 또는 프록시 준비 후 검토 |
| S6 | 전체 컬러 디자인 적용 | 전체 | 현재 흑백 → 색상 테마 13주차 복원 |

---

## 4. 이번 버전에서 제외할 기능 (Won't Have)

> 현재 버전에서 명시적으로 포함하지 않는다. 기술 부채로 관리.

| 기능 | 제외 이유 |
|------|-----------|
| 카카오 OAuth 실 연동 (MVP 필수 제외) | Firestore 직접 시딩으로 대체 가능. 일정 리스크 대비 효과 적음 |
| go_router 선언형 라우팅 | 현재 Navigator.push로 동작함. 전환 비용 대비 MVP 영향 없음 |
| freezed 코드 생성 전환 | 현재 수기 모델로 동작함. 점진적 전환 가능 |
| 별자리 우주 애니메이션 (Lottie 필수) | Should Have로 분류. 미완성 상태로 발표 가능 |
| 자체 백엔드 REST 서버 | Firebase Firestore + 클라이언트 직접 연동으로 MVP 범위 충족 가능 |
| 결제/구독 기능 | 범위 외 |
| 통합 테스트 완전 커버리지 | 14주차 위젯 테스트 + smoke test로 충분 |
| Docker 기반 자체 호스팅 | Firebase 관리형으로 대체. 백엔드 개발자 없는 환경에 부적합 |

---

## 5. 기능별 우선순위

### 우선순위 기준

- **P0 (블로킹)**: 이게 없으면 다른 기능이 동작 안 됨
- **P1 (핵심)**: MVP의 핵심 가치 제공
- **P2 (완성도)**: MVP 흐름은 되지만 경험 향상
- **P3 (선택)**: Should Have 수준

| 우선순위 | 기능 | 이유 |
|----------|------|------|
| **P0** | Prokerala 실응답 검증 + parser/fixture 보정 | 나탈/운세/궁합이 모두 추정 응답 키 위에 올라가 있으므로 가장 먼저 안정화 필요 |
| **P0** | Firebase 프로젝트 설정 + `users` 컬렉션 시딩 | 모든 기능의 전제 조건 |
| **P0** | 무료 플랜 운영 규칙 고정 + 공개 배포 금지 원칙 명시 | direct call 구조를 학교 데모 범위 안에서만 안전하게 운영하기 위한 전제 |
| **P0** | 출생지 좌표 변환 + `BirthInfo` 저장 규칙 확정 | 현재 서울/부산 폴백이라 차트 정확도가 보장되지 않음 |
| **P0** | 출생 정보 입력 → Firestore 저장 (M1) | 앱의 모든 데이터 기반 |
| **P1** | `friendCodes` 인덱스 + `chartVersion` 캐시 규칙 | 친구 검색/궁합 캐시가 중복 없이 돌아가기 위한 기반 |
| **P1** | 나탈 차트 조회 + 시각화 (M2) | 핵심 차별화 기능 |
| **P1** | 오늘의 운세 조회 (M3) | 일상 재방문 유도의 핵심 |
| **P1** | 친구 추가 + 즐겨찾기 (M4, M5) | 소셜 기능의 기반 |
| **P1** | 궁합 분석 결과 (M6) | 친구 기능과 결합되어 핵심 가치 제공 |
| **P2** | AI 랜덤 질문 (M7) | 필수 기능이지만 다른 P1 완료 후 구현 |
| **P2** | 결과 공유 (M8) | 바이럴 요소. 구현은 후반부에 두되 12주차 후반부터 레이아웃/자산 선행 준비 |
| **P2** | 마이페이지 출생정보 수정 (M9) | 데이터 정확도 향상 |
| **P3** | 운세 캐시 (S1) | 크레딧 절약 |
| **P3** | 카카오 OAuth (S3) | 데모 완성도 |
| **P3** | Lottie 애니메이션 (S2) | 시각적 완성도. 13주차 적용 전 12주차 후반 검토 |

---

## 6. 개발 순서 제안

### Phase 1 — 기반 구축 (10주차, 5/9~5/15)

> 목표: 앱이 "실제 데이터 + 검증된 응답 계약"으로 돌아가는 최초 버전 완성

```
Step 0.  Prokerala 첫 실응답 확보
         → natal / horoscope / synastry raw JSON 저장
         → fixture 갱신 + parser 키 보정

Step 1.  Firebase 프로젝트 생성
         → google-services.json 설정 (Android/iOS)
         → firebase_core, cloud_firestore, flutter_secure_storage pubspec에 추가

Step 2.  Spark-only 운영 규칙 정리
         → Prokerala direct call 유지 범위 문서화
         → multi-key fallback / fixture 기본 전략 고정
         → 공개 배포 금지 원칙 명시

Step 3.  Firestore users / charts / friendCodes 설계 확정 + 팀원 4명 테스트 데이터 시딩
         → Firebase Console에서 직접 입력

Step 4.  Android/iOS geocoding 연결
         → Android/iOS에서 온보딩 출생지 입력 → 실제 lat/lng 저장
         → BirthInfo 는 dateTimeLocal + utcOffset 형태 유지

Step 5.  LoginScreen 현재 구조 유지
         → "시작하기" + "데모 데이터로 둘러보기" 버튼 유지
         → 최종 마감 전까지 데모 경로를 살려두고, 마지막 정리 단계에서 제거 여부 판단

Step 6.  OnboardingScreen → Firestore 저장 연결
         → 출생정보 입력 후 users/{uid} 문서 생성/업데이트

Step 7.  currentBirthInfoProvider → Firestore Stream 교체
         → 앱 재실행 시 데이터 유지 검증
```

**이 단계 완료 기준**: 앱 재실행 후에도 출생정보가 유지되고 나탈 차트가 표시됨

---

### Phase 2 — 소셜 기능 (11주차, 5/16~5/22)

> 목표: 친구 추가 → 궁합 확인 흐름 완성

```
Step 8.  FRIEND-001 기능 구현
         - friends/ 도메인: data/domain 계층 추가
         - Firestore friendCode 검색 → friendRequests 생성
         - 친구 요청 수락 → friendships 생성
         - 즐겨찾기 설정 (users.favoriteIds 업데이트, 최대 3명)

Step 9.  MAIN-001 실데이터 연결
         - 즐겨찾기 친구의 나탈 차트 데이터 → 홈 화면 행성 표시

Step 10. MATCH-001 실 Synastry 데이터 연결
         - direct Prokerala 호출 결과와 Firestore cache 연결
         - pairKey + chartPairVersion 기반 cache
         - 어스펙트 가중치 재조정 (실데이터 기반)
         - 4축 점수 + 설명 화면 표시
```

**이 단계 완료 기준**: 팀원 2명이 친구 추가 후 궁합 점수를 확인할 수 있음

---

### Phase 3 — AI + 운세 + 후반부 준비 (12주차, 5/23~5/29)

> 목표: AI 기능과 운세 캐시를 완성하고, 공유/디자인 작업이 막판에 몰리지 않도록 선행 준비 시작

```
Step 11. CONTENT-001 질문 엔진 추가
         - `자동(추천) / GPT / Claude` provider 선택 UI 추가
         - 기본 흐름은 `OpenAI → Anthropic → local fallback`
         - raw model id 는 메인 화면 대신 `.env` 또는 개발자 설정에서 관리
         - AI 질문 3개 + 사용자 입력 1개 화면 표시

Step 12. TODAY-001 운세 캐시 (SharedPreferences)
         - 당일 동일 별자리 재호출 방지
         - dailyFortunes Firestore 저장

Step 13. SHARE-001 / 디자인 선행 준비
         - 공유 카드 레이아웃 와이어프레임 확정
         - 컬러 토큰/모션 토큰 초안 정리
         - Lottie 적용 후보 자산 검토

Step 14. FCM 설정 (선택)
         - 운세 도착 / 친구 요청 알림 (일정 여유 시)
```

**이 단계 완료 기준**: AI 질문이 실제로 생성되고, 오늘의 운세가 캐시되며, 공유/디자인 작업의 선행 준비가 끝나 있음

---

### Phase 4 — 공유 + 디자인 완성 (13주차, 5/30~6/5)

> 목표: 결과 공유 기능 + 전체 디자인 완성

```
Step 15. SHARE-001 구현
         - share_plus, screenshot 패키지 추가
         - 운세·궁합·나탈 차트 결과 이미지 캡처 → SNS 공유

Step 16. 전체 디자인 폴리시 마감
         - 12주차에 준비한 컬러/모션 토큰 반영
         - Lottie 애니메이션 (일정 여유 시)

Step 17. MYPAGE-001 출생정보 수정 기능 완성
         - Firestore 업데이트 → charts 컬렉션 버전 무효화 → 재계산

Step 18. 카카오 OAuth (일정 여유 시)
```

**이 단계 완료 기준**: 궁합 결과를 이미지로 저장하고 카톡/인스타에 공유 가능

---

### Phase 5 — 검증 + 발표 준비 (14주차, 6/6~)

```
Step 19. 위젯 테스트 보완 + smoke test
Step 20. README 최종화 + 시연 영상 촬영
Step 21. Prokerala 응답 키 매핑 최종 검증 (실 API 호출)
Step 22. 발표 자료 준비
```

---

## 7. 나중에 합류하는 팀원을 위한 컨텍스트

### 앱 이해를 위한 3줄 요약

Stellara는 **출생 정보(생년월일·시간·장소) → Prokerala API → 나탈 차트·운세·궁합** 흐름으로 동작하는 Flutter 앱이다. 모든 점성술 계산은 외부 API에 위임하고, 앱은 시각화·소셜 기능을 담당한다. 현재 MVP는 **Firebase Firestore(Spark) + 클라이언트 직접 호출** 기준으로 진행되며, 서버 프록시는 후속 선택지로 남겨둔다.

### 코드 진입점

```
lib/main.dart     → 앱 시작, .env 로드, ProviderScope
lib/app.dart      → MaterialApp, 흑백 테마, LoginScreen 첫 화면
lib/core/         → 테마, HTTP, env, 공용 위젯 (도메인 무관)
lib/features/     → 화면별 모듈 (auth/onboarding/home/astrology/horoscope/compatibility/friends/content/profile/share)
functions/        → [선택] Blaze 전환 시 추가할 서버 프록시 영역
docs/SDD.md       → 전체 설계 문서
docs/MVP.md       → 이 문서
```

### 꼭 알아야 할 패턴

1. **Fixture Fallback**: 모든 API Repository는 실호출 실패 시 `fixtures/` 더미 데이터를 반환한다. 개발 중에는 `USE_FIXTURE_IN_DEBUG=true`로 설정해 Prokerala 크레딧을 절약한다.

2. **Provider 의존**: Riverpod의 모든 Provider는 `astrology_providers.dart`가 DI 루트이다. 화면은 `myNatalChartProvider`, `todayHoroscopeProvider`, `synastryProvider`를 `watch`하여 자동으로 API 호출을 트리거한다.

3. **레이어드 구조**: 각 feature 폴더는 `presentation → application → data → domain` 단방향 의존으로 구성된다. 새 기능 추가 시 이 구조를 따른다.

4. **Prokerala 제약 메모**: 현재 문서의 fallback은 실제 네트워크 실패나 응답 형태 차이를 흡수하기 위한 장치다. `1월 1일만 허용` 같은 제한은 공식 문서로 확인된 규칙이 아니므로, 사실처럼 전제하지 않는다.

5. **DB 시딩**: 카카오 로그인이 없는 동안 `LoginScreen`의 현재 데모 진입 흐름을 유지하고, Firestore에는 테스트 사용자를 직접 시딩한다. `데모 데이터로 둘러보기` 버튼은 최종 정리 직전까지 살려둔다.

6. **후반부 연출 작업 운영 방식**: 공유 화면, 애니메이션, 컬러 테마 같은 화려한 요소는 후반부 구현 대상으로 두되, 12주차 후반부터 레이아웃/디자인 토큰/자산 검토를 미리 시작해 13주차 과밀을 피한다.

7. **AI 질문 UX 원칙**: 메인 화면에는 `자동/GPT/Claude` 정도의 provider 수준만 노출하고, `gpt-5-mini`, `claude-3-5-haiku-latest` 같은 raw model id 는 `.env` 또는 개발자 전용 설정에서 관리한다.

---

## 8. MVP 완성 체크리스트

### 10주차 완료 조건

- [ ] Firebase 프로젝트 연결 (google-services.json 존재)
- [ ] `users` 컬렉션 + 팀원 4명 테스트 데이터 시딩 완료
- [ ] Android/iOS에서 출생지 입력 → 좌표 변환 동작 확인
- [ ] 온보딩 입력 → Firestore 저장 동작 확인
- [ ] 앱 재실행 후 나탈 차트 유지 확인

### 11주차 완료 조건

- [ ] 랜덤 코드로 친구 검색·요청·수락 동작 확인
- [ ] 즐겨찾기 3명 설정 → 홈 화면 표시 확인
- [ ] `prokerala-synastry` + `synastryCaches` 동작 확인
- [ ] MATCH-001에서 실 Synastry 점수 표시 확인

### 12주차 완료 조건

- [ ] CONTENT-001에서 AI 질문 3개 생성 확인
- [ ] TODAY-001 운세 당일 캐시 동작 확인
- [ ] SHARE-001 레이아웃 초안 + 디자인 토큰 초안 확정

### 13주차 완료 조건

- [ ] SHARE-001에서 이미지 저장 + SNS 공유 성공
- [ ] 전체 디자인 컬러 테마 적용 완료

### 14주차 완료 조건

- [ ] `flutter analyze` 경고 없음
- [ ] `flutter test` 전체 통과
- [ ] 시연 시나리오 (출생정보 입력 → 운세 확인 → 친구 궁합 → 공유) 끊김 없이 동작
- [ ] README 최종화 + 시연 영상 완성

---

*작성: 2026-05-08 / 기준 브랜치: feature/week09-prokerala-api*
