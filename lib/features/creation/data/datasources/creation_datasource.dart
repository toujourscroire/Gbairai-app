import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/error/failures.dart';
import '../../../../shared/models/content_model.dart';

class CreationDatasource {
  SupabaseClient get _client => SupabaseService.client;
  // ── Publication TEXTE ──────────────────────────────────────────────
  Future<ContentModel> publishText({
    required String caption,
    required String textFont,
    required String textSize,
    required String textBackground,
    required bool isAnonymous,
    required String city,
    List<String> hashtags = const [],
  }) async {
    final userId = SupabaseService.internalUserId;
    if (userId == null) throw const Failure.unauthenticated();
    if (caption.trim().isEmpty) {
      throw const Failure.validationError(field: 'caption', message: 'Le texte est vide');
    }
    if (caption.length > 280) {
      throw const Failure.validationError(field: 'caption', message: 'Max 280 caractères');
    }

    final data = await _client
        .from('contents')
        .insert({
          'user_id': userId,
          'type': 'text',
          'caption': caption.trim(),
          'text_font': textFont,
          'text_size': textSize,
          'text_background': textBackground,
          'is_anonymous': isAnonymous,
          'city': city,
          'visibility': 'public',
          'moderation_status': 'pending',
        })
        .select('''
          id, user_id, type, caption, text_font, text_size, text_background,
          city, is_anonymous, moderation_status, created_at
        ''')
        .single();

    // Lier les hashtags si présents
    if (hashtags.isNotEmpty) {
      await _linkHashtags(data['id'] as String, hashtags);
    }

    return ContentModel(
      id: data['id'] as String,
      userId: userId,
      type: ContentType.text,
      caption: data['caption'] as String?,
      textFont: data['text_font'] as String? ?? textFont,
      textSize: data['text_size'] as String? ?? textSize,
      textBackground: data['text_background'] as String? ?? textBackground,
      isAnonymous: data['is_anonymous'] as bool? ?? isAnonymous,
      city: data['city'] as String? ?? city,
      createdAt: DateTime.tryParse(data['created_at'] as String? ?? ''),
    );
  }

  // ── Publication VIDÉO ──────────────────────────────────────────────
  Future<ContentModel> publishVideo({
    required String filePath,
    String? caption,
    required bool isAnonymous,
    required String city,
    void Function(double progress)? onProgress,
  }) async {
    final userId = SupabaseService.internalUserId;
    if (userId == null) throw const Failure.unauthenticated();

    final file = File(filePath);
    if (!file.existsSync()) {
      throw const Failure.validationError(field: 'file', message: 'Fichier introuvable');
    }

    // Générer un nom unique
    final fileId = const Uuid().v4();
    final ext = p.extension(filePath).toLowerCase();
    final storagePath = 'videos/$userId/$fileId$ext';

    onProgress?.call(0.1);

    // Upload Supabase Storage (bucket "media")
    await _client.storage.from('media').upload(
      storagePath,
      file,
      fileOptions: const FileOptions(
        cacheControl: '3600',
        upsert: false,
        contentType: 'video/mp4',
      ),
    );

    onProgress?.call(0.8);

    final mediaUrl = _client.storage.from('media').getPublicUrl(storagePath);

    // Insert content
    final data = await _client
        .from('contents')
        .insert({
          'user_id': userId,
          'type': 'video',
          'media_url': mediaUrl,
          'caption': caption?.trim(),
          'is_anonymous': isAnonymous,
          'city': city,
          'visibility': 'public',
          'moderation_status': 'pending',
        })
        .select('id, user_id, type, media_url, caption, city, is_anonymous, created_at')
        .single();

    onProgress?.call(1.0);

    return ContentModel(
      id: data['id'] as String,
      userId: userId,
      type: ContentType.video,
      mediaUrl: data['media_url'] as String?,
      caption: data['caption'] as String?,
      isAnonymous: isAnonymous,
      city: city,
      createdAt: DateTime.tryParse(data['created_at'] as String? ?? ''),
    );
  }

  // ── Publication VOCALE ─────────────────────────────────────────────
  Future<ContentModel> publishVoice({
    required String filePath,
    required String voiceTitle,
    required String voiceCoverBg,
    required bool isAnonymous,
    required String city,
    double? durationSeconds,
    void Function(double progress)? onProgress,
  }) async {
    final userId = SupabaseService.internalUserId;
    if (userId == null) throw const Failure.unauthenticated();
    if (voiceTitle.trim().isEmpty) {
      throw const Failure.validationError(field: 'voiceTitle', message: 'Titre requis');
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      throw const Failure.validationError(field: 'file', message: 'Fichier audio introuvable');
    }

    final fileId = const Uuid().v4();
    final ext = p.extension(filePath).toLowerCase().isEmpty ? '.m4a' : p.extension(filePath).toLowerCase();
    final storagePath = 'voices/$userId/$fileId$ext';

    onProgress?.call(0.1);

    await _client.storage.from('media').upload(
      storagePath,
      file,
      fileOptions: FileOptions(
        cacheControl: '3600',
        upsert: false,
        contentType: ext == '.mp3' ? 'audio/mpeg' : 'audio/m4a',
      ),
    );

    onProgress?.call(0.8);

    final mediaUrl = _client.storage.from('media').getPublicUrl(storagePath);

    final data = await _client
        .from('contents')
        .insert({
          'user_id': userId,
          'type': 'audio',
          'media_url': mediaUrl,
          'voice_title': voiceTitle.trim(),
          'voice_cover_bg': voiceCoverBg,
          'duration_seconds': durationSeconds,
          'is_anonymous': isAnonymous,
          'city': city,
          'visibility': 'public',
          'moderation_status': 'pending',
        })
        .select('id, user_id, type, media_url, voice_title, voice_cover_bg, duration_seconds, city, is_anonymous, created_at')
        .single();

    onProgress?.call(1.0);

    return ContentModel(
      id: data['id'] as String,
      userId: userId,
      type: ContentType.audio,
      mediaUrl: data['media_url'] as String?,
      voiceTitle: data['voice_title'] as String?,
      voiceCoverBg: data['voice_cover_bg'] as String? ?? voiceCoverBg,
      durationSeconds: (data['duration_seconds'] as num?)?.toDouble(),
      isAnonymous: isAnonymous,
      city: city,
      createdAt: DateTime.tryParse(data['created_at'] as String? ?? ''),
    );
  }

  // ── Helper hashtags ────────────────────────────────────────────────
  Future<void> _linkHashtags(String contentId, List<String> hashtags) async {
    for (final tag in hashtags) {
      final cleaned = tag.replaceAll('#', '').trim().toLowerCase();
      if (cleaned.isEmpty) continue;
      try {
        // Upsert hashtag + lien
        final result = await _client
            .from('hashtags')
            .upsert({'tag': cleaned}, onConflict: 'tag')
            .select('id')
            .single();
        await _client.from('content_hashtags').insert({
          'content_id': contentId,
          'hashtag_id': result['id'],
        });
      } catch (_) {
        // Ignore les erreurs de hashtag — le contenu est déjà publié
      }
    }
  }
}
