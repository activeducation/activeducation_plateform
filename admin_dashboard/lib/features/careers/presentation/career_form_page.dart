import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/admin_constants.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/feedback/admin_snackbar.dart';

class CareerFormPage extends StatefulWidget {
  final String? careerId;
  const CareerFormPage({super.key, this.careerId});

  @override
  State<CareerFormPage> createState() => _CareerFormPageState();
}

class _CareerFormPageState extends State<CareerFormPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;
  bool get _isEditing => widget.careerId != null;

  // Base tab
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _sectorNameCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  String? _jobDemand;
  String? _growthTrend;
  List<String> _skills = [];
  List<String> _traits = [];

  // Education tab
  String _minLevel = 'BAC';
  final _durationCtrl = TextEditingController();
  List<String> _formations = [];

  // Perspectives tab
  final _salaryMinCtrl = TextEditingController();
  final _salaryMaxCtrl = TextEditingController();
  final _salaryAvgCtrl = TextEditingController();
  final _outlookCtrl = TextEditingController();
  List<String> _employers = [];
  bool _entrepreneurship = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    if (_isEditing) _loadCareer();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _sectorNameCtrl.dispose();
    _imageUrlCtrl.dispose();
    _durationCtrl.dispose();
    _salaryMinCtrl.dispose();
    _salaryMaxCtrl.dispose();
    _salaryAvgCtrl.dispose();
    _outlookCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCareer() async {
    setState(() => _isLoading = true);
    try {
      final api = getIt<ApiClient>();
      final response = await api.get(ApiEndpoints.adminCareerById(widget.careerId!));
      final d = response.data as Map<String, dynamic>;
      _nameCtrl.text = d['name'] ?? '';
      _descCtrl.text = d['description'] ?? '';
      _sectorNameCtrl.text = d['sector_name'] ?? '';
      _imageUrlCtrl.text = d['image_url'] ?? '';
      _jobDemand = d['job_demand'];
      _growthTrend = d['growth_trend'];
      _skills = List<String>.from(d['required_skills'] ?? []);
      _traits = List<String>.from(d['related_traits'] ?? []);
      final edu = d['education_path'] as Map<String, dynamic>? ?? {};
      _minLevel = edu['minimum_level'] ?? 'BAC';
      _durationCtrl.text = '${edu['duration_years'] ?? 3}';
      _formations = List<String>.from(edu['recommended_formations'] ?? []);
      _salaryMinCtrl.text = '${d['salary_min_fcfa'] ?? ''}';
      _salaryMaxCtrl.text = '${d['salary_max_fcfa'] ?? ''}';
      _salaryAvgCtrl.text = '${d['salary_avg_fcfa'] ?? ''}';
      _outlookCtrl.text = d['outlook_description'] ?? '';
      _employers = List<String>.from(d['top_employers'] ?? []);
      _entrepreneurship = d['entrepreneurship_potential'] ?? false;
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur de chargement');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final data = {
      'name': _nameCtrl.text,
      'description': _descCtrl.text,
      'sector_name': _sectorNameCtrl.text,
      'image_url': _imageUrlCtrl.text.isEmpty ? null : _imageUrlCtrl.text,
      'required_skills': _skills,
      'related_traits': _traits,
      'job_demand': _jobDemand,
      'growth_trend': _growthTrend,
      'education_path': {
        'minimum_level': _minLevel,
        'duration_years': int.tryParse(_durationCtrl.text) ?? 3,
        'recommended_formations': _formations,
      },
      'salary_min_fcfa': int.tryParse(_salaryMinCtrl.text),
      'salary_max_fcfa': int.tryParse(_salaryMaxCtrl.text),
      'salary_avg_fcfa': int.tryParse(_salaryAvgCtrl.text),
      'outlook_description': _outlookCtrl.text.isEmpty ? null : _outlookCtrl.text,
      'top_employers': _employers,
      'entrepreneurship_potential': _entrepreneurship,
    };

    try {
      final api = getIt<ApiClient>();
      if (_isEditing) {
        await api.put(ApiEndpoints.adminCareerById(widget.careerId!), data: data);
      } else {
        await api.post(ApiEndpoints.adminCareers, data: data);
      }
      if (mounted) {
        AdminSnackbar.success(context, _isEditing ? 'Carriere modifiee' : 'Carriere creee');
        context.go('/careers');
      }
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur de sauvegarde');
    }
    setState(() => _isSaving = false);
  }

  void _addChip(List<String> list, String label) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ajouter $label'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Ajouter')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => list.add(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.contentPadding, AppSpacing.contentPadding, AppSpacing.contentPadding, 0),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/careers')),
                const SizedBox(width: 8),
                Text(_isEditing ? 'Modifier la carriere' : 'Nouvelle carriere', style: AppTypography.heading1),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isEditing ? 'Sauvegarder' : 'Creer'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TabBar(controller: _tabCtrl, tabs: const [
            Tab(text: 'Base'),
            Tab(text: 'Parcours educatif'),
            Tab(text: 'Perspectives'),
          ]),
          Expanded(
            child: TabBarView(controller: _tabCtrl, children: [
              _buildBaseTab(),
              _buildEducationTab(),
              _buildPerspectivesTab(),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildBaseTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.contentPadding),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nom *'),
                  validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description *'), maxLines: 3,
                  validator: (v) => v == null || v.length < 10 ? 'Min 10 caracteres' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _sectorNameCtrl, decoration: const InputDecoration(labelText: 'Secteur *'),
                  validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _imageUrlCtrl, decoration: const InputDecoration(labelText: 'URL image')),
              const SizedBox(height: 16),
              Text('Competences', style: AppTypography.label),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ..._skills.map((s) => Chip(label: Text(s), onDeleted: () => setState(() => _skills.remove(s)))),
                ActionChip(label: const Text('+ Ajouter'), onPressed: () => _addChip(_skills, 'competence')),
              ]),
              const SizedBox(height: 16),
              Text('Traits RIASEC', style: AppTypography.label),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: AdminConstants.riasecCategories.map((t) {
                final sel = _traits.contains(t);
                return FilterChip(label: Text(t), selected: sel, onSelected: (v) {
                  setState(() { v ? _traits.add(t) : _traits.remove(t); });
                });
              }).toList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEducationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.contentPadding),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _minLevel,
                decoration: const InputDecoration(labelText: 'Niveau minimum'),
                items: ['BEPC', 'BAC', 'BAC+2', 'BAC+3', 'BAC+5', 'BAC+8']
                    .map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (v) => setState(() => _minLevel = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _durationCtrl, decoration: const InputDecoration(labelText: 'Duree (annees)'),
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              Text('Formations recommandees', style: AppTypography.label),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ..._formations.map((f) => Chip(label: Text(f), onDeleted: () => setState(() => _formations.remove(f)))),
                ActionChip(label: const Text('+ Ajouter'), onPressed: () => _addChip(_formations, 'formation')),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerspectivesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.contentPadding),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _salaryMinCtrl, decoration: const InputDecoration(labelText: 'Salaire min (FCFA)'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _salaryMaxCtrl, decoration: const InputDecoration(labelText: 'Salaire max (FCFA)'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _salaryAvgCtrl, decoration: const InputDecoration(labelText: 'Salaire moyen (FCFA)'), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: _jobDemand,
                      decoration: const InputDecoration(labelText: 'Demande'),
                      items: [null, ...AdminConstants.jobDemands].map((d) => DropdownMenuItem(
                        value: d, child: Text(d ?? 'Non defini'),
                      )).toList(),
                      onChanged: (v) => setState(() => _jobDemand = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: _growthTrend,
                      decoration: const InputDecoration(labelText: 'Tendance'),
                      items: [null, ...AdminConstants.growthTrends].map((t) => DropdownMenuItem(
                        value: t, child: Text(t ?? 'Non defini'),
                      )).toList(),
                      onChanged: (v) => setState(() => _growthTrend = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _outlookCtrl, decoration: const InputDecoration(labelText: 'Description perspectives'), maxLines: 3),
              const SizedBox(height: 16),
              Text('Principaux employeurs', style: AppTypography.label),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ..._employers.map((e) => Chip(label: Text(e), onDeleted: () => setState(() => _employers.remove(e)))),
                ActionChip(label: const Text('+ Ajouter'), onPressed: () => _addChip(_employers, 'employeur')),
              ]),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Potentiel entrepreneurial'),
                value: _entrepreneurship,
                onChanged: (v) => setState(() => _entrepreneurship = v),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
