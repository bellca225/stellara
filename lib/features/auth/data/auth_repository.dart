import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/app_user.dart';

class AuthRepository {
  final _db = FirebaseFirestore.instance;

  Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return AppUser.fromMap(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveUser(AppUser user) async {
    await _db.collection('users').doc(user.uid).set(
      user.toMap(),
      SetOptions(merge: true),
    );
  }
}