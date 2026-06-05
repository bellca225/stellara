# Stellara AI 프로바이더 통합 가이드

> **작성**: 2026-06-03  
> **대상**: Codex (AI 코딩 에이전트), 팀원 전체  
> **목적**: AI 질문 생성 구조와 env 키 규약을 통일하고 혼선을 방지한다.

---

## 0. Codex 다음 세션 필수 컨텍스트

다음 세션에서 Codex가 AI 관련 코드를 건드릴 때는 이 파일을 먼저 읽고 아래 3가지를 **고정 규칙**으로 따른다.

1. env 키명은 반드시 `AI_MODEL_OPENAI_DEFAULT`를 사용한다.  
   `OPENAI_MODEL` 같은 구 키명은 사용하지 않는다.
2. 모델 getter는 반드시 `Env.aiModelOpenAi`를 사용한다.  
   `Env.openAiModel` 구 getter는 존재하지 않으며, 새 코드에서도 참조하지 않는다.
3. AI 호출은 반드시 `AiQuestionRepository`를 통해서만 한다.  
   화면, provider, 다른 repository에서 OpenAI/Anthropic endpoint를 직접 호출하지 않는다.

실제 코드 기준 파일:

- `lib/core/env/env.dart`
- `lib/features/content/data/ai_question_repository.dart`
- `lib/features/content/application/question_providers.dart`

---

## 1. 현재 구조 (확정)

Codex의 `.env` 멀티 프로바이더 설계 + 나영의 Dart 구현을 합쳐 아래로 확정했다.

### 1.1 fallback chain

```
AI_REMOTE_ENABLED=false → 로컬 질문 템플릿 (기본 동작)

AI_REMOTE_ENABLED=true + 키 있음 →
  AI_PROVIDER_ORDER 순서로 시도:
  1. OpenAI (gpt-4o-mini)     → 성공 시 QuestionItem(source: remoteAi)
  2. Anthropic (haiku-latest) → OpenAI 실패 시 자동 전환
  3. 로컬 fallback             → 모두 실패 시 (사용자에게 오류 미노출)
```

### 1.2 env 키 (확정 목록)

| 키 | 의미 | 기본값 |
|----|------|--------|
| `AI_REMOTE_ENABLED` | 마스터 스위치. false=항상 로컬 | `false` |
| `AI_PROVIDER_DEFAULT` | 우선 프로바이더 ('auto'=순서대로) | `auto` |
| `AI_PROVIDER_ORDER` | fallback 순서, comma-separated | `openai,anthropic` |
| `AI_MODEL_OPENAI_DEFAULT` | OpenAI 모델 | `gpt-4o-mini` |
| `AI_MODEL_ANTHROPIC_DEFAULT` | Anthropic 모델 | `claude-3-5-haiku-latest` |
| `OPENAI_API_KEY` | OpenAI secret key | `` (비어있으면 건너뜀) |
| `ANTHROPIC_API_KEY` | Anthropic secret key | `` (비어있으면 건너뜀) |

### 1.3 Dart getter 위치

모든 env 값은 `lib/core/env/env.dart`의 `Env` 클래스에서만 읽는다.

```dart
Env.aiRemoteEnabled       // bool
Env.aiProviderOrder       // List<String>
Env.aiModelOpenAi         // String
Env.aiModelAnthropic      // String
Env.openAiApiKey          // String
Env.anthropicApiKey       // String
```

---

## 2. 구현 파일 목록

| 파일 | 역할 | 건드려도 되는지 |
|------|------|----------------|
| `lib/core/env/env.dart` | env getter 모음 | ✅ 키 추가 가능, 기존 getter 이름 변경 금지 |
| `lib/features/content/data/ai_question_repository.dart` | AI 호출 + fallback chain | ✅ 로직 개선 가능 |
| `lib/features/content/data/question_repository.dart` | 로컬 fallback 템플릿 | ✅ 템플릿 개선 가능 |
| `lib/features/content/application/question_providers.dart` | Riverpod provider 모음 | ✅ provider 추가 가능, 기존 이름 변경 금지 |
| `lib/features/content/domain/question_item.dart` | 도메인 모델 | ✅ 필드 추가 가능, 기존 필드 삭제 금지 |
| `lib/features/content/presentation/random_question_screen.dart` | UI | ⚠️ 디자인/CSS 수정 금지. 기능 연결만 |

---

## 3. Codex가 해야 할 것 / 하면 안 되는 것

### ✅ 해야 할 것
- `AI_PROVIDER_ORDER`, `AI_MODEL_OPENAI_DEFAULT`, `AI_MODEL_ANTHROPIC_DEFAULT` 키명 사용
- 새 env 키 추가 시 `env.dart`에 getter도 함께 추가
- `.env.example`에 키 이름 추가 (값은 비워서)
- `AiQuestionRepository`를 통해서만 AI 호출 (`HttpClientWrapper` 직접 호출 금지)

### ❌ 하면 안 되는 것
- `OPENAI_MODEL` (구 키명) 사용 — `AI_MODEL_OPENAI_DEFAULT` 사용할 것
- `Env.openAiModel` getter 참조 — `Env.aiModelOpenAi` 사용할 것
- `AiQuestionRepository` 없이 OpenAI/Anthropic 직접 호출
- `AI_REMOTE_ENABLED=true`를 기본값으로 코드에 하드코딩
- 실제 API 키를 코드/주석/프롬프트에 포함

---

## 4. 새 AI 기능 추가 시 규칙

### 예: AI 성격 리포트 (장문) 추가

```
1. env.dart에 getter 추가:
   static String get aiModelOpenAiReport =>
       dotenv.maybeGet('AI_MODEL_OPENAI_REPORT')?.trim() ?? 'gpt-4o';

2. .env.example에 키 추가:
   AI_MODEL_OPENAI_REPORT=gpt-4o

3. 별도 Repository 생성:
   lib/features/profile/data/ai_report_repository.dart
   (AiQuestionRepository 복사 후 시스템 프롬프트만 교체)

4. Provider 추가:
   lib/features/profile/application/report_providers.dart

5. 화면 연결:
   lib/features/profile/presentation/my_page_screen.dart
```

---

## 5. 비용 가이드

| 사용 시나리오 | 예상 비용 |
|--------------|---------|
| 질문 3개 생성 (gpt-4o-mini) | ~$0.00027 / 회 |
| 질문 1000회 생성 | ~$0.27 (약 370원) |
| Anthropic fallback (haiku) | ~$0.00024 / 회 |
| 장문 리포트 (gpt-4o) | ~$0.015 / 회 |

**운영 원칙**: `AI_REMOTE_ENABLED=false` 상태에서 로컬 질문으로 발표/시연 가능.  
AI ON은 owner(나영) 승인 후에만 활성화.

---

## 6. 현재 알려진 이슈

- **OpenAI 키 노출 이력**: 이전 채팅에서 실제 키가 노출됨. **재발급 필요** (나영이 처리).  
  재발급 후 `.env` 파일의 `OPENAI_API_KEY` 값만 교체하면 됨.
- **Anthropic 키 미발급**: `ANTHROPIC_API_KEY=` 비어있음. 현재는 OpenAI만 동작.  
  Anthropic 키 발급 시 `.env`에 추가하면 자동으로 fallback에 포함됨.
