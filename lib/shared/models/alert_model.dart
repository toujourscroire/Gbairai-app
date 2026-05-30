import 'package:freezed_annotation/freezed_annotation.dart';

part 'alert_model.freezed.dart';
part 'alert_model.g.dart';

enum AlertLevel {
  preGbairai('pre_gbairai', '🔥', 'Pré-Gbairai'),
  local('local', '🔥🔥', 'Gbairai Local'),
  national('national', '🚨', 'Gbairai National'),
  legendaire('legendaire', '👑', 'Gbairai Légendaire');

  final String value;
  final String badge;
  final String label;
  const AlertLevel(this.value, this.badge, this.label);

  static AlertLevel fromString(String value) {
    return AlertLevel.values.firstWhere(
      (l) => l.value == value,
      orElse: () => AlertLevel.preGbairai,
    );
  }
}

@freezed
class AlertModel with _$AlertModel {
  const factory AlertModel({
    required String id,
    required String contentId,
    required AlertLevel level,
    required String titleGenerated,
    required DateTime triggeredAt,
    @Default(0) int sentCount,
    @Default(0) int openedCount,
    double? openRate,
    @Default(false) bool isSponsored,
    String? cityScope,
    // Contenu associé (dénormalisé pour affichage rapide)
    String? contentType,
    String? contentThumbnailUrl,
    String? contentCaption,
    int? contentViewsCount,
    String? authorUsername,
    String? authorAvatarUrl,
  }) = _AlertModel;

  factory AlertModel.fromJson(Map<String, dynamic> json) =>
      _$AlertModelFromJson(json);
}
