import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/error/failures.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/models/content_model.dart';

class ProfileDatasource {
  SupabaseClient get _client => SupabaseService.client;

  // ── Charger un profil utilisateur ─────────────────────────────────
  Future<UserModel> fetchProfile(String userId) async {
    final result = await _client
        .from('users')
        .select('''
          id, username,
          profiles!inner(
            display_name, bio, avatar_url, banner_url, city, level,
            is_verified, is_business, followers_count, following_count,
            posts_count
          )
        ''')
        .eq('id', userId)
        .maybeSingle();

    if (result == null) throw const Failure.accountNotFound();
    return _mapUser(result);
  }

  // ── Contenus publiés par un utilisateur ───────────────────────────
  Future<List<ContentModel>> fetchUserContents(
    String userId, {
    int offset = 0,
    int limit = 30,
  }) async {
    final result = await _client
        .from('contents')
        .select(
            'id, type, media_url, stream_id, thumbnail_url, caption, '
            'views_count, reactions_count, created_at')
        .eq('user_id', userId)
        .eq('moderation_status', 'approved')
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (result as List).map((item) {
      return ContentModel(
        id: item['id'] as String,
        userId: userId,
        type: ContentType.values.firstWhere(
          (t) => t.name == (item['type'] as String),
          orElse: () => ContentType.video,
        ),
        mediaUrl: item['media_url'] as String?,
        streamId: item['stream_id'] as String?,
        thumbnailUrl: item['thumbnail_url'] as String?,
        caption: item['caption'] as String?,
        viewsCount: item['views_count'] as int? ?? 0,
        reactionsCount: item['reactions_count'] as int? ?? 0,
        createdAt:
            DateTime.tryParse(item['created_at'] as String? ?? ''),
      );
    }).toList();
  }

  // ── Follow ────────────────────────────────────────────────────────
  Future<void> follow(String targetUserId) async {
    final myId = SupabaseService.currentUser?.id;
    if (myId == null) throw const Failure.unauthenticated();
    if (myId == targetUserId) return; // Pas de self-follow

    await _client.from('follows').upsert({
      'follower_id': myId,
      'following_id': targetUserId,
    }, onConflict: 'follower_id, following_id');

    // Mise à jour atomique des compteurs
    // Le trigger `trg_follow_counts` met à jour followers_count / following_count
    // automatiquement. Pas besoin de RPC côté client.
  }

  // ── Unfollow ──────────────────────────────────────────────────────
  Future<void> unfollow(String targetUserId) async {
    final myId = SupabaseService.currentUser?.id;
    if (myId == null) throw const Failure.unauthenticated();

    await _client
        .from('follows')
        .delete()
        .eq('follower_id', myId)
        .eq('following_id', targetUserId);

    // Le trigger `trg_follow_counts` décrémente les compteurs automatiquement.
  }

  // ── Vérifier si je suis quelqu'un ────────────────────────────────
  Future<bool> isFollowing(String targetUserId) async {
    final myId = SupabaseService.currentUser?.id;
    if (myId == null) return false;

    final result = await _client
        .from('follows')
        .select('follower_id')
        .eq('follower_id', myId)
        .eq('following_id', targetUserId)
        .maybeSingle();

    return result != null;
  }

  // ── Compteurs en temps réel (stream) ─────────────────────────────
  Stream<Map<String, int>> countersStream(String userId) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((rows) {
          if (rows.isEmpty) return {'followers': 0, 'following': 0, 'posts': 0};
          final row = rows.first;
          return {
            'followers': row['followers_count'] as int? ?? 0,
            'following': row['following_count'] as int? ?? 0,
            'posts': row['posts_count'] as int? ?? 0,
          };
        });
  }

  // ── Helpers ───────────────────────────────────────────────────────
  UserModel _mapUser(Map<String, dynamic> row) {
    final profileRaw = row['profiles'];
    final profile = profileRaw is Map<String, dynamic>
        ? profileRaw
        : (profileRaw is List<dynamic> && profileRaw.isNotEmpty)
            ? profileRaw.first as Map<String, dynamic>
            : <String, dynamic>{};
    return UserModel(
      id: row['id'] as String,
      username: row['username'] as String,
      displayName: profile['display_name'] as String? ?? '',
      bio: profile['bio'] as String?,
      avatarUrl: profile['avatar_url'] as String?,
      bannerUrl: profile['banner_url'] as String?,
      city: profile['city'] as String? ?? 'Abidjan',
      level: profile['level'] as String? ?? 'debutant',
      isVerified: profile['is_verified'] as bool? ?? false,
      isBusiness: profile['is_business'] as bool? ?? false,
      followersCount: profile['followers_count'] as int? ?? 0,
      followingCount: profile['following_count'] as int? ?? 0,
      postsCount: profile['posts_count'] as int? ?? 0,
    );
  }

}
