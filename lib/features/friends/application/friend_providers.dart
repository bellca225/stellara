import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/friend_repository.dart';

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return FriendRepository();
});
