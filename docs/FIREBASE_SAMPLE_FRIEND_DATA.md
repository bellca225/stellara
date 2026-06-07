# Firebase 친구 샘플 데이터

> 기준 브랜치: `main`  
> 기준 시점: 2026-05-31  
> 목적: `FRIEND-001` 화면에서 4명(우나영 / 김도연 / 배서연 / 이선우)을 검색하고 친구 요청 테스트를 할 수 있도록 Firestore 콘솔에 바로 넣을 수 있는 샘플 데이터를 제공한다.

## 1. 현재 `main` 브랜치 기준 분석

현재 친구 기능은 아래 흐름으로 동작한다.

- 검색: `friendCodes/{code}` 단건 조회 → `uid` 획득 → `users/{uid}` 로 실제 사용자 문서 조회
- 요청 보내기: `friendRequests` 컬렉션에 문서 추가
- 요청 수락: `runTransaction` 으로 `friendRequests.status=accepted` + `friendships/{pairKey}` 생성
- 친구 목록: `friendships` 에서 `uids array-contains` 조회 후 상대 `users/{uid}` 문서 로드
- 즐겨찾기: `users/{uid}.favoriteIds`

실제 코드 위치:

- 검색/요청/수락/친구목록: [lib/features/friends/data/friend_repository.dart](/Users/nywoo/proj/stellara/lib/features/friends/data/friend_repository.dart:1)
- 친구 화면: [lib/features/friends/presentation/friend_screen.dart](/Users/nywoo/proj/stellara/lib/features/friends/presentation/friend_screen.dart:1)
- 사용자 스키마 모델: [lib/features/users/domain/user_profile.dart](/Users/nywoo/proj/stellara/lib/features/users/domain/user_profile.dart:1)
- 현재 로그인 진입점: [lib/features/auth/presentation/login_screen.dart](/Users/nywoo/proj/stellara/lib/features/auth/presentation/login_screen.dart:1)

중요 포인트:

- 현재 앱에는 `데모 데이터로 둘러보기` 버튼이 없다
- 아래 `demo-*` uid 값은 **예시 placeholder** 이며, 실제 테스트에서는 회원가입으로 생성된 Firebase Auth uid에 맞춰 바꿔 넣어야 한다
- Web(`localhost`)에서 테스트 중이면 `.env` 의 `FIREBASE_WEB_*` 값이 먼저 설정되어 있어야 Firestore가 실제로 붙는다

## 2. 최소 입력 세트

`FRIEND-001` 검색이 바로 되게 하려면 아래 2개 컬렉션만 먼저 넣으면 된다.

1. `users`
2. `friendCodes`

이 두 컬렉션만 있으면:

- 테스트용 계정으로 로그인한 뒤
- `DOY001`, `SEO001`, `SUN001` 검색
- 검색 결과 확인
- 친구 요청 전송

까지 가능하다.

## 3. 권장 uid / friendCode

| 이름 | uid | friendCode |
|------|-----|------------|
| 우나영 | `demo-una` | `UNA001` |
| 김도연 | `demo-doyeon` | `DOY001` |
| 배서연 | `demo-seoyeon` | `SEO001` |
| 이선우 | `demo-seonwoo` | `SUN001` |

## 4. `users` 컬렉션 샘플

Firestore 콘솔에서 컬렉션 `users` 를 만들고 아래 문서 4개를 추가하면 된다.

### `users/demo-una`

```json
{
  "uid": "demo-una",
  "authProvider": "dev",
  "nickname": "우나영",
  "friendCode": "UNA001",
  "profileCompleted": true,
  "sunSign": "Pisces",
  "birthInfo": {
    "nickname": "우나영",
    "dateTimeLocal": "1999-02-25T14:30:00",
    "utcOffset": "+09:00",
    "placeName": "서울특별시 강남구 역삼동",
    "latitude": 37.4999,
    "longitude": 127.037
  },
  "favoriteIds": [],
  "activeChartVersion": "1999-02-25T14:30:00_37.4999_127.037_+09:00",
  "createdAt": "2026-05-31T12:00:00.000Z",
  "updatedAt": "2026-05-31T12:00:00.000Z"
}
```

### `users/demo-doyeon`

