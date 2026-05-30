import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';

class BiometricService {
  static final _auth = LocalAuthentication();

  // Vérifier si la biométrie est disponible
  static Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  // Types disponibles (Face ID, Touch ID, etc.)
  static Future<List<BiometricType>> getAvailableTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  // Authentifier (ré-ouverture de l'app)
  static Future<BiometricResult> authenticate({
    String reason = 'Confirme ton identité pour accéder à Gbairai',
  }) async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          sensitiveTransaction: false,
          biometricOnly: false, // Fallback PIN/passcode autorisé
          useErrorDialogs: true,
        ),
      );
      return authenticated
          ? BiometricResult.success
          : BiometricResult.failed;
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable ||
          e.code == auth_error.notEnrolled) {
        return BiometricResult.unavailable;
      }
      if (e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        return BiometricResult.lockedOut;
      }
      return BiometricResult.error;
    }
  }

  // Activer/désactiver la biométrie pour l'app
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.biometricEnabled, enabled);
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKeys.biometricEnabled) ?? false;
  }
}

enum BiometricResult { success, failed, unavailable, lockedOut, error }
