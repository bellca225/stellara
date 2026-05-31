// lib/features/friends/application/friend_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/friend_repository.dart';

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return FriendRepository();
});
