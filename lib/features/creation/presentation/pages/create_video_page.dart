import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/design/design_tokens.dart';
import '../providers/creation_provider.dart';

const _cities = [
  'Abidjan', 'Yamoussoukro', 'Bouaké', 'Daloa',
  'Korhogo', 'San-Pédro', 'Man', 'Gagnoa',
];

class CreateVideoPage extends ConsumerStatefulWidget {
  const CreateVideoPage({super.key});

  @override
  ConsumerState<CreateVideoPage> createState() => _CreateVideoPageState();
}

class _CreateVideoPageState extends ConsumerState<CreateVideoPage> {
  XFile? _videoFile;
  VideoPlayerController? _previewController;
  bool _previewInitialized = false;

  final _captionController = TextEditingController();
  String _selectedCity = 'Abidjan';
  bool _isAnonymous = false;

  @override
  void dispose() {
    _previewController?.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 3),
    );
    if (file == null) return;

    await _previewController?.dispose();
    _previewController = null;
    setState(() {
      _videoFile = file;
      _previewInitialized = false;
    });

    final ctrl = VideoPlayerController.file(File(file.path));
    await ctrl.initialize();
    if (mounted) {
      setState(() {
        _previewController = ctrl;
        _previewInitialized = true;
      });
      ctrl.setLooping(true);
      ctrl.play();
    }
  }

  Future<void> _publish() async {
    if (_videoFile == null) return;

    await ref.read(creationProvider.notifier).publishVideo(
          filePath: _videoFile!.path,
          caption: _captionController.text.trim().isEmpty
              ? null
              : _captionController.text.trim(),
          isAnonymous: _isAnonymous,
          city: _selectedCity,
        );

    final state = ref.read(creationProvider);
    if (!mounted) return;

    if (state is PublicationSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vidéo en cours de validation'),
          backgroundColor: GColors.orange,
        ),
      );
      context.go('/feed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pubState = ref.watch(creationProvider);
    final isLoading = pubState is PublicationLoading;
    final progress = isLoading ? (pubState).progress : 0.0;

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
        title: const Text('Vidéo'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: GSpacing.md),
            child: TextButton(
              onPressed: isLoading || _videoFile == null ? null : _publish,
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
        child: Column(
          children: [
            // ── Zone vidéo ───────────────────────────────────────────────
            GestureDetector(
              onTap: isLoading ? null : _pickVideo,
              child: Container(
                height: 400,
                width: double.infinity,
                color: GColors.surface,
                child: _previewInitialized && _previewController != null
                    ? Stack(
                        children: [
                          Center(
                            child: AspectRatio(
                              aspectRatio:
                                  _previewController!.value.aspectRatio,
                              child: VideoPlayer(_previewController!),
                            ),
                          ),
                          // Overlay play/pause
                          Positioned.fill(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _previewController!.value.isPlaying
                                      ? _previewController!.pause()
                                      : _previewController!.play();
                                });
                              },
                              child: Container(color: Colors.transparent),
                            ),
                          ),
                          // Icône changer vidéo
                          Positioned(
                            top: GSpacing.md,
                            right: GSpacing.md,
                            child: GestureDetector(
                              onTap: isLoading ? null : _pickVideo,
                              child: Container(
                                padding: const EdgeInsets.all(GSpacing.sm),
                                decoration: BoxDecoration(
                                  color: GColors.glassBg,
                                  borderRadius: BorderRadius.circular(GRadius.full),
                                ),
                                child: const Icon(Icons.edit,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: GColors.elevated,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.video_call_outlined,
                                color: GColors.orange, size: 40),
                          ),
                          const SizedBox(height: GSpacing.lg),
                          const Text(
                            'Appuie pour choisir une vidéo',
                            style: TextStyle(
                                color: GColors.textSecondary, fontSize: 16),
                          ),
                          const SizedBox(height: GSpacing.sm),
                          Text(
                            'Max 3 minutes · MP4, MOV',
                            style: TextStyle(
                                color: GColors.textTertiary, fontSize: 12),
                          ),
                        ],
                      ).animate().fadeIn(),
              ),
            ),

            // ── Barre de progression upload ──────────────────────────────
            if (isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: GSpacing.md),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: GColors.elevated,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(GColors.orange),
                ),
              ).animate().fadeIn(),

            // ── Formulaire ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(GSpacing.md),
              child: Column(
                children: [
                  TextField(
                    controller: _captionController,
                    maxLength: 150,
                    style: const TextStyle(color: GColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Description (optionnel)…',
                      hintStyle:
                          const TextStyle(color: GColors.textTertiary),
                      filled: true,
                      fillColor: GColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(GRadius.md),
                        borderSide:
                            const BorderSide(color: GColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(GRadius.md),
                        borderSide:
                            const BorderSide(color: GColors.border),
                      ),
                    ),
                  ),

                  const SizedBox(height: GSpacing.md),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCity,
                          dropdownColor: GColors.elevated,
                          style: const TextStyle(color: GColors.textPrimary),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                                Icons.location_on_outlined,
                                color: GColors.textSecondary,
                                size: 18),
                            filled: true,
                            fillColor: GColors.surface,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(GRadius.md),
                              borderSide:
                                  const BorderSide(color: GColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(GRadius.md),
                              borderSide:
                                  const BorderSide(color: GColors.border),
                            ),
                          ),
                          items: _cities
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(
                              () => _selectedCity = v ?? _selectedCity),
                        ),
                      ),
                      const SizedBox(width: GSpacing.md),
                      Row(
                        children: [
                          const Text('Anonyme',
                              style:
                                  TextStyle(color: GColors.textSecondary)),
                          Switch.adaptive(
                            value: _isAnonymous,
                            onChanged: (v) =>
                                setState(() => _isAnonymous = v),
                            activeColor: GColors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
