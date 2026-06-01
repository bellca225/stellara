// lib/features/users/data/user_repository.dart
//
// Firestore `users/{uid}` 컬렉션 클라이언트 wrapper.
//
// 이 클래스는 다음을 책임진다:
//   - `users/{uid}` 1회 조회 (get)
//   - 실시간 stream (watch) → T11 에서 `currentBirthInfoProvider` 가 구독
//   - 신규 생성 (create) → anonymous sign-in 직후 1회 호출
//   - birthInfo 갱신 (upsertBirthInfo) → 온보딩 / 마이페이지 수정 시
//
// 명시적으로 안 하는 것:
//   - 친구 코드 발급 (T16 — friendCodes 컬렉션 트랜잭션이라 별도 wrapper)
//   - favoriteIds 추가/제거 (T19 — 별도 메서드로 분리)
//   - chartVersion 무효화 (T12 — astrology repository 와 함께 처리)

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../astrology/domain/birth_info.dart';
import '../domain/user_profile.dart';

class UserRepository {
  UserRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// 1회 조회. 문서가 없으면 null.
  Future<UserProfile?> get(String uid) async {
    final snap = await _users.doc(uid).get();
    final data = snap.data();
    if (data == null) return null;
    return UserProfile.fromFirestore(uid, data);
  }

  /// 실시간 stream. 문서가 없으면 null 을 emit.
  Stream<UserProfile?> watch(String uid) {
    return _users.doc(uid).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return UserProfile.fromFirestore(uid, data);
    });
  }

  /// 신규 사용자 문서 생성.
  ///
  /// anonymous sign-in 직후 [get] 결과가 null 인 경우에만 호출한다.
  /// 이미 존재하면 덮어쓰지 않도록 [merge] 를 사용해 race 안전.
  Future<void> create(UserProfile profile) async {
    await _users.doc(profile.uid).set(
          profile.toFirestore(),
          SetOptions(merge: true),
        );
  }

  /// 출생정보 + 닉네임 업데이트. T11 (Firestore 연동) / T27 (마이페이지 수정) 가 사용.
  ///
  /// `activeChartVersion` 은 [BirthInfo.chartVersion] 으로 자동 갱신해 stale 차트를 가르마.
  Future<void> upsertBirthInfo({
    required String uid,
    required BirthInfo birthInfo,
    String? nickname,
  }) async {
    final updates = <String, dynamic>{
      'birthInfo': UserProfile(
        uid: uid,
        loginId: '',
        authProvider: 'email',
        nickname: nickname ?? birthInfo.nickname,
        profileCompleted: true,
        birthInfo: birthInfo,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      ).toFirestore()['birthInfo'],
      'nickname': nickname ?? birthInfo.nickname,
      'profileCompleted': true,
      'activeChartVersion': birthInfo.chartVersion,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
    await _users.doc(uid).set(updates, SetOptions(merge: true));
  }

  /// 즐겨찾기 갱신. T19 에서 사용. 최대 3명 제약은 Firestore Rules 가 강제하지만
  /// 클라이언트에서도 사전 검증해 UX 를 매끄럽게 한다.
  Future<void> updateFavorites({
    required String uid,
    required List<String> favoriteIds,
  }) async {
    if (favoriteIds.length > 3) {
      throw ArgumentError(
        '즐겨찾기는 최대 3명까지 등록할 수 있어요 (현재 ${favoriteIds.length}명).',
      );
    }
    await _users.doc(uid).set(
      {
        'favoriteIds': favoriteIds,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }
}
