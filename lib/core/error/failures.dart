import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

@freezed
sealed class Failure with _$Failure {
  // Auth
  const factory Failure.unauthenticated() = UnauthenticatedFailure;
  const factory Failure.invalidCredentials() = InvalidCredentialsFailure;
  const factory Failure.otpExpired() = OtpExpiredFailure;
  const factory Failure.otpInvalid() = OtpInvalidFailure;
  const factory Failure.accountBanned({String? until}) = AccountBannedFailure;
  const factory Failure.accountNotFound() = AccountNotFoundFailure;
  const factory Failure.phoneAlreadyUsed() = PhoneAlreadyUsedFailure;

  // Network
  const factory Failure.noConnection() = NoConnectionFailure;
  const factory Failure.timeout() = TimeoutFailure;
  const factory Failure.serverError({String? message}) = ServerErrorFailure;

  // Content
  const factory Failure.contentNotFound() = ContentNotFoundFailure;
  const factory Failure.contentRejected({String? reason}) = ContentRejectedFailure;
  const factory Failure.uploadFailed() = UploadFailedFailure;
  const factory Failure.fileTooLarge() = FileTooLargeFailure;
  const factory Failure.unsupportedFormat() = UnsupportedFormatFailure;

  // Rate Limiting
  const factory Failure.rateLimited({required String retryAfter}) = RateLimitedFailure;

  // Access Control
  const factory Failure.forbidden() = ForbiddenFailure;
  const factory Failure.blocked() = BlockedFailure;

  // Validation
  const factory Failure.validationError({required String field, required String message}) = ValidationFailure;

  // Generic
  const factory Failure.unknown({String? message}) = UnknownFailure;
}

extension FailureMessage on Failure {
  String get userMessage => switch (this) {
    UnauthenticatedFailure() => 'Connecte-toi pour continuer',
    InvalidCredentialsFailure() => 'Identifiants incorrects',
    OtpExpiredFailure() => 'Le code a expiré — demande-en un nouveau',
    OtpInvalidFailure() => 'Code incorrect',
    AccountBannedFailure(:final until) =>
        until != null ? 'Compte suspendu jusqu\'au $until' : 'Compte suspendu',
    AccountNotFoundFailure() => 'Compte introuvable',
    PhoneAlreadyUsedFailure() => 'Ce numéro est déjà utilisé',
    NoConnectionFailure() => 'Pas de connexion — vérifie ton réseau',
    TimeoutFailure() => 'Connexion trop lente — réessaie',
    ServerErrorFailure(:final message) => message ?? 'Erreur serveur — réessaie',
    ContentNotFoundFailure() => 'Contenu introuvable',
    ContentRejectedFailure(:final reason) =>
        reason != null ? 'Contenu refusé : $reason' : 'Contenu refusé par la modération',
    UploadFailedFailure() => 'Upload échoué — réessaie',
    FileTooLargeFailure() => 'Fichier trop volumineux',
    UnsupportedFormatFailure() => 'Format non supporté',
    RateLimitedFailure(:final retryAfter) => 'Trop vite ! $retryAfter',
    ForbiddenFailure() => 'Action non autorisée',
    BlockedFailure() => 'Action impossible',
    ValidationFailure(:final message) => message,
    UnknownFailure(:final message) => message ?? 'Une erreur est survenue',
  };
}
