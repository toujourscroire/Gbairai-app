import 'package:freezed_annotation/freezed_annotation.dart';

part 'content_model.freezed.dart';
part 'content_model.g.dart';

enum ContentType { video, text, audio }

enum GbairaiLevel { preGbairai, local, national, legendaire }

enum ModerationStatus { pending, approved, review, rejected }

@freezed
class ContentModel with _$ContentModel {
  const factory ContentModel({
    required String id,
    required String userId,
    required ContentType type,

    // Média
    String? mediaUrl,
    String? streamId,
    String? thumbnailUrl,
    double? durationSeconds,

    // Texte
    String? caption,
    @Default('inter') String textFont,
    @Default('normal') String textSize,
    @Default('gradient_1') String textBackground,

    // Audio spécifique
    String? voiceTitle,
    @Default('orange') String voiceCoverBg,

    // Métadonnées
    @Default('Abidjan') String city,
    String? district,
    @Default(false) bool isAnonymous,
    String? anonUsername,
    @Default('public') String visibility,

    // Scoring
    @Default(0.0) double score,
    @Default(0.0) double scoreAdjusted,
    @Default(0) int viewsCount,
    @Default(0) int reactionsCount,
    @Default(0) int commentsCount,
    @Default(0) int sharesCount,
    @Default(0) int voiceReactionsCount,
    GbairaiLevel? gbairaiLevel,

    // Auteur (dénormalisé pour affichage)
    String? authorUsername,
    String? authorDisplayName,
    String? authorAvatarUrl,
    String? authorLevel,

    // Réaction de l'utilisateur courant
    String? myReaction,

    // Modération
    @Default('approved') String moderationStatus,
    @Default(false) bool isFlagged,

    // Timestamps
    DateTime? createdAt,
    DateTime? publishedAt,
  }) = _ContentModel;

  factory ContentModel.fromJson(Map<String, dynamic> json) =>
      _$ContentModelFromJson(json);
}

@freezed
class ReactionModel with _$ReactionModel {
  const factory ReactionModel({
    required String id,
    required String contentId,
    required String userId,
    required String reactionType,
    DateTime? createdAt,
  }) = _ReactionModel;

  factory ReactionModel.fromJson(Map<String, dynamic> json) =>
      _$ReactionModelFromJson(json);
}

@freezed
class CommentModel with _$CommentModel {
  const factory CommentModel({
    required String id,
    required String contentId,
    required String userId,
    String? parentId,
    required String body,
    @Default(false) bool isPinned,
    String? authorUsername,
    String? authorAvatarUrl,
    String? authorLevel,
    DateTime? createdAt,
  }) = _CommentModel;

  factory CommentModel.fromJson(Map<String, dynamic> json) =>
      _$CommentModelFromJson(json);
}
