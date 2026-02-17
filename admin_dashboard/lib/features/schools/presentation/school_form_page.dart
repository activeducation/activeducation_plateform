import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/admin_constants.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/feedback/admin_snackbar.dart';
import '../../../shared/widgets/dialogs/confirm_dialog.dart';

class SchoolFormPage extends StatefulWidget {
  final String? schoolId;
  const SchoolFormPage({super.key, this.schoolId});

  @override
  State<SchoolFormPage> createState() => _SchoolFormPageState();
}

class _SchoolFormPageState extends State<SchoolFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Informations de base
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'university';
  bool _isPublic = true;
  bool _isActive = true;

  // Champs enrichis
  final _tuitionRangeCtrl = TextEditingController();
  final _admissionReqCtrl = TextEditingController();
  final _foundingYearCtrl = TextEditingController();
  final _studentCountCtrl = TextEditingController();
  List<String> _accreditations = [];
  List<String> _programsOffered = [];

  // Images
  String? _logoUrl;
  String? _coverImageUrl;
  bool _isUploadingLogo = false;
  bool _isUploadingCover = false;

  // Programmes (filieres)
  List<Map<String, dynamic>> _programs = [];

  // Etat
  bool _isLoading = false;
  bool _isSaving = false;
  bool get _isEditing => widget.schoolId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadSchool();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _descCtrl.dispose();
    _tuitionRangeCtrl.dispose();
    _admissionReqCtrl.dispose();
    _foundingYearCtrl.dispose();
    _studentCountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSchool() async {
    setState(() => _isLoading = true);
    try {
      final api = getIt<ApiClient>();
      final response = await api.get(ApiEndpoints.adminSchoolById(widget.schoolId!));
      final data = response.data as Map<String, dynamic>;

      _nameCtrl.text = data['name'] ?? '';
      _cityCtrl.text = data['city'] ?? '';
      _addressCtrl.text = data['address'] ?? '';
      _phoneCtrl.text = data['phone'] ?? '';
      _emailCtrl.text = data['email'] ?? '';
      _websiteCtrl.text = data['website'] ?? '';
      _descCtrl.text = data['description'] ?? '';
      _tuitionRangeCtrl.text = data['tuition_range'] ?? '';
      _admissionReqCtrl.text = data['admission_requirements'] ?? '';
      _foundingYearCtrl.text = data['founding_year']?.toString() ?? '';
      _studentCountCtrl.text = data['student_count']?.toString() ?? '';

      _type = data['type'] ?? 'university';
      _isPublic = data['is_public'] ?? true;
      _isActive = data['is_active'] ?? true;
      _logoUrl = data['logo_url'];
      _coverImageUrl = data['cover_image_url'];
      _accreditations = List<String>.from(data['accreditations'] ?? []);
      _programsOffered = List<String>.from(data['programs_offered'] ?? []);
      _programs = List<Map<String, dynamic>>.from(data['programs'] ?? []);
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur de chargement');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'type': _type,
      'city': _cityCtrl.text.trim(),
      'address': _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      'website': _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
      'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'is_public': _isPublic,
      'logo_url': _logoUrl,
      'cover_image_url': _coverImageUrl,
      'tuition_range': _tuitionRangeCtrl.text.trim().isEmpty ? null : _tuitionRangeCtrl.text.trim(),
      'admission_requirements': _admissionReqCtrl.text.trim().isEmpty ? null : _admissionReqCtrl.text.trim(),
      'accreditations': _accreditations,
      'programs_offered': _programsOffered,
      'founding_year': _foundingYearCtrl.text.trim().isEmpty ? null : int.tryParse(_foundingYearCtrl.text.trim()),
      'student_count': _studentCountCtrl.text.trim().isEmpty ? null : int.tryParse(_studentCountCtrl.text.trim()),
    };

    if (_isEditing) {
      data['is_active'] = _isActive;
    }

    try {
      final api = getIt<ApiClient>();
      if (_isEditing) {
        await api.put(ApiEndpoints.adminSchoolById(widget.schoolId!), data: data);
      } else {
        await api.post(ApiEndpoints.adminSchools, data: data);
      }
      if (mounted) {
        AdminSnackbar.success(context, _isEditing ? 'Ecole modifiee' : 'Ecole creee');
        context.go('/schools');
      }
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur de sauvegarde: $e');
    }
    setState(() => _isSaving = false);
  }

  // =========================================================================
  // IMAGE UPLOAD
  // =========================================================================

  Future<void> _uploadImage({required bool isLogo}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() {
      if (isLogo) _isUploadingLogo = true;
      else _isUploadingCover = true;
    });

    try {
      final api = getIt<ApiClient>();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
          contentType: DioMediaType.parse(
            file.extension == 'png' ? 'image/png'
            : file.extension == 'webp' ? 'image/webp'
            : 'image/jpeg',
          ),
        ),
      });

      final response = await api.dio.post(
        ApiEndpoints.adminUpload('schools'),
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final url = (response.data as Map<String, dynamic>)['url'] as String;
      setState(() {
        if (isLogo) _logoUrl = url;
        else _coverImageUrl = url;
      });
      if (mounted) AdminSnackbar.success(context, 'Image uploadee');
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur d\'upload: $e');
    }

    setState(() {
      if (isLogo) _isUploadingLogo = false;
      else _isUploadingCover = false;
    });
  }

  // =========================================================================
  // TAGS MANAGEMENT (accreditations, programs_offered)
  // =========================================================================

  Future<void> _addTag({required bool isAccreditation}) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAccreditation ? 'Ajouter une accreditation' : 'Ajouter un domaine de formation'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: isAccreditation ? 'Ex: CAMES, HCERES' : 'Ex: Informatique, Droit',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Ajouter')),
        ],
      ),
    );
    if (result == null || result.trim().isEmpty) return;
    setState(() {
      if (isAccreditation) {
        if (!_accreditations.contains(result.trim())) _accreditations.add(result.trim());
      } else {
        if (!_programsOffered.contains(result.trim())) _programsOffered.add(result.trim());
      }
    });
  }

  // =========================================================================
  // PROGRAMS (FILIERES) MANAGEMENT
  // =========================================================================

  Future<void> _addProgram() async {
    if (!_isEditing) return;

    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String level = 'licence';
    final durationCtrl = TextEditingController(text: '3');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Ajouter une filiere'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nom de la filiere *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: level,
                  decoration: const InputDecoration(labelText: 'Niveau'),
                  items: AdminConstants.programLevels.map((l) => DropdownMenuItem(
                    value: l,
                    child: Text(AdminConstants.programLevelLabels[l] ?? l),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => level = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationCtrl,
                  decoration: const InputDecoration(labelText: 'Duree (annees)'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, {
                  'name': nameCtrl.text.trim(),
                  'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  'level': level,
                  'duration_years': int.tryParse(durationCtrl.text),
                });
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    try {
      final api = getIt<ApiClient>();
      await api.post(
        ApiEndpoints.adminSchoolPrograms(widget.schoolId!),
        data: result,
      );
      if (mounted) AdminSnackbar.success(context, 'Filiere ajoutee');
      _loadSchool();
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur: $e');
    }
  }

  Future<void> _editProgram(Map<String, dynamic> program) async {
    if (!_isEditing) return;

    final nameCtrl = TextEditingController(text: program['name'] ?? '');
    final descCtrl = TextEditingController(text: program['description'] ?? '');
    String level = program['level'] ?? 'licence';
    final durationCtrl = TextEditingController(text: program['duration_years']?.toString() ?? '');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Modifier la filiere'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom de la filiere *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: AdminConstants.programLevels.contains(level) ? level : 'licence',
                  decoration: const InputDecoration(labelText: 'Niveau'),
                  items: AdminConstants.programLevels.map((l) => DropdownMenuItem(
                    value: l,
                    child: Text(AdminConstants.programLevelLabels[l] ?? l),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => level = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationCtrl,
                  decoration: const InputDecoration(labelText: 'Duree (annees)'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, {
                  'name': nameCtrl.text.trim(),
                  'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  'level': level,
                  'duration_years': int.tryParse(durationCtrl.text),
                });
              },
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    try {
      final api = getIt<ApiClient>();
      await api.put(
        ApiEndpoints.adminSchoolProgramById(widget.schoolId!, program['id']),
        data: result,
      );
      if (mounted) AdminSnackbar.success(context, 'Filiere modifiee');
      _loadSchool();
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur: $e');
    }
  }

  Future<void> _deleteProgram(String programId) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Supprimer la filiere',
      message: 'Cette action est irreversible.',
      confirmLabel: 'Supprimer',
      isDanger: true,
    );
    if (confirmed != true) return;

    try {
      final api = getIt<ApiClient>();
      await api.delete(ApiEndpoints.adminSchoolProgramById(widget.schoolId!, programId));
      if (mounted) AdminSnackbar.success(context, 'Filiere supprimee');
      _loadSchool();
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.contentPadding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/schools')),
                const SizedBox(width: 8),
                Text(_isEditing ? 'Modifier l\'ecole' : 'Nouvelle ecole', style: AppTypography.heading1),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isEditing ? 'Sauvegarder' : 'Creer'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =====================================================
                // LEFT COLUMN - Main info
                // =====================================================
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // Informations generales
                      _buildInfoCard(),
                      const SizedBox(height: 16),
                      // Admission & Frais
                      _buildAdmissionCard(),
                      const SizedBox(height: 16),
                      // Filieres (programmes)
                      if (_isEditing) _buildProgramsCard(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // =====================================================
                // RIGHT COLUMN - Options, images, tags
                // =====================================================
                Expanded(
                  child: Column(
                    children: [
                      _buildOptionsCard(),
                      const SizedBox(height: 16),
                      _buildImagesCard(),
                      const SizedBox(height: 16),
                      _buildAccreditationsCard(),
                      const SizedBox(height: 16),
                      _buildProgramsOfferedCard(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // CARD: Informations generales
  // =========================================================================

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informations generales', style: AppTypography.heading3),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nom de l\'etablissement *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Le nom est requis' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _type,
                    decoration: const InputDecoration(labelText: 'Type *'),
                    items: AdminConstants.schoolTypes.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(AdminConstants.schoolTypeLabels[t] ?? t),
                    )).toList(),
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cityCtrl,
                    decoration: const InputDecoration(labelText: 'Ville *'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'La ville est requise' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Adresse complete'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Telephone', hintText: '+228 XX XX XX XX'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) {
                      if (v != null && v.isNotEmpty && !v.contains('@')) return 'Email invalide';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _websiteCtrl,
              decoration: const InputDecoration(labelText: 'Site web', hintText: 'https://...'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true),
              maxLines: 5,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _foundingYearCtrl,
                    decoration: const InputDecoration(labelText: 'Annee de fondation'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        final year = int.tryParse(v);
                        if (year == null || year < 1800 || year > 2100) return 'Annee invalide';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _studentCountCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre d\'etudiants'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // CARD: Admission & Frais
  // =========================================================================

  Widget _buildAdmissionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admission & Frais', style: AppTypography.heading3),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tuitionRangeCtrl,
              decoration: const InputDecoration(
                labelText: 'Frais de scolarite',
                hintText: 'Ex: 500 000 - 1 200 000 FCFA/an',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _admissionReqCtrl,
              decoration: const InputDecoration(
                labelText: 'Conditions d\'admission',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // CARD: Options (switches)
  // =========================================================================

  Widget _buildOptionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Options', style: AppTypography.heading3),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Etablissement public'),
              subtitle: Text(_isPublic ? 'Publique' : 'Privee', style: AppTypography.bodySmall),
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
            ),
            if (_isEditing)
              SwitchListTile(
                title: const Text('Actif'),
                subtitle: Text(_isActive ? 'Visible dans l\'app' : 'Masque', style: AppTypography.bodySmall),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // CARD: Images (logo + banniere)
  // =========================================================================

  Widget _buildImagesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Images', style: AppTypography.heading3),
            const SizedBox(height: 16),

            // Logo
            Text('Logo', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildImageUpload(
              url: _logoUrl,
              isUploading: _isUploadingLogo,
              onUpload: () => _uploadImage(isLogo: true),
              onRemove: () => setState(() => _logoUrl = null),
              height: 100,
            ),

            const SizedBox(height: 20),

            // Cover
            Text('Banniere', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildImageUpload(
              url: _coverImageUrl,
              isUploading: _isUploadingCover,
              onUpload: () => _uploadImage(isLogo: false),
              onRemove: () => setState(() => _coverImageUrl = null),
              height: 120,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUpload({
    String? url,
    required bool isUploading,
    required VoidCallback onUpload,
    required VoidCallback onRemove,
    double height = 100,
  }) {
    if (isUploading) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (url != null && url.isNotEmpty) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: height,
                color: AppColors.surfaceVariant,
                child: const Center(child: Icon(Icons.broken_image, color: AppColors.textMuted)),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _miniIconButton(Icons.edit, onUpload),
                const SizedBox(width: 4),
                _miniIconButton(Icons.close, onRemove, color: AppColors.error),
              ],
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: onUpload,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.3), style: BorderStyle.solid),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_upload_outlined, color: AppColors.textMuted),
              SizedBox(height: 4),
              Text('Cliquer pour uploader', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniIconButton(IconData icon, VoidCallback onPressed, {Color? color}) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: color ?? AppColors.textMuted),
        ),
      ),
    );
  }

  // =========================================================================
  // CARD: Accreditations
  // =========================================================================

  Widget _buildAccreditationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Accreditations', style: AppTypography.heading3),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => _addTag(isAccreditation: true),
                  tooltip: 'Ajouter',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_accreditations.isEmpty)
              Text('Aucune accreditation', style: AppTypography.bodySmall),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _accreditations.map((a) => Chip(
                label: Text(a),
                onDeleted: () => setState(() => _accreditations.remove(a)),
                backgroundColor: AppColors.success.withValues(alpha: 0.1),
                labelStyle: TextStyle(color: AppColors.success),
                deleteIconColor: AppColors.success,
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // CARD: Domaines de formation (programs_offered)
  // =========================================================================

  Widget _buildProgramsOfferedCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Domaines', style: AppTypography.heading3),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => _addTag(isAccreditation: false),
                  tooltip: 'Ajouter',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_programsOffered.isEmpty)
              Text('Aucun domaine', style: AppTypography.bodySmall),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _programsOffered.map((p) => Chip(
                label: Text(p),
                onDeleted: () => setState(() => _programsOffered.remove(p)),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // CARD: Filieres (programmes)
  // =========================================================================

  Widget _buildProgramsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Filieres (${_programs.length})', style: AppTypography.heading3),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _addProgram,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Ajouter'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_programs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Aucune filiere. Cliquez sur "Ajouter" pour creer des filieres.',
                    style: AppTypography.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ..._programs.map((p) => _buildProgramTile(p)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramTile(Map<String, dynamic> program) {
    final levelLabel = AdminConstants.programLevelLabels[program['level']] ?? program['level'] ?? '';
    final duration = program['duration_years'];
    final subtitle = [
      if (levelLabel.isNotEmpty) levelLabel,
      if (duration != null) '$duration an${duration > 1 ? 's' : ''}',
    ].join(' - ');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(program['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle.isNotEmpty)
            Text(subtitle, style: TextStyle(color: AppColors.primary, fontSize: 12)),
          if (program['description'] != null && (program['description'] as String).isNotEmpty)
            Text(
              program['description'],
              style: AppTypography.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: () => _editProgram(program),
            tooltip: 'Modifier',
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
            onPressed: () => _deleteProgram(program['id']),
            tooltip: 'Supprimer',
          ),
        ],
      ),
    );
  }
}
