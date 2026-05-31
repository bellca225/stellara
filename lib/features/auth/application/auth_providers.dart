// lib/features/auth/application/auth_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// 현재 로그인된 사용자. null = 미로그인.
final currentUserProvider = StateProvider<AppUser?>((ref) => null);
