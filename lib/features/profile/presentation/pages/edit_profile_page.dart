import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/design/design_tokens.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/datasources/auth_remote_datasource.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  bool _saving = false;
  String? _localAvatarPath;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authControllerProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _currentAvatarUrl = user?.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() => _localAvatarPath = picked.path);
    }
  }

  Future<String?> _uploadAvatar(String userId) async {
    if (_localAvatarPath == null) return null;
    try {
      final file = File(_localAvatarPath!);
      final ext = _localAvatarPath!.split('.').last.toLowerCase();
      final path = 'avatars/$userId/avatar.$ext';
      final bytes = await file.readAsBytes();
      await SupabaseService.client.storage.from('media').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
      );
      return SupabaseService.client.storage.from('media').getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final authState = ref.read(authControllerProvider);
    if (authState is! AuthAuthenticated) return;

    setState(() => _saving = true);
    try {
      // internalUserId = users.id — la vraie FK de profiles.user_id
      final internalId = SupabaseService.internalUserId;
      if (internalId == null) {
        setState(() => _saving = false);
        return;
      }
      // Upload avatar si nouveau choix
      final avatarUrl = _localAvatarPath != null
          ? await _uploadAvatar(internalId)
          : null;

      await AuthRemoteDatasource().updateProfile(
        userId: internalId,
        displayName: _nameController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        avatarUrl: avatarUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour ✓')),
        );
        context.pop();
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.message}'),
            backgroundColor: GColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: GColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GColors.void_,
      appBar: AppBar(
        backgroundColor: GColors.void_,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: GColors.textPrimary, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text('Modifier le profil', style: GTextStyle.headlineSmall),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(GColors.orange),
                    ),
                  )
                : Text(
                    'Enregistrer',
                    style: GTextStyle.labelLarge.copyWith(
                      color: GColors.orange,
                    ),
                  ),
          ),
          const SizedBox(width: GSpacing.sm),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: GSpacing.xl, vertical: GSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Avatar ─────────────────────────────────────────────
              GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: GColors.surface,
                      backgroundImage: _localAvatarPath != null
                          ? FileImage(File(_localAvatarPath!))
                          : (_currentAvatarUrl != null
                              ? NetworkImage(_currentAvatarUrl!) as ImageProvider
                              : null),
                      child: (_localAvatarPath == null && _currentAvatarUrl == null)
                          ? const Icon(Icons.person_rounded,
                              color: GColors.textSecondary, size: 40)
                          : null,
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: GColors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: GColors.void_, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: GSpacing.xxl),

              // ── Nom affiché ────────────────────────────────────────
              _FieldLabel(label: 'Nom affiché'),
              const SizedBox(height: GSpacing.xs),
              TextFormField(
                controller: _nameController,
                maxLength: 50,
                style: GTextStyle.bodyLarge,
                decoration: const InputDecoration(
                  hintText: 'Ton nom ou pseudo',
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Le nom ne peut pas être vide';
                  }
                  return null;
                },
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: GSpacing.lg),

              // ── Bio ────────────────────────────────────────────────
              _FieldLabel(label: 'Bio'),
              const SizedBox(height: GSpacing.xs),
              TextFormField(
                controller: _bioController,
                maxLength: 160,
                maxLines: 4,
                minLines: 2,
                style: GTextStyle.bodyLarge,
                decoration: const InputDecoration(
                  hintText: 'Dis quelque chose sur toi…',
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: GSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: GTextStyle.labelMedium.copyWith(
          color: GColors.textSecondary,
        ),
      ),
    );
  }
}
