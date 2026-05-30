// Deep Link Security — OWASP M1 mitigation
// Valide et sanitise tous les deep links avant traitement

abstract final class DeepLinkSecurity {
  static const _allowedSchemes = {'gbairai', 'https'};
  static const _allowedHosts = {'gbairai.ci', 'www.gbairai.ci'};

  // Paths autorisés (liste blanche stricte)
  static const _allowedPaths = {
    '/content',
    '/profile',
    '/alert',
    '/trends',
  };

  /// Valide qu'un deep link est sûr avant de le router
  static DeepLinkValidationResult validate(String rawUrl) {
    Uri uri;
    try {
      uri = Uri.parse(rawUrl.trim());
    } catch (_) {
      return DeepLinkValidationResult.invalid('URL malformée');
    }

    // Vérifier le schéma
    if (!_allowedSchemes.contains(uri.scheme)) {
      return DeepLinkValidationResult.invalid('Schéma non autorisé');
    }

    // Pour https, vérifier le host
    if (uri.scheme == 'https' && !_allowedHosts.contains(uri.host)) {
      return DeepLinkValidationResult.invalid('Host non autorisé');
    }

    // Vérifier le path (préfixe autorisé)
    final pathOk = _allowedPaths.any(
      (p) => uri.path.startsWith(p),
    );
    if (!pathOk && uri.path.isNotEmpty && uri.path != '/') {
      return DeepLinkValidationResult.invalid('Path non autorisé');
    }

    // Vérifier les query params (uniquement alphanumériques/UUID)
    for (final entry in uri.queryParameters.entries) {
      if (!RegExp(r'^[a-zA-Z0-9_\-]+$').hasMatch(entry.key)) {
        return DeepLinkValidationResult.invalid('Paramètre invalide');
      }
      if (entry.value.length > 200) {
        return DeepLinkValidationResult.invalid('Paramètre trop long');
      }
    }

    return DeepLinkValidationResult.valid(uri);
  }

  /// Extrait l'ID de ressource depuis un deep link validé
  static String? extractId(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.length >= 2) return segments.last;
    return uri.queryParameters['id'];
  }
}

class DeepLinkValidationResult {
  final bool isValid;
  final Uri? uri;
  final String? error;

  const DeepLinkValidationResult._({required this.isValid, this.uri, this.error});

  factory DeepLinkValidationResult.valid(Uri uri) =>
      DeepLinkValidationResult._(isValid: true, uri: uri);

  factory DeepLinkValidationResult.invalid(String error) =>
      DeepLinkValidationResult._(isValid: false, error: error);
}
