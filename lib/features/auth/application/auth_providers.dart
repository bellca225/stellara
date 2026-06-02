// lib/features/auth/application/auth_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/login_id_repository.dart';
import '../domain/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final loginIdRepositoryProvider = Provider<LoginIdRepository>(
  (ref) => LoginIdRepository(FirebaseFirestore.instance),
);

/// 현재 로그인된 사용자. null = 미로그인.
final currentUserProvider = StateProvider<AppUser?>((ref) => null);