```json
{
  "uid": "demo-doyeon",
  "authProvider": "dev",
  "nickname": "김도연",
  "friendCode": "DOY001",
  "profileCompleted": true,
  "sunSign": "Cancer",
  "birthInfo": {
    "nickname": "김도연",
    "dateTimeLocal": "1998-07-11T09:20:00",
    "utcOffset": "+09:00",
    "placeName": "서울특별시 마포구 서교동",
    "latitude": 37.5558,
    "longitude": 126.9237
  },
  "favoriteIds": [],
  "activeChartVersion": "1998-07-11T09:20:00_37.5558_126.9237_+09:00",
  "createdAt": "2026-05-31T12:00:00.000Z",
  "updatedAt": "2026-05-31T12:00:00.000Z"
}
```

### `users/demo-seoyeon`

```json
{
  "uid": "demo-seoyeon",
  "authProvider": "dev",
  "nickname": "배서연",
  "friendCode": "SEO001",
  "profileCompleted": true,
  "sunSign": "Libra",
  "birthInfo": {
    "nickname": "배서연",
    "dateTimeLocal": "2000-10-03T21:10:00",
    "utcOffset": "+09:00",
    "placeName": "부산광역시 해운대구 우동",
    "latitude": 35.1632,
    "longitude": 129.1635
  },
  "favoriteIds": [],
  "activeChartVersion": "2000-10-03T21:10:00_35.1632_129.1635_+09:00",
  "createdAt": "2026-05-31T12:00:00.000Z",
  "updatedAt": "2026-05-31T12:00:00.000Z"
}
```

### `users/demo-seonwoo`

```json
{
  "uid": "demo-seonwoo",
  "authProvider": "dev",
  "nickname": "이선우",
  "friendCode": "SUN001",
  "profileCompleted": true,
  "sunSign": "Sagittarius",
  "birthInfo": {
    "nickname": "이선우",
    "dateTimeLocal": "1997-12-08T07:45:00",
    "utcOffset": "+09:00",
    "placeName": "인천광역시 연수구 송도동",
    "latitude": 37.3826,
    "longitude": 126.6431
  },
  "favoriteIds": [],
  "activeChartVersion": "1997-12-08T07:45:00_37.3826_126.6431_+09:00",
  "createdAt": "2026-05-31T12:00:00.000Z",
  "updatedAt": "2026-05-31T12:00:00.000Z"
}
```

## 5. `friendCodes` 컬렉션 샘플

Firestore 콘솔에서 컬렉션 `friendCodes` 를 만들고 아래 문서 4개를 추가하면 된다.  
문서 ID 자체를 친구 코드와 동일하게 넣는 것이 핵심이다.

### `friendCodes/UNA001`

```json
{
  "code": "UNA001",
  "uid": "demo-una",
  "nicknameSnapshot": "우나영",
  "active": true,
  "createdAt": "2026-05-31T12:00:00.000Z",
  "updatedAt": "2026-05-31T12:00:00.000Z"
}
```

### `friendCodes/DOY001`

```json
{
  "code": "DOY001",
  "uid": "demo-doyeon",
  "nicknameSnapshot": "김도연",
  "active": true,
  "createdAt": "2026-05-31T12:00:00.000Z",
  "updatedAt": "2026-05-31T12:00:00.000Z"
}
```

### `friendCodes/SEO001`

```json
{
  "code": "SEO001",
  "uid": "demo-seoyeon",
  "nicknameSnapshot": "배서연",
  "active": true,
  "createdAt": "2026-05-31T12:00:00.000Z",
  "updatedAt": "2026-05-31T12:00:00.000Z"
}
```

### `friendCodes/SUN001`

```json
{
  "code": "SUN001",
  "uid": "demo-seonwoo",
  "nicknameSnapshot": "이선우",
  "active": true,
  "createdAt": "2026-05-31T12:00:00.000Z",
  "updatedAt": "2026-05-31T12:00:00.000Z"
}
```

## 6. 실제 테스트 방법

가장 쉬운 테스트 순서:

1. Web 또는 Android에서 앱 실행
2. 테스트용 계정으로 로그인
3. 로그인한 계정의 실제 Firebase Auth uid 와 Firestore `users/{uid}` 가 맞는지 확인한다
4. 친구 화면에서 아래 코드를 검색한다
   - `DOY001`
   - `SEO001`
   - `SUN001`
