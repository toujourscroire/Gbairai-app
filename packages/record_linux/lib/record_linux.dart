// ignore_for_file: avoid_returning_null_for_void

import 'dart:typed_data';
import 'package:record_platform_interface/record_platform_interface.dart';

/// Stub implementation of [RecordPlatform] for Linux.
///
/// record_linux 0.7.2 on pub.dev was never updated to implement
/// record_platform_interface >= 1.5.0. This local stub provides compilable
/// no-op implementations of ALL abstract members so the Dart kernel snapshot
/// compiles on iOS/macOS/Android builds where record_linux is resolved as a
/// transitive dependency but never instantiated at runtime.
///
/// On iOS, [RecordPlatform.instance] is set to the record_darwin implementation,
/// NOT this class. Calling any of these methods at runtime would indicate a
/// platform registration bug.
class RecordLinux extends RecordPlatform {
  static void registerWith() {
    // No-op: on Linux this would register the implementation.
    // On iOS this is never called.
  }

  // ── RecordEventChannelPlatformInterface ──────────────────────────────────

  @override
  Stream<RecordState> onStateChanged(String recorderId) {
    throw UnsupportedError('RecordLinux stub: not available on this platform');
  }

  // ── RecordMethodChannelPlatformInterface ─────────────────────────────────

  @override
  Future<void> cancel(String recorderId) async {
    throw UnsupportedError('RecordLinux stub: not available on this platform');
  }

  @override
  Future<void> create(String recorderId) async {
    throw UnsupportedError('RecordLinux stub: not available on this platform');
  }

  @override
  Future<void> dispose(String recorderId) async {
    throw UnsupportedError('RecordLinux stub: not available on this platform');
  }

  @override
  Future<bool> hasPermission(String recorderId, {bool request = true}) async {
    throw UnsupportedError('RecordLinux stub: not available on this platform');
  }

  @override
  Future<bool> isPaused(String recorderId) async {
    throw UnsupportedError('RecordLinux stub: not available on this platform');
  }

  @override
  Future<bool> isRecording(String recorderId) async {
    throw UnsupportedError('RecordLinux stub: not available on this platform');
  }

  @override
  Future<void> pause(String recorderId) async {
    throw UnsupportedError('RecordLinux stub: not available on this platform');
  }

  @override
  Future<void> resume(String recorderId) async {
    throw UnsupportedError('RecordLinux stub: not available on this platform');
  }

  @override
  Future<void> start(
    String recorderId,
    RecordConfig config, {
    required String path,
  }) async {
    throw UnsupportedError('RecordLinux stub: not available on this platform');
  }

  @override
  Future<Stream<Uint8List>> startStream(
    String recorderId,
    RecordConfig config,
  ) async {
    throw UnsupportedError('RecordLinux stub: not available on this platform');
  }

  @override
  Future<String?> stop(String recorderId) async {
    throw UnsupportedError('RecordLinux stub: not available on this platform');
  }

  @override
  Future<Amplitude> getAmplitude(String recorderId) async {
    throw UnsupportedError('RecordLinux stub: not available on this platform');
  }

  @override
  Future<bool> isEncoderSupported(
    String recorderId,
    AudioEncoder encoder,
  ) async {
    throw UnsupportedError('RecordLinux stub: not available on this platform');
  }

  @override
  Future<List<InputDevice>> listInputDevices(String recorderId) async {
    throw UnsupportedError('RecordLinux stub: not available on this platform');
  }
}
