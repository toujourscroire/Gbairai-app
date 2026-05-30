import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Secure Storage centralisé avec config iOS Keychain
// OWASP M2 — Insecure Data Storage mitigation
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      // Pas de synchronisation iCloud — données strictement locales
      synchronizable: false,
    ),
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // ── Écriture sécurisée ────────────────────────────────────────────
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  // ── Lecture sécurisée ─────────────────────────────────────────────
  Future<String?> read({required String key}) async {
    return _storage.read(key: key);
  }

  // ── Suppression ───────────────────────────────────────────────────
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  // ── Purge complète (déconnexion / suppression compte) ─────────────
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  // ── Vérification existence ────────────────────────────────────────
  Future<bool> containsKey({required String key}) async {
    return _storage.containsKey(key: key);
  }
}
