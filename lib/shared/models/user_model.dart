import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    String? phone,
    String? email,
    required String username,
    required String displayName,
    String? bio,
    String? avatarUrl,
    String? bannerUrl,
    @Default('Abidjan') String city,
    @Default('debutant') String level,
    @Default(0) int followersCount,
    @Default(0) int followingCount,
    @Default(0) int postsCount,
    @Default(false) bool isVerified,
    @Default(false) bool isBusiness,
    @Default(false) bool isBanned,
    @Default('user') String role,
    DateTime? createdAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

enum UserLevel {
  debutant('Débutant', '🌱'),
  influenceur('Influenceur', '⚡'),
  grandPatron('Grand Patron', '👑'),
  legendeIvoirienne('Légende Ivoirienne', '🏆');

  final String label;
  final String emoji;
  const UserLevel(this.label, this.emoji);

  static UserLevel fromString(String value) {
    return switch (value) {
      'influenceur' => UserLevel.influenceur,
      'grand_patron' => UserLevel.grandPatron,
      'legende' => UserLevel.legendeIvoirienne,
      _ => UserLevel.debutant,
    };
  }
}
