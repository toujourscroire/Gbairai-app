// OWASP M7 — Client Code Quality / Injection mitigation
// Validation stricte de toutes les entrées utilisateur

abstract final class InputValidator {
  // ── Téléphone CI (+225 XX XX XX XX XX) ───────────────────────────
  static String? validateCiPhone(String? value) {
    if (value == null || value.isEmpty) return 'Numéro requis';
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    // Format CI : +225 suivi de 10 chiffres
    final phoneRegex = RegExp(r'^\+225[0-9]{10}$');
    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Numéro CI invalide (ex: +225 07 00 00 00 00)';
    }
    return null;
  }

  // ── Email ────────────────────────────────────────────────────────
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email requis';
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) return 'Email invalide';
    if (value.length > 254) return 'Email trop long';
    return null;
  }

  // ── Mot de passe ─────────────────────────────────────────────────
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Mot de passe requis';
    if (value.length < 8) return 'Minimum 8 caractères';
    if (value.length > 128) return 'Mot de passe trop long';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Une majuscule requise';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Un chiffre requis';
    return null;
  }

  // ── OTP ──────────────────────────────────────────────────────────
  static String? validateOtp(String? value) {
    if (value == null || value.isEmpty) return 'Code requis';
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return 'Code invalide';
    return null;
  }

  // ── Pseudo ───────────────────────────────────────────────────────
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) return 'Pseudo requis';
    if (value.length < 3) return 'Minimum 3 caractères';
    if (value.length > 30) return 'Maximum 30 caractères';
    // Alphanumérique + underscore + tiret uniquement
    if (!RegExp(r'^[a-zA-Z0-9_\-]+$').hasMatch(value)) {
      return 'Uniquement lettres, chiffres, _ et -';
    }
    // Protection XSS — pas de caractères spéciaux HTML
    if (RegExp(r'[<>&"\'\/]').hasMatch(value)) {
      return 'Caractères non autorisés';
    }
    return null;
  }

  // ── Caption / Statut ─────────────────────────────────────────────
  static String? validateCaption(String? value, {int maxLength = 280}) {
    if (value == null || value.isEmpty) return null; // Optionnel
    if (value.length > maxLength) return 'Maximum $maxLength caractères';
    return null;
  }

  // ── Commentaire ──────────────────────────────────────────────────
  static String? validateComment(String? value) {
    if (value == null || value.trim().isEmpty) return 'Commentaire vide';
    if (value.length > 300) return 'Maximum 300 caractères';
    return null;
  }

  // ── Bio ───────────────────────────────────────────────────────────
  static String? validateBio(String? value) {
    if (value == null || value.isEmpty) return null; // Optionnel
    if (value.length > 150) return 'Maximum 150 caractères';
    return null;
  }

  // ── Sanitisation XSS (pour affichage HTML indirect) ───────────────
  static String sanitizeText(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }

  // ── Validation hashtag ────────────────────────────────────────────
  static String? validateHashtag(String? value) {
    if (value == null || value.isEmpty) return 'Hashtag vide';
    final tag = value.startsWith('#') ? value.substring(1) : value;
    if (tag.length < 2) return 'Trop court';
    if (tag.length > 50) return 'Maximum 50 caractères';
    if (!RegExp(r'^[a-zA-Z0-9_À-ſ]+$').hasMatch(tag)) {
      return 'Caractères non autorisés dans le hashtag';
    }
    return null;
  }

  // ── URL sécurisée (deep links) ────────────────────────────────────
  static bool isValidDeepLink(String url) {
    try {
      final uri = Uri.parse(url);
      // Uniquement les schémas autorisés
      return uri.scheme == 'gbairai' ||
          (uri.scheme == 'https' && uri.host.endsWith('gbairai.ci'));
    } catch (_) {
      return false;
    }
  }

  // ── Validation UUID ───────────────────────────────────────────────
  static bool isValidUuid(String? value) {
    if (value == null || value.isEmpty) return false;
    return RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(value);
  }
}
