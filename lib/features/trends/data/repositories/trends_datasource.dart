import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../shared/models/content_model.dart';

class TrendHashtag {
  final String id;
  final String tag;
  final int usesCount;
  final int usesLastDay;
  final double trendingScore;

  const TrendHashtag({
    required this.id,
    required this.tag,
    required this.usesCount,
    required this.usesLastDay,
    required this.trendingScore,
  });
}

class TrendsDatasource {
  SupabaseClient get _client => SupabaseService.client;

  // ── Top trending content ─────────────────────────────────────────
  Future<List<ContentModel>> fetchTopContent({
    int limit = 20,
    String period = 'day', // 'hour' | 'day' | 'week'
  }) async {
    final cutoff = switch (period) {
      'hour' => DateTime.now().subtract(const Duration(hours: 1)),
      'week' => DateTime.now().subtract(const Duration(days: 7)),
      _ => DateTime.now().subtract(const Duration(days: 1)),
    };

    final result = await _client
        .from('contents')
        .select('''
          id, user_id, type, media_url, stream_id, thumbnail_url,
          caption, views_count, reactions_count, comments_count,
          score_adjusted, gbairai_level, created_at,
          users!inner(
            username,
            profiles!inner(display_name, avatar_url, level)
          )
        ''')
        .eq('moderation_status', 'approved')
        .eq('visibility', 'public')
        .isFilter('deleted_at', null)
        .gte('created_at', cutoff.toIso8601String())
        .order('score_adjusted', ascending: false)
        .limit(limit);

    return (result as List).map((item) {
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
        caption: item['caption'] as String?,
        viewsCount: item['views_count'] as int? ?? 0,
        reactionsCount: item['reactions_count'] as int? ?? 0,
        commentsCount: item['comments_count'] as int? ?? 0,
        scoreAdjusted: (item['score_adjusted'] as num?)?.toDouble() ?? 0.0,
        authorUsername: user?['username'] as String?,
        authorDisplayName: profile?['display_name'] as String?,
        authorAvatarUrl: profile?['avatar_url'] as String?,
        authorLevel: profile?['level'] as String?,
        createdAt: DateTime.tryParse(item['created_at'] as String? ?? ''),
      );
    }).toList();
  }

  // ── Top hashtags tendances ────────────────────────────────────────
  Future<List<TrendHashtag>> fetchTrendingHashtags({int limit = 20}) async {
    final result = await _client
        .from('hashtags')
        .select('id, tag, uses_count, uses_last_day, trending_score')
        .gt('uses_last_day', 0)
        .order('trending_score', ascending: false)
        .limit(limit);

    return (result as List).map((item) {
      return TrendHashtag(
        id: item['id'] as String,
        tag: item['tag'] as String,
        usesCount: item['uses_count'] as int? ?? 0,
        usesLastDay: item['uses_last_day'] as int? ?? 0,
        trendingScore: (item['trending_score'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  // ── Nombre d'utilisateurs actifs (approximatif) ──────────────────
  Future<int> fetchActiveUsersCount() async {
    final cutoff =
        DateTime.now().subtract(const Duration(hours: 1)).toIso8601String();

    final result = await _client
        .from('content_views')
        .select('user_id')
        .gte('created_at', cutoff);

    // Compter les user_id uniques
    final ids = (result as List)
        .map((r) => r['user_id'] as String?)
        .whereType<String>()
        .toSet();
    return ids.length;
  }
}
