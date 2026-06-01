import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../../../../core/design/design_tokens.dart';
import '../../data/datasources/feed_remote_datasource.dart';

/// Bottom sheet d'enregistrement d'une réaction vocale (max 30s).
///
/// Usage :
///   showModalBottomSheet(
///     context: context,
///     builder: (_) => VoiceReactionSheet(contentId: '...'),
///   );
class VoiceReactionSheet extends ConsumerStatefulWidget {
  final String contentId;

  const VoiceReactionSheet({super.key, required this.contentId});

  @override
  ConsumerState<VoiceReactionSheet> createState() =>
      _VoiceReactionSheetState();
}

class _VoiceReactionSheetState extends ConsumerState<VoiceReactionSheet> {
  final AudioRecorder _recorder = AudioRecorder();
  final _datasource = FeedRemoteDatasource();

  _Phase _phase = _Phase.idle;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  String? _recordedPath;
  String? _error;

  static const _maxSeconds = 30;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final status = await Permission.microphone.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() => _error = 'Autorise le micro dans les réglages');
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/vr_${widget.contentId}_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 44100,
      ),
      path: path,
    );

    setState(() {
      _phase = _Phase.recording;
      _elapsed = Duration.zero;
      _error = null;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
      if (_elapsed.inSeconds >= _maxSeconds) _stop();
    });
  }

  Future<void> _stop() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    setState(() {
      _phase = _Phase.preview;
      _recordedPath = path;
    });
  }

  Future<void> _send() async {
    if (_recordedPath == null) return;
    setState(() => _phase = _Phase.uploading);

    try {
      await _datasource.submitVoiceReaction(
        contentId: widget.contentId,
        filePath: _recordedPath!,
        durationSeconds: _elapsed.inMilliseconds / 1000.0,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // true = succès
      }
    } catch (e) {
      setState(() {
        _phase = _Phase.preview;
        _error = 'Erreur upload — réessaie';
      });
    } finally {
      // Nettoyer le fichier temporaire
      try {
        if (_recordedPath != null) File(_recordedPath!).deleteSync();
      } catch (_) {}
    }
  }

  void _retry() {
    setState(() {
      _phase = _Phase.idle;
      _recordedPath = null;
      _elapsed = Duration.zero;
      _error = null;
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: GColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(GRadius.xl)),
      ),
      padding: const EdgeInsets.all(GSpacing.xl),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: GColors.border,
                borderRadius: BorderRadius.circular(GRadius.full),
              ),
            ),

            const SizedBox(height: GSpacing.lg),

            Text(
              'Réaction vocale',
              style: GTextStyle.headlineSmall,
            ),

            const SizedBox(height: GSpacing.sm),

            Text(
              'Max 30 secondes',
              style: GTextStyle.bodySmall
                  .copyWith(color: GColors.textSecondary),
            ),

            const SizedBox(height: GSpacing.xl),

            // ── Timer ────────────────────────────────────────────────────
            Text(
              _formatDuration(_elapsed),
              style: GTextStyle.displaySmall.copyWith(
                color: _phase == _Phase.recording
                    ? GColors.error
                    : GColors.textPrimary,
              ),
            ),

            // Barre progression
            const SizedBox(height: GSpacing.sm),
            LinearProgressIndicator(
              value: _elapsed.inSeconds / _maxSeconds,
              backgroundColor: GColors.elevated,
              valueColor: AlwaysStoppedAnimation<Color>(
                _phase == _Phase.recording ? GColors.error : GColors.orange,
              ),
            ),

            const SizedBox(height: GSpacing.xl),

            // ── Erreur ───────────────────────────────────────────────────
            if (_error != null) ...[
              Text(_error!,
                  style: GTextStyle.bodySmall
                      .copyWith(color: GColors.error)),
              const SizedBox(height: GSpacing.md),
            ],

            // ── Boutons ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_phase == _Phase.idle) ...[
                  _BigButton(
                    icon: Icons.mic,
                    label: 'Enregistrer',
                    color: GColors.orange,
                    onTap: _start,
                  ),
                ] else if (_phase == _Phase.recording) ...[
                  _BigButton(
                    icon: Icons.stop,
                    label: 'Arrêter',
                    color: GColors.error,
                    onTap: _stop,
                  ),
                ] else if (_phase == _Phase.preview) ...[
                  _BigButton(
                    icon: Icons.refresh,
                    label: 'Recommencer',
                    color: GColors.textSecondary,
                    onTap: _retry,
                  ),
                  const SizedBox(width: GSpacing.xl),
                  _BigButton(
                    icon: Icons.send,
                    label: 'Envoyer',
                    color: GColors.orange,
                    onTap: _send,
                  ),
                ] else if (_phase == _Phase.uploading) ...[
                  const CircularProgressIndicator(color: GColors.orange),
                ],
              ],
            ),

            const SizedBox(height: GSpacing.md),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.2, duration: 300.ms);
  }
}

enum _Phase { idle, recording, preview, uploading }

class _BigButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BigButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: GSpacing.sm),
          Text(label,
              style: GTextStyle.bodySmall.copyWith(color: color)),
        ],
      ),
    );
  }
}
