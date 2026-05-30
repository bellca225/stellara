import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/app_user.dart';

class AuthRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<AppUser?> signInWithGoogle() async {
    try {
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');

      final userCredential = await _auth.signInWithPopup(provider);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) return null;

      final doc = await _db.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists) {
        return AppUser.fromMap(doc.data()!);
      }

      final friendCode = _generateCode(firebaseUser.uid);
      final newUser = AppUser(
        uid: firebaseUser.uid,
        nickname: firebaseUser.displayName ?? '별자리 유저',
        friendCode: friendCode,
        profileCompleted: false,
        authProvider: 'google',
      );

      await _db.collection('users').doc(firebaseUser.uid).set(newUser.toMap());
      await _db.collection('friendCodes').doc(friendCode).set({
        'code': friendCode,
        'uid': firebaseUser.uid,
        'active': true,
      });

      return newUser;
    } catch (e) {
      return null;
    }
  }

  String _generateCode(String uid) {
    final base = uid.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    return base.substring(0, 3) +
        (uid.hashCode.abs() % 1000).toString().padLeft(3, '0');
  }

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
    await _db
        .collection('users')
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
