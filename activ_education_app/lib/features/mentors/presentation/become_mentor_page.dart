import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/constants/constants.dart';
import '../../../core/di/injection_container.dart';
import '../../../shared/widgets/buttons/gradient_button.dart';
import '../../../shared/widgets/feedback/app_snackbar.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';

/// Formulaire de candidature pour devenir mentor.
///
/// Envoie la candidature a POST /mentors/apply. Pre-rempli avec le profil
/// connecte si disponible. Aucune authentification requise (auth optionnelle).
class BecomeMentorPage extends StatefulWidget {
  const BecomeMentorPage({super.key});

  @override
  State<BecomeMentorPage> createState() => _BecomeMentorPageState();
}

class _BecomeMentorPageState extends State<BecomeMentorPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _specialty = TextEditingController();
  final _experience = TextEditingController();
  final _bio = TextEditingController();
  final _linkedin = TextEditingController();
  final _motivation = TextEditingController();

  bool _submitting = false;

  // Photo de profil : octets choisis (pour l'apercu) et URL renvoyee par
  // POST /mentors/apply/photo une fois le fichier depose.
  Uint8List? _photoBytes;
  String? _photoUrl;
  bool _uploadingPhoto = false;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    // Pre-remplir depuis le profil connecte
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      final u = state.user;
      final name = [u.firstName, u.lastName]
          .where((e) => e != null && e.isNotEmpty)
          .join(' ');
      _fullName.text = name.isNotEmpty ? name : (u.displayName ?? '');
      _email.text = u.email;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _fullName, _email, _phone, _specialty,
      _experience, _bio, _linkedin, _motivation,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Choisit une image et la depose immediatement.
  ///
  /// L'envoi est fait des la selection plutot qu'a la soumission : le
  /// candidat voit tout de suite si le fichier est refuse (format, taille),
  /// au lieu de perdre son formulaire sur une erreur finale.
  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true, // indispensable sur le web : pas de chemin de fichier
    );
    final file = result?.files.firstOrNull;
    if (file == null || file.bytes == null) return;

    setState(() {
      _photoBytes = file.bytes;
      _uploadingPhoto = true;
    });

    try {
      final dio = getIt<Dio>(instanceName: 'apiClient');
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      });
      final res = await dio.post(ApiEndpoints.mentorApplyPhoto, data: form);
      if (mounted) setState(() => _photoUrl = res.data['url'] as String?);
    } catch (e) {
      if (mounted) {
        setState(() {
          _photoBytes = null;
          _photoUrl = null;
        });
        AppSnackbar.error(
          context,
          "Photo refusée. Formats acceptés : JPG, PNG ou WEBP, 5 Mo maximum.",
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final dio = getIt<Dio>(instanceName: 'apiClient');
      await dio.post(ApiEndpoints.mentorApply, data: {
        'full_name': _fullName.text.trim(),
        'email': _email.text.trim(),
        if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
        'specialty': _specialty.text.trim(),
        if (_experience.text.trim().isNotEmpty)
          'years_experience': int.tryParse(_experience.text.trim()),
        if (_bio.text.trim().isNotEmpty) 'bio': _bio.text.trim(),
        if (_linkedin.text.trim().isNotEmpty) 'linkedin_url': _linkedin.text.trim(),
        if (_motivation.text.trim().isNotEmpty) 'motivation': _motivation.text.trim(),
        if (_photoUrl != null) 'photo_url': _photoUrl,
      });
      if (mounted) setState(() => _success = true);
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
          context,
          "Impossible d'envoyer votre candidature. Réessayez plus tard.",
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Devenir mentor', style: AppTypography.titleMedium),
      ),
      body: _success ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  size: 44, color: AppColors.success),
            ),
            const SizedBox(height: 20),
            Text('Candidature envoyée !',
                style: AppTypography.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              'Merci ! Notre équipe examinera votre candidature et reviendra '
              'vers vous par email.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GradientButton(
              text: 'Retour',
              showArrow: false,
              width: 180,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Iconsax.teacher, color: Colors.white, size: 30),
                  const SizedBox(height: 12),
                  Text('Partagez votre expérience',
                      style: AppTypography.heroTitle.copyWith(fontSize: 20)),
                  const SizedBox(height: 6),
                  Text(
                    'Accompagnez des jeunes dans leur orientation. '
                    'Remplissez le formulaire pour rejoindre nos mentors.',
                    style: AppTypography.heroSubtitle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildPhotoPicker(),
            const SizedBox(height: 4),
            _field(_fullName, 'Nom complet *', Iconsax.user, required: true),
            _field(_email, 'Email *', Iconsax.sms,
                required: true, keyboard: TextInputType.emailAddress),
            _field(_phone, 'Téléphone', Iconsax.call,
                keyboard: TextInputType.phone),
            _field(_specialty, 'Spécialité * (ex: Ingénierie, Droit...)',
                Iconsax.briefcase, required: true),
            _field(_experience, "Années d'expérience", Iconsax.calendar,
                keyboard: TextInputType.number),
            _field(_linkedin, 'Profil LinkedIn (URL)', Iconsax.link),
            _field(_bio, 'Bio (présentez-vous)', Iconsax.document_text,
                maxLines: 4),
            _field(_motivation, 'Pourquoi devenir mentor ?', Iconsax.heart,
                maxLines: 4),

            const SizedBox(height: 24),
            GradientButton(
              text: _submitting ? 'Envoi...' : 'Envoyer ma candidature',
              icon: Iconsax.send_1,
              showArrow: false,
              onPressed: _submitting ? null : _submit,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: _uploadingPhoto ? null : _pickPhoto,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _photoUrl != null
                      ? AppColors.success
                      : AppColors.border,
                  width: 2,
                ),
                image: _photoBytes != null
                    ? DecorationImage(
                        image: MemoryImage(_photoBytes!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _uploadingPhoto
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _photoBytes == null
                      ? const Icon(Iconsax.camera,
                          color: AppColors.textTertiary, size: 26)
                      : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Photo de profil',
                    style: AppTypography.titleSmall),
                const SizedBox(height: 2),
                Text(
                  _photoUrl != null
                      ? 'Photo ajoutée. Touchez pour la remplacer.'
                      : 'Facultatif — JPG, PNG ou WEBP, 5 Mo maximum.',
                  style: AppTypography.bodySmall.copyWith(
                    color: _photoUrl != null
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        keyboardType: keyboard,
        style: AppTypography.bodyMedium,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
            borderSide: BorderSide(color: AppColors.border),
          ),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null
            : null,
      ),
    );
  }
}
