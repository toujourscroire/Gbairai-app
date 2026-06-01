import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../../../../core/design/design_tokens.dart';
import '../providers/creation_provider.dart';

const _cities = [
  'Abidjan', 'Yamoussoukro', 'Bouaké', 'Daloa',
  'Korhogo', 'San-Pédro', 'Man', 'Gagnoa',
];

const _coverColors = [
  ('orange',   Color(0xFFE85D04)),
  ('violet',   Color(0xFF7C3AED)),
  ('teal',     Color(0xFF0891B2)),
  ('green',    Color(0xFF059669)),
  ('red',      Color(0xFFDC2626)),
  ('gold',     Color(0xFFF5A623)),
];

class CreateVoicePage extends ConsumerStatefulWidget {
  const CreateVoicePage({super.key});

  @override
  ConsumerState<CreateVoicePage> createState() => _CreateVoicePageState();
}

class _CreateVoicePageState extends ConsumerState<CreateVoicePage> {
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  bool _hasRecording = false;
  String? _recordedPath;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  final _titleController = TextEditingController();
  String _selectedCity = 'Abidjan';
  String _selectedColor = 'orange';
  bool _isAnonymous = false;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<bool> _requestMicPermission() async {
    final status = await Permission.microphone.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Autorise le micro dans les réglages'),
            backgroundColor: GColors.error,
          ),
        );
      }
      return false;
    }
    return true;
  }

  Future<void> _startRecording() async {
    if (!await _requestMicPermission()) return;

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/gbairai_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    setState(() {
      _isRecording = true;
      _elapsed = Duration.zero;
      _recordedPath = null;
      _hasRecording = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
      // Max 2 minutes
      if (_elapsed.inSeconds >= 120) _stopRecording();
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _recordedPath = path;
      _hasRecording = path != null;
    });
  }

  Future<void> _publish() async {
    if (_recordedPath == null) return;
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Donne un titre à ton vocal'),
          backgroundColor: GColors.error,
        ),
      );
      return;
    }

    await ref.read(creationProvider.notifier).publishVoice(
          filePath: _recordedPath!,
          voiceTitle: _titleController.text.trim(),
          voiceCoverBg: _selectedColor,
          isAnonymous: _isAnonymous,
          city: _selectedCity,
          durationSeconds: _elapsed.inMilliseconds / 1000.0,
        );

    final state = ref.read(creationProvider);
    if (!mounted) return;

    if (state is PublicationSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vocal en cours de validation'),
          backgroundColor: GColors.orange,
        ),
      );
      context.go('/feed');
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color get _coverColor =>
      _coverColors.firstWhere((c) => c.$1 == _selectedColor).$2;

  @override
  Widget build(BuildContext context) {
    final pubState = ref.watch(creationProvider);
    final isLoading = pubState is PublicationLoading;
    final uploadProgress = isLoading ? (pubState).progress : 0.0;

    ref.listen<PublicationState>(creationProvider, (_, next) {
      if (next is PublicationError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: GColors.error,
          ),
        );
        ref.read(creationProvider.notifier).reset();
      }
    });

    return Scaffold(
      backgroundColor: GColors.void_,
      appBar: AppBar(
        backgroundColor: GColors.void_,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: isLoading ? null : () => context.pop(),
        ),
        title: const Text('Vocal'),
        actions: [
          if (_hasRecording)
            Padding(
              padding: const EdgeInsets.only(right: GSpacing.md),
              child: TextButton(
                onPressed: isLoading ? null : _publish,
                style: TextButton.styleFrom(
                  backgroundColor: GColors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: GSpacing.lg, vertical: GSpacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GRadius.full),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Publier'),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(GSpacing.xl),
        child: Column(
          children: [
            // ── Cover preview ────────────────────────────────────────────
            AnimatedContainer(
              duration: 300.ms,
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: _coverColor,
                borderRadius: BorderRadius.circular(GRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: _coverColor.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isRecording ? Icons.graphic_eq : Icons.mic,
                    color: Colors.white,
                    size: 60,
                  )
                      .animate(
                          onPlay: (c) => c.repeat(),
                          target: _isRecording ? 1.0 : 0.0)
                      .scaleXY(
                          begin: 1.0,
                          end: 1.2,
                          duration: 600.ms,
                          curve: Curves.easeInOut),
                  const SizedBox(height: GSpacing.sm),
                  Text(
                    _formatDuration(_elapsed),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_hasRecording)
                    const Text('Enregistrement terminé',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),

            const SizedBox(height: GSpacing.xl),

            // ── Bouton enregistrement ────────────────────────────────────
            if (!_hasRecording) ...[
              GestureDetector(
                onTap: isLoading
                    ? null
                    : (_isRecording ? _stopRecording : _startRecording),
                child: AnimatedContainer(
                  duration: 200.ms,
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isRecording ? GColors.error : GColors.orange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording ? GColors.error : GColors.orange)
                            .withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: GSpacing.sm),
              Text(
                _isRecording
                    ? 'Appuie pour arrêter'
                    : 'Appuie pour enregistrer',
                style: const TextStyle(color: GColors.textSecondary),
              ),
            ] else ...[
              // Recommencer
              TextButton.icon(
                onPressed: isLoading
                    ? null
                    : () {
                        if (_recordedPath != null) {
                          try {
                            File(_recordedPath!).deleteSync();
                          } catch (_) {}
                        }
                        setState(() {
                          _hasRecording = false;
                          _recordedPath = null;
                          _elapsed = Duration.zero;
                        });
                      },
                icon: const Icon(Icons.refresh, color: GColors.textSecondary),
                label: const Text('Recommencer',
                    style: TextStyle(color: GColors.textSecondary)),
              ),
            ],

            const SizedBox(height: GSpacing.xl),

            // ── Upload progress ──────────────────────────────────────────
            if (isLoading)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: GSpacing.sm),
                child: LinearProgressIndicator(
                  value: uploadProgress,
                  backgroundColor: GColors.elevated,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(GColors.orange),
                ),
              ).animate().fadeIn(),

            // ── Titre ────────────────────────────────────────────────────
            TextField(
              controller: _titleController,
              maxLength: 80,
              style: const TextStyle(color: GColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Titre du vocal…',
                hintStyle: const TextStyle(color: GColors.textTertiary),
                filled: true,
                fillColor: GColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(GRadius.md),
                  borderSide: const BorderSide(color: GColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(GRadius.md),
                  borderSide: const BorderSide(color: GColors.border),
                ),
              ),
            ),

            const SizedBox(height: GSpacing.md),

            // ── Couleur cover ────────────────────────────────────────────
            Row(
              children: _coverColors
                  .map((c) => GestureDetector(
                        onTap: () =>
                            setState(() => _selectedColor = c.$1),
                        child: AnimatedContainer(
                          duration: 150.ms,
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(right: GSpacing.sm),
                          decoration: BoxDecoration(
                            color: c.$2,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedColor == c.$1
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),

            const SizedBox(height: GSpacing.md),

            // ── Ville + Anonyme ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCity,
                    dropdownColor: GColors.elevated,
                    style: const TextStyle(color: GColors.textPrimary),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.location_on_outlined,
                          color: GColors.textSecondary, size: 18),
                      filled: true,
                      fillColor: GColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(GRadius.md),
                        borderSide: const BorderSide(color: GColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(GRadius.md),
                        borderSide: const BorderSide(color: GColors.border),
                      ),
                    ),
                    items: _cities
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedCity = v ?? _selectedCity),
                  ),
                ),
                const SizedBox(width: GSpacing.md),
                Row(
                  children: [
                    const Text('Anonyme',
                        style: TextStyle(color: GColors.textSecondary)),
                    Switch.adaptive(
                      value: _isAnonymous,
                      onChanged: (v) => setState(() => _isAnonymous = v),
                      activeColor: GColors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
