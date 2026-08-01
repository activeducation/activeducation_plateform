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

part 'school_form_page.cards.dart';

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
      final response = await api.get(
        ApiEndpoints.adminSchoolById(widget.schoolId!),
      );
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
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'type': _type,
      'city': _cityCtrl.text.trim(),
      'address': _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      'website': _websiteCtrl.text.trim().isEmpty
          ? null
          : _websiteCtrl.text.trim(),
      'description': _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
      'is_public': _isPublic,
      'logo_url': _logoUrl,
      'cover_image_url': _coverImageUrl,
      'tuition_range': _tuitionRangeCtrl.text.trim().isEmpty
          ? null
          : _tuitionRangeCtrl.text.trim(),
      'admission_requirements': _admissionReqCtrl.text.trim().isEmpty
          ? null
          : _admissionReqCtrl.text.trim(),
      'accreditations': _accreditations,
      'programs_offered': _programsOffered,
      'founding_year': _foundingYearCtrl.text.trim().isEmpty
          ? null
          : int.tryParse(_foundingYearCtrl.text.trim()),
      'student_count': _studentCountCtrl.text.trim().isEmpty
          ? null
          : int.tryParse(_studentCountCtrl.text.trim()),
    };

    if (_isEditing) {
      data['is_active'] = _isActive;
    }

    try {
      final api = getIt<ApiClient>();
      if (_isEditing) {
        await api.put(
          ApiEndpoints.adminSchoolById(widget.schoolId!),
          data: data,
        );
      } else {
        await api.post(ApiEndpoints.adminSchools, data: data);
      }
      if (mounted) {
        AdminSnackbar.success(
          context,
          _isEditing ? 'Ecole modifiee' : 'Ecole creee',
        );
        context.go('/schools');
      }
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur de sauvegarde: $e');
    }
    if (mounted) setState(() => _isSaving = false);
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
      if (isLogo) {
        _isUploadingLogo = true;
      } else {
        _isUploadingCover = true;
      }
    });

    try {
      final api = getIt<ApiClient>();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
          contentType: DioMediaType.parse(
            file.extension == 'png'
                ? 'image/png'
                : file.extension == 'webp'
                ? 'image/webp'
                : 'image/jpeg',
          ),
        ),
      });

      final response = await api.dio.post(
        ApiEndpoints.adminUpload('schools'),
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 120),
        ),
      );

      final url = (response.data as Map<String, dynamic>)['url'] as String;
      setState(() {
        if (isLogo) {
          _logoUrl = url;
        } else {
          _coverImageUrl = url;
        }
      });
      if (mounted) AdminSnackbar.success(context, 'Image uploadee');
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur d\'upload: $e');
    }

    if (mounted) {
      setState(() {
        if (isLogo) {
          _isUploadingLogo = false;
        } else {
          _isUploadingCover = false;
        }
      });
    }
  }

  // =========================================================================
  // TAGS MANAGEMENT (accreditations, programs_offered)
  // =========================================================================

  Future<void> _addTag({required bool isAccreditation}) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isAccreditation
              ? 'Ajouter une accreditation'
              : 'Ajouter un domaine de formation',
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: isAccreditation
                ? 'Ex: CAMES, HCERES'
                : 'Ex: Informatique, Droit',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result == null || result.trim().isEmpty) return;
    setState(() {
      if (isAccreditation) {
        if (!_accreditations.contains(result.trim())) {
          _accreditations.add(result.trim());
        }
      } else {
        if (!_programsOffered.contains(result.trim())) {
          _programsOffered.add(result.trim());
        }
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
                  decoration: const InputDecoration(
                    labelText: 'Nom de la filiere *',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: level,
                  decoration: const InputDecoration(labelText: 'Niveau'),
                  items: AdminConstants.programLevels
                      .map(
                        (l) => DropdownMenuItem(
                          value: l,
                          child: Text(
                            AdminConstants.programLevelLabels[l] ?? l,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => level = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Duree (annees)',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, {
                  'name': nameCtrl.text.trim(),
                  'description': descCtrl.text.trim().isEmpty
                      ? null
                      : descCtrl.text.trim(),
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

    nameCtrl.dispose();
    descCtrl.dispose();
    durationCtrl.dispose();
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
    final durationCtrl = TextEditingController(
      text: program['duration_years']?.toString() ?? '',
    );

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
                  decoration: const InputDecoration(
                    labelText: 'Nom de la filiere *',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: AdminConstants.programLevels.contains(level)
                      ? level
                      : 'licence',
                  decoration: const InputDecoration(labelText: 'Niveau'),
                  items: AdminConstants.programLevels
                      .map(
                        (l) => DropdownMenuItem(
                          value: l,
                          child: Text(
                            AdminConstants.programLevelLabels[l] ?? l,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => level = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Duree (annees)',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, {
                  'name': nameCtrl.text.trim(),
                  'description': descCtrl.text.trim().isEmpty
                      ? null
                      : descCtrl.text.trim(),
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

    nameCtrl.dispose();
    descCtrl.dispose();
    durationCtrl.dispose();
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
      await api.delete(
        ApiEndpoints.adminSchoolProgramById(widget.schoolId!, programId),
      );
      if (mounted) AdminSnackbar.success(context, 'Filiere supprimee');
      _loadSchool();
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  /// Permet aux cartes extraites (extension dans le part) de declencher un
  /// rebuild sans appeler directement le membre protege setState.
  void refresh(VoidCallback fn) => setState(fn);

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
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/schools'),
                ),
                const SizedBox(width: 8),
                Text(
                  _isEditing ? 'Modifier l\'ecole' : 'Nouvelle ecole',
                  style: AppTypography.heading1,
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
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
}