5. 검색 결과가 뜨면 `요청` 버튼을 눌러 `friendRequests` 문서가 생성되는지 확인한다

## 7. 선택 입력: 요청/친구 목록까지 바로 보이게 하는 데이터

검색만이 아니라 아래 두 탭도 바로 보이게 하려면 추가로 넣는다.

- `받은 요청`
- `전체 친구`

### 7-1. 받은 요청 샘플

`demo-una` 가 받은 요청 1개를 보이게 하려면:

문서 경로: `friendRequests/sample_doyeon_to_una`

```json
{
  "fromUid": "demo-doyeon",
  "fromNickname": "김도연",
  "fromSunSign": "Cancer",
  "toUid": "demo-una",
  "pairKey": "demo-doyeon__demo-una",
  "status": "pending",
  "createdAt": "2026-05-31T12:10:00.000Z"
}
```

### 7-2. 전체 친구 샘플

`demo-una` 에게 이미 친구 2명이 보이게 하려면:

문서 경로 1: `friendships/demo-seoyeon__demo-una`

```json
{
  "pairKey": "demo-seoyeon__demo-una",
  "uids": ["demo-seoyeon", "demo-una"],
  "createdAt": "2026-05-31T12:20:00.000Z",
  "createdFromRequestId": "sample_seed"
}
```

문서 경로 2: `friendships/demo-seonwoo__demo-una`

```json
{
  "pairKey": "demo-seonwoo__demo-una",
  "uids": ["demo-seonwoo", "demo-una"],
  "createdAt": "2026-05-31T12:21:00.000Z",
  "createdFromRequestId": "sample_seed"
}
```

그리고 `users/demo-una.favoriteIds` 는 예를 들어 아래처럼 바꿀 수 있다.

```json
["demo-seoyeon", "demo-seonwoo"]
```

## 8. 현재 소스 기준 주의사항

1. `friendCodes` 가 없으면 검색은 절대 되지 않는다  
   이유: 현재 검색은 `users.friendCode` 스캔이 아니라 `friendCodes/{code}` 조회만 사용한다.

2. `users/{uid}` 문서 안에 `uid` 필드도 반드시 넣는 것이 안전하다  
   이유: 검색 결과에서 `_searchResult['uid']` 를 바로 읽어 요청 전송에 사용한다.

3. Web 테스트라면 Firestore 샘플 데이터보다 먼저 `.env` 의 `FIREBASE_WEB_*` 값이 필요하다  
   이유: 현재 Web Firebase 초기화는 [lib/core/firebase/firebase_bootstrap.dart](/Users/nywoo/proj/stellara/lib/core/firebase/firebase_bootstrap.dart:41) 의 환경변수 기반이다.

4. `friendRequests.createdAt` 는 현재 코드상 문자열 ISO가 가장 안전하다  
   이유: [FriendRequest.fromMap](/Users/nywoo/proj/stellara/lib/features/friends/domain/friend.dart:48) 이 `DateTime.tryParse(map['createdAt'].toString())` 를 사용하기 때문이다.

## 9. 현재 `main` 브랜치에 대한 짧은 분석 메모

`main` 은 5월 31일 기준으로 다음 변경이 이미 들어와 있다.

- 도연 협업 브랜치의 친구 기능 코드 머지
- `friend_repository.dart` 기반 Firestore 직접 검색/요청/수락 구현
- `users/` 도메인 모듈 추가
- `shared_preferences` 기반 L2 디스크 캐시 추가
- SDD v1.2 현행화

다만 아직 같이 보이는 미정합도 있다.

- `docs/SDD_input_codebase_overview.md` 는 현재 친구 기능 구현 상태를 덜 반영한 오래된 설명이 남아 있다
- `.env.example` 는 Web Firebase 키 설명이 빠져 있어 현재 소스보다 뒤처져 있다
- `Onboarding` 의 Firestore 저장 연결은 아직 화면 코드에 완전히 붙지 않은 구간이 있다

즉, **친구 기능은 실제로 붙었고 샘플 데이터 테스트는 가능하지만, 문서/연결 일부는 아직 정리 중인 상태**로 보면 된다.
