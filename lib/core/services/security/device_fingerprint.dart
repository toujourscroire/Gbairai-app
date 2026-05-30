// Device Fingerprinting pour détection multi-comptes et fraud prevention
// OWASP M1 — Improper Platform Usage mitigation

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';

class DeviceFingerprintService {
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
    ),
  );
  static const _fpKey = 'gbairai_device_fp';

  // Générer ou récupérer le fingerprint de l'appareil
  static Future<String> getOrCreate() async {
    // Vérifier si déjà généré
    final existing = await _storage.read(key: _fpKey);
    if (existing != null && existing.isNotEmpty) return existing;

    // Générer un nouveau fingerprint
    final fp = await _generate();
    await _storage.write(key: _fpKey, value: fp);
    return fp;
  }

  static Future<String> _generate() async {
    final plugin = DeviceInfoPlugin();
    final components = <String>[];

    if (Platform.isIOS) {
      final info = await plugin.iosInfo;
      components.addAll([
        info.identifierForVendor ?? '',
        info.model,
        info.systemVersion,
        info.utsname.machine,
      ]);
    } else if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      components.addAll([
        info.id,
        info.model,
        info.brand,
        info.version.sdkInt.toString(),
      ]);
    }

    final raw = components.join('|');
    final bytes = utf8.encode(raw);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Invalider le fingerprint (si l'utilisateur réinitialise l'app)
  static Future<void> invalidate() async {
    await _storage.delete(key: _fpKey);
  }
}
