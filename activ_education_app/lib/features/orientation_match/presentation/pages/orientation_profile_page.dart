import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/buttons/gradient_button.dart';
import '../../data/datasources/orientation_match_datasource.dart';
import '../../data/models/orientation_profile_model.dart';
import '../widgets/tag_input.dart';

/// Formulaire du profil d'orientation (notes, matières, intérêts, budget, projet).
class OrientationProfilePage extends StatefulWidget {
  const OrientationProfilePage({super.key});

  @override
  State<OrientationProfilePage> createState() => _OrientationProfilePageState();
}

class _OrientationProfilePageState extends State<OrientationProfilePage> {
  late final OrientationMatchDataSource _ds;

  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  final Map<String, double> _grades = {};
  List<String> _favoriteSubjects = [];
  List<String> _interests = [];
  final _budgetController = TextEditingController();
  final _projectController = TextEditingController();

  static const _commonSubjects = [
    'Mathématiques', 'Physique', 'Chimie', 'SVT', 'Français',
    'Philosophie', 'Histoire', 'Géographie', 'Anglais', 'Économie',
    'Informatique',
  ];

  @override
  void initState() {
    super.initState();
    _ds = OrientationMatchDataSourceImpl(getIt<Dio>(instanceName: 'apiClient'));
    _load();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _projectController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final profile = await _ds.getProfile();
      if (!mounted) return;
      setState(() {
        _grades
          ..clear()
          ..addAll(profile.grades);
        _favoriteSubjects = List.of(profile.favoriteSubjects);
        _interests = List.of(profile.interests);
        _budgetController.text =
            profile.budgetAnnualFcfa?.toString() ?? '';
        _projectController.text = profile.careerProject ?? '';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Impossible de charger ton profil.';
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final budget = int.tryParse(
      _budgetController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    final project = _projectController.text.trim();
    final model = OrientationProfileModel(
      grades: _grades,
      favoriteSubjects: _favoriteSubjects,
      interests: _interests,
      budgetAnnualFcfa: budget,
      careerProject: project.isEmpty ? null : project,
    );
    try {
      await _ds.saveProfile(model);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil enregistré')),
      );
      context.pushReplacement('/orientation/recommendations');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de l\'enregistrement, réessaie.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Mon profil d\'orientation',
            style: AppTypography.titleSmall.copyWith(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _buildForm(),
      bottomNavigationBar: _loading ? null : _buildSaveBar(),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (_loadError != null) ...[
          Text(_loadError!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
          const SizedBox(height: 12),
        ],
        _sectionTitle('Tes notes', 'Ajoute tes moyennes par matière (sur 20).'),
        const SizedBox(height: 12),
        _buildGrades(),
        const SizedBox(height: 24),
        _sectionTitle('Tes matières préférées', null),
        const SizedBox(height: 8),
        TagInput(
          label: '',
          hint: 'Ex : Mathématiques',
          initial: _favoriteSubjects,
          suggestions: _commonSubjects,
          onChanged: (v) => _favoriteSubjects = v,
        ),
        const SizedBox(height: 24),
        _sectionTitle('Tes centres d\'intérêt', null),
        const SizedBox(height: 8),
        TagInput(
          label: '',
          hint: 'Ex : programmation, sport, dessin',
          initial: _interests,
          suggestions: const [
            'Programmation', 'Sport', 'Dessin', 'Musique', 'Sciences',
            'Voyages', 'Lecture', 'Entrepreneuriat',
          ],
          onChanged: (v) => _interests = v,
        ),
        const SizedBox(height: 24),
        _sectionTitle('Ton budget annuel', 'Montant maximum pour tes études (FCFA).'),
        const SizedBox(height: 8),
        _buildBudget(),
        const SizedBox(height: 24),
        _sectionTitle('Ton projet professionnel', 'Décris en quelques mots ce que tu aimerais faire.'),
        const SizedBox(height: 8),
        _buildProject(),
      ],
    );
  }

  Widget _sectionTitle(String title, String? subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: AppTypography.titleSmall.copyWith(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textTertiary)),
        ],
      ],
    );
  }

  // ---- Notes ----

  Widget _buildGrades() {
    final remaining =
        _commonSubjects.where((s) => !_grades.containsKey(s)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._grades.keys.map(_buildGradeRow),
        if (remaining.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: remaining.map((s) {
              return ActionChip(
                avatar: const Icon(Icons.add_rounded,
                    size: 15, color: AppColors.primary),
                label: Text(s,
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.primary, fontSize: 11)),
                backgroundColor: AppColors.primarySurface,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                onPressed: () => setState(() => _grades[s] = 10),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildGradeRow(String subject) {
    final value = _grades[subject] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(subject,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textPrimary)),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: 0,
              max: 20,
              divisions: 40,
              activeColor: AppColors.primary,
              label: value.toStringAsFixed(1),
              onChanged: (v) => setState(() => _grades[subject] = v),
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(value.toStringAsFixed(1),
                textAlign: TextAlign.right,
                style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded,
                size: 18, color: AppColors.textTertiary),
            onPressed: () => setState(() => _grades.remove(subject)),
          ),
        ],
      ),
    );
  }

  // ---- Budget ----

  Widget _buildBudget() {
    return TextField(
      controller: _budgetController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Ex : 300000',
        suffixText: 'FCFA / an',
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  // ---- Projet ----

  Widget _buildProject() {
    return TextField(
      controller: _projectController,
      maxLines: 4,
      maxLength: 2000,
      textCapitalization: TextCapitalization.sentences,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Ex : Je veux devenir ingénieur en informatique...',
        filled: true,
        fillColor: AppColors.surface,
        alignLabelWithHint: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSaveBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: GradientButton(
        text: _saving ? 'Enregistrement...' : 'Voir mes recommandations',
        icon: Icons.auto_awesome_rounded,
        onPressed: _saving ? null : _save,
      ),
    );
  }
}
