import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/creation_datasource.dart';
import '../../../../shared/models/content_model.dart';

// ── État de publication ─────────────────────────────────────────────────────

sealed class PublicationState {
  const PublicationState();
}

class PublicationIdle extends PublicationState {
  const PublicationIdle();
}

class PublicationLoading extends PublicationState {
  final double progress;
  const PublicationLoading({this.progress = 0.0});
}

class PublicationSuccess extends PublicationState {
  final ContentModel content;
  const PublicationSuccess(this.content);
}

class PublicationError extends PublicationState {
  final String message;
  const PublicationError(this.message);
}

// ── Provider ────────────────────────────────────────────────────────────────

final creationDatasourceProvider = Provider<CreationDatasource>(
  (_) => CreationDatasource(),
);

class CreationNotifier extends StateNotifier<PublicationState> {
  CreationNotifier(this._datasource) : super(const PublicationIdle());

  final CreationDatasource _datasource;

  // ── Publier texte ──────────────────────────────────────────────────
  Future<void> publishText({
    required String caption,
    required String textFont,
    required String textSize,
    required String textBackground,
    required bool isAnonymous,
    required String city,
    List<String> hashtags = const [],
  }) async {
    state = const PublicationLoading(progress: 0.5);
    try {
      final content = await _datasource.publishText(
        caption: caption,
        textFont: textFont,
        textSize: textSize,
        textBackground: textBackground,
        isAnonymous: isAnonymous,
        city: city,
        hashtags: hashtags,
      );
      state = PublicationSuccess(content);
    } catch (e) {
      state = PublicationError(_friendlyError(e));
    }
  }

  // ── Publier vidéo ──────────────────────────────────────────────────
  Future<void> publishVideo({
    required String filePath,
    String? caption,
    required bool isAnonymous,
    required String city,
  }) async {
    state = const PublicationLoading(progress: 0.0);
    try {
      final content = await _datasource.publishVideo(
        filePath: filePath,
        caption: caption,
        isAnonymous: isAnonymous,
        city: city,
        onProgress: (p) => state = PublicationLoading(progress: p),
      );
      state = PublicationSuccess(content);
    } catch (e) {
      state = PublicationError(_friendlyError(e));
    }
  }

  // ── Publier vocal ──────────────────────────────────────────────────
  Future<void> publishVoice({
    required String filePath,
    required String voiceTitle,
    required String voiceCoverBg,
    required bool isAnonymous,
    required String city,
    double? durationSeconds,
  }) async {
    state = const PublicationLoading(progress: 0.0);
    try {
      final content = await _datasource.publishVoice(
        filePath: filePath,
        voiceTitle: voiceTitle,
        voiceCoverBg: voiceCoverBg,
        isAnonymous: isAnonymous,
        city: city,
        durationSeconds: durationSeconds,
        onProgress: (p) => state = PublicationLoading(progress: p),
      );
      state = PublicationSuccess(content);
    } catch (e) {
      state = PublicationError(_friendlyError(e));
    }
  }

  void reset() => state = const PublicationIdle();

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('unauthenticated')) return 'Connecte-toi pour publier';
    if (msg.contains('storage')) return 'Erreur upload — réessaie';
    if (msg.contains('network')) return 'Pas de connexion internet';
    return 'Erreur inattendue — réessaie';
  }
}

final creationProvider =
    StateNotifierProvider<CreationNotifier, PublicationState>((ref) {
  return CreationNotifier(ref.watch(creationDatasourceProvider));
});
