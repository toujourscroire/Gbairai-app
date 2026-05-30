import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/security/input_validator.dart';
import '../../../../core/error/failures.dart';
import '../../../../shared/models/content_model.dart';

class FeedRemoteDatasource {
  final _client = SupabaseService.client;

  // ── Feed Pour Toi (algorithme tendances) ─────────────────────────
  Future<List<ContentModel>> getForYouFeed({
    int offset = 0,
    int limit = 10,
    List<String>? categories,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw const Failure.unauthenticated();

    // RLS garantit que seuls les contenus approved + public sont retournés
    final result = await _client
        .from('contents')
        .select('''
          id, user_id, type, media_url, stream_id, thumbnail_url,
          duration_seconds, caption, text_font, text_size, text_background,
          voice_title, voice_cover_bg, city, district, is_anonymous,
          anon_username, views_count, reactions_count, comments_count,
          shares_count, voice_reactions_count, gbairai_level, score_adjusted,
          created_at,
          users!inner(
            username,
            profiles!inner(display_name, avatar_url, level)
          )
        ''')
        .eq('moderation_status', 'approved')
        .eq('visibility', 'public')
        .isFilter('deleted_at', null)
        .order('score_adjusted', ascending: false)
        .range(offset, offset + limit - 1);

    return (result as List).map((item) => _mapContent(item)).toList();
  }

  // ── Feed Abonnements (chronologique) ─────────────────────────────
  Future<List<ContentModel>> getFollowingFeed({
    int offset = 0,
    int limit = 10,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw const Failure.unauthenticated();

    // Récupérer les IDs des comptes suivis
    final following = await _client
        .from('follows')
        .select('following_id')
        .eq('follower_id', userId);

    if ((following as List).isEmpty) return [];

    final followingIds = following.map((f) => f['following_id'] as String).toList();

    final result = await _client
        .from('contents')
        .select('''
          id, user_id, type, media_url, stream_id, thumbnail_url,
          duration_seconds, caption, text_font, text_size, text_background,
          voice_title, voice_cover_bg, city, district, is_anonymous,
          anon_username, views_count, reactions_count, comments_count,
          shares_count, voice_reactions_count, gbairai_level,
          created_at,
          users!inner(
            username,
            profiles!inner(display_name, avatar_url, level)
          )
        ''')
        .inFilter('user_id', followingIds)
        .eq('moderation_status', 'approved')
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (result as List).map((item) => _mapContent(item)).toList();
  }

  // ── Enregistrer une vue ───────────────────────────────────────────
  Future<void> recordView({
    required String contentId,
    required double watchDurationSeconds,
    required String source,
  }) async {
    // Validation de l'UUID avant envoi
    if (!InputValidator.isValidUuid(contentId)) return;

    await _client.rpc('increment_view_count', params: {
      'p_content_id': contentId,
    });

    await _client.from('content_views').insert({
      'content_id': contentId,
      'user_id': SupabaseService.currentUser?.id,
      'watch_duration_seconds': watchDurationSeconds,
      'completed': watchDurationSeconds > 0,
      'source': source,
    });
  }

  // ── Réaction ─────────────────────────────────────────────────────
  Future<void> react({
    required String contentId,
    required String reactionType,
  }) async {
    if (!InputValidator.isValidUuid(contentId)) return;

    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw const Failure.unauthenticated();

    // Upsert — remplace la réaction existante
    await _client.from('reactions').upsert({
      'content_id': contentId,
      'user_id': userId,
      'reaction_type': reactionType,
    }, onConflict: 'content_id, user_id');
  }

  Future<void> removeReaction(String contentId) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('reactions')
        .delete()
        .eq('content_id', contentId)
        .eq('user_id', userId);
  }

  // ── Commentaires ──────────────────────────────────────────────────
  Future<List<CommentModel>> getComments(String contentId) async {
    if (!InputValidator.isValidUuid(contentId)) return [];

    final result = await _client
        .from('comments')
        .select('''
          id, content_id, user_id, parent_id, body, is_pinned, created_at,
          users!inner(
            username,
            profiles!inner(avatar_url, level)
          )
        ''')
        .eq('content_id', contentId)
        .isFilter('deleted_at', null)
        .isFilter('is_restricted', false)
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: true)
        .limit(100);

    return (result as List).map((item) {
      final user = item['users'] as Map<String, dynamic>;
      final profile = user['profiles'] as Map<String, dynamic>;
      return CommentModel(
        id: item['id'] as String,
        contentId: item['content_id'] as String,
        userId: item['user_id'] as String,
        parentId: item['parent_id'] as String?,
        body: item['body'] as String,
        isPinned: item['is_pinned'] as bool? ?? false,
        authorUsername: user['username'] as String?,
        authorAvatarUrl: profile['avatar_url'] as String?,
        authorLevel: profile['level'] as String?,
        createdAt: DateTime.tryParse(item['created_at'] as String? ?? ''),
      );
    }).toList();
  }

