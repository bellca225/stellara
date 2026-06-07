# Stellara AI 프로바이더 통합 가이드

> 작성: 2026-06-07  
> 대상: 팀원 전체, Codex  
> 목적: 현재 소스 기준 AI 질문 생성 구조와 env 규약을 한 문서로 고정한다.

## 0. 고정 규칙

다음 세션에서 AI 관련 코드를 수정할 때는 아래 규칙을 먼저 따른다.

1. env 키명은 `AI_MODEL_GEMINI_DEFAULT`, `AI_MODEL_OPENAI_DEFAULT`, `AI_MODEL_ANTHROPIC_DEFAULT`를 사용한다.
2. 모델 getter는 `Env.aiModelGemini`, `Env.aiModelOpenAi`, `Env.aiModelAnthropic`를 사용한다.
3. AI 호출은 반드시 `AiQuestionRepository`를 통해서만 한다.

실제 기준 파일:

- `lib/core/env/env.dart`
- `lib/features/content/data/ai_question_repository.dart`
- `lib/features/content/application/question_providers.dart`

## 1. 현재 구조

### 1.1 fallback chain

```text
AI_REMOTE_ENABLED=false
  → 로컬 질문 템플릿

AI_REMOTE_ENABLED=true + 키 있음
  → AI_PROVIDER_ORDER 순서대로 시도
  1. Gemini (gemini-2.5-flash)
  2. OpenAI (gpt-4o-mini)
  3. Anthropic (claude-3-5-haiku-latest)
  4. 모두 실패하면 로컬 fallback
```

### 1.2 env 키

| 키 | 의미 | 체크인 기본값 |
|----|------|---------------|
| `AI_REMOTE_ENABLED` | 마스터 스위치 | `false` |
| `AI_PROVIDER_DEFAULT` | 우선 프로바이더 (`auto` 권장) | `auto` |
| `AI_PROVIDER_ORDER` | fallback 순서 | `gemini,openai,anthropic` |
| `AI_MODEL_GEMINI_DEFAULT` | Gemini 모델 | `gemini-2.5-flash` |
| `AI_MODEL_OPENAI_DEFAULT` | OpenAI 모델 | `gpt-4o-mini` |
| `AI_MODEL_ANTHROPIC_DEFAULT` | Anthropic 모델 | `claude-3-5-haiku-latest` |
| `GEMINI_API_KEY` | Gemini 키 | 빈 값 |
| `OPENAI_API_KEY` | OpenAI 키 | 빈 값 |
| `ANTHROPIC_API_KEY` | Anthropic 키 | 빈 값 |

### 1.3 Env getter

```dart
Env.aiRemoteEnabled
Env.aiProviderOrder
Env.aiModelGemini
Env.aiModelOpenAi
Env.aiModelAnthropic
Env.geminiApiKey
Env.openAiApiKey
Env.anthropicApiKey
```

## 2. 구현 파일 역할

| 파일 | 역할 |
|------|------|
| `lib/core/env/env.dart` | AI 관련 env getter 단일 진입점 |
| `lib/features/content/data/ai_question_repository.dart` | 멀티 프로바이더 호출 + JSON 파싱 + fallback |
| `lib/features/content/data/question_repository.dart` | 로컬 질문 템플릿 |
| `lib/features/content/application/question_providers.dart` | 화면용 Riverpod provider |
| `lib/features/content/presentation/random_question_screen.dart` | 질문 생성/재생성/공유 UI |

## 3. 해야 할 것 / 하면 안 되는 것

### 해야 할 것

- 새 AI 키나 모델을 추가하면 `env.dart` getter와 `.env.example`을 같이 갱신한다.
- UI에서는 provider만 호출하고, 실제 provider 선택은 repository에 맡긴다.
- 발표용 기본 설정은 `AI_REMOTE_ENABLED=false`로 둔다.

### 하면 안 되는 것

- `OPENAI_MODEL` 같은 구 키명을 다시 도입하지 않는다.
- 화면이나 다른 repository에서 Gemini/OpenAI/Anthropic endpoint를 직접 호출하지 않는다.
- 체크인 파일에서 `AI_REMOTE_ENABLED=true`를 기본값으로 두지 않는다.
- 실제 API 키를 코드, 주석, 프롬프트, 문서 예시에 넣지 않는다.

## 4. 운영 메모

- 현재 소스는 원격 AI가 꺼져 있어도 랜덤 질문 화면이 local question set으로 정상 동작한다.
- 원격 AI를 열면 동일한 UI에서 repository가 `Gemini → OpenAI → Anthropic` 순으로 자동 fallback 한다.
- `.env`는 Flutter asset으로 번들되므로, 현재 구조는 학교 내부 데모용에 가깝고 공개 배포용으로는 안전하지 않다.
- 발표 직전에는 `.env.example` 기준처럼 `AI_REMOTE_ENABLED=false` 상태를 유지하는 편이 가장 안정적이다.
