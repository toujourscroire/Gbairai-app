import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/profile_datasource.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/models/content_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ── Datasource provider ─────────────────────────────────────────────────────

final profileDatasourceProvider = Provider<ProfileDatasource>(
  (_) => ProfileDatasource(),
);

// ── Profil d'un utilisateur (par userId) ───────────────────────────────────

final profileProvider = FutureProvider.family<UserModel, String>((ref, userId) {
  return ref.watch(profileDatasourceProvider).fetchProfile(userId);
});

// ── Profil courant (depuis l'état auth) ───────────────────────────────────

final myProfileProvider = Provider<UserModel?>((ref) {
  final auth = ref.watch(authControllerProvider);
  if (auth is AuthAuthenticated) return auth.user;
  return null;
});

// ── Contenus d'un utilisateur ─────────────────────────────────────────────

final userContentsProvider =
    FutureProvider.family<List<ContentModel>, String>((ref, userId) {
  return ref.watch(profileDatasourceProvider).fetchUserContents(userId);
});

// ── Compteurs temps réel ──────────────────────────────────────────────────

final profileCountersProvider =
    StreamProvider.family<Map<String, int>, String>((ref, userId) {
  return ref.watch(profileDatasourceProvider).countersStream(userId);
});

// ── Follow state ──────────────────────────────────────────────────────────

class FollowNotifier extends StateNotifier<AsyncValue<bool>> {
  FollowNotifier(this._datasource, this._targetUserId)
      : super(const AsyncValue.loading()) {
    _init();
  }

  final ProfileDatasource _datasource;
  final String _targetUserId;

  Future<void> _init() async {
    try {
      final isFollowing = await _datasource.isFollowing(_targetUserId);
      state = AsyncValue.data(isFollowing);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> toggle() async {
    final current = state.valueOrNull ?? false;
    // Optimistic update
    state = AsyncValue.data(!current);

    try {
      if (current) {
        await _datasource.unfollow(_targetUserId);
      } else {
        await _datasource.follow(_targetUserId);
      }
    } catch (e) {
      // Rollback
      state = AsyncValue.data(current);
    }
  }
}

final followProvider = StateNotifierProvider.family<FollowNotifier,
    AsyncValue<bool>, String>((ref, targetUserId) {
  return FollowNotifier(ref.watch(profileDatasourceProvider), targetUserId);
});