  Future<void> addComment({
    required String contentId,
    required String body,
    String? parentId,
  }) async {
    if (!InputValidator.isValidUuid(contentId)) return;
    if (parentId != null && !InputValidator.isValidUuid(parentId)) return;

    // Validation du contenu
    final validation = InputValidator.validateComment(body);
    if (validation != null) throw Failure.validationError(field: 'body', message: validation);

    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw const Failure.unauthenticated();

    await _client.from('comments').insert({
      'content_id': contentId,
      'user_id': userId,
      'parent_id': parentId,
      'body': body.trim(),
    });
  }

  // ── Signalement ───────────────────────────────────────────────────
  Future<void> reportContent({
    required String contentId,
    required String reason,
    String? detail,
  }) async {
    if (!InputValidator.isValidUuid(contentId)) return;

    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw const Failure.unauthenticated();

    // Vérifier que la raison est dans la liste autorisée (pas d'injection)
    const allowedReasons = [
      'spam', 'violence', 'nudity', 'fake_news',
      'harassment', 'hate_speech', 'other',
    ];
    if (!allowedReasons.contains(reason)) {
      throw const Failure.validationError(field: 'reason', message: 'Raison invalide');
    }

    await _client.from('reports').insert({
      'reporter_id': userId,
      'target_type': 'content',
      'target_id': contentId,
      'reason': reason,
      'detail': detail?.trim().substring(0, detail.length.clamp(0, 500)),
    });
  }

  // ── Helper de mapping ─────────────────────────────────────────────
  ContentModel _mapContent(Map<String, dynamic> item) {
    final user = item['users'] as Map<String, dynamic>?;
    final profile = user?['profiles'] as Map<String, dynamic>?;

    return ContentModel(
      id: item['id'] as String,
      userId: item['user_id'] as String,
      type: ContentType.values.firstWhere(
        (t) => t.name == (item['type'] as String),
        orElse: () => ContentType.video,
      ),
      mediaUrl: item['media_url'] as String?,
      streamId: item['stream_id'] as String?,
      thumbnailUrl: item['thumbnail_url'] as String?,
      durationSeconds: (item['duration_seconds'] as num?)?.toDouble(),
      caption: item['caption'] as String?,
      textFont: item['text_font'] as String? ?? 'inter',
      textSize: item['text_size'] as String? ?? 'normal',
      textBackground: item['text_background'] as String? ?? 'gradient_1',
      voiceTitle: item['voice_title'] as String?,
      voiceCoverBg: item['voice_cover_bg'] as String? ?? 'orange',
      city: item['city'] as String? ?? 'Abidjan',
      district: item['district'] as String?,
      isAnonymous: item['is_anonymous'] as bool? ?? false,
      anonUsername: item['anon_username'] as String?,
      viewsCount: item['views_count'] as int? ?? 0,
      reactionsCount: item['reactions_count'] as int? ?? 0,
      commentsCount: item['comments_count'] as int? ?? 0,
      sharesCount: item['shares_count'] as int? ?? 0,
      voiceReactionsCount: item['voice_reactions_count'] as int? ?? 0,
      authorUsername: user?['username'] as String?,
      authorDisplayName: profile?['display_name'] as String?,
      authorAvatarUrl: profile?['avatar_url'] as String?,
      authorLevel: profile?['level'] as String?,
      createdAt: DateTime.tryParse(item['created_at'] as String? ?? ''),
    );
  }
}
