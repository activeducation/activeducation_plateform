import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/feedback/admin_snackbar.dart';

class OpportunityEditorPage extends StatefulWidget {
  final String? opportunityId;
  const OpportunityEditorPage({super.key, this.opportunityId});

  @override
  State<OpportunityEditorPage> createState() => _OpportunityEditorPageState();
}

class _OpportunityEditorPageState extends State<OpportunityEditorPage> {
  bool get _isEditing => widget.opportunityId != null;
  bool _isLoading = false;
  bool _isSaving = false;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();
  final _orgLogoCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _requirementsCtrl = TextEditingController();
  final _benefitsCtrl = TextEditingController();
  final _salaryMinCtrl = TextEditingController();
  final _salaryMaxCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _deadlineCtrl = TextEditingController();

  String _type = 'job';
  String _remote = 'onsite';
  String _currency = 'EUR';
  bool _isPublished = false;
  bool _isFeatured = false;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _orgCtrl.dispose();
    _orgLogoCtrl.dispose();
    _locationCtrl.dispose();
    _durationCtrl.dispose();
    _requirementsCtrl.dispose();
    _benefitsCtrl.dispose();
    _salaryMinCtrl.dispose();
    _salaryMaxCtrl.dispose();
    _urlCtrl.dispose();
    _deadlineCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final api = getIt<ApiClient>();
      final response = await api.get(ApiEndpoints.adminOpportunityById(widget.opportunityId!));
      final data = response.data as Map<String, dynamic>;
      _titleCtrl.text = data['title'] ?? '';
      _descCtrl.text = data['description'] ?? '';
      _orgCtrl.text = data['organization_name'] ?? '';
      _orgLogoCtrl.text = data['organization_logo'] ?? '';
      _locationCtrl.text = data['location'] ?? '';
      _durationCtrl.text = data['duration'] ?? '';
      _requirementsCtrl.text = data['requirements'] ?? '';
      _benefitsCtrl.text = data['benefits'] ?? '';
      _salaryMinCtrl.text = data['salary_min']?.toString() ?? '';
      _salaryMaxCtrl.text = data['salary_max']?.toString() ?? '';
      _urlCtrl.text = data['application_url'] ?? '';
      _deadlineCtrl.text = data['application_deadline'] ?? '';
      _type = data['opportunity_type'] ?? 'job';
      _remote = data['remote_type'] ?? 'onsite';
      _currency = data['salary_currency'] ?? 'EUR';
      _isPublished = data['is_published'] ?? false;
      _isFeatured = data['is_featured'] ?? false;
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur de chargement');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.isEmpty || _descCtrl.text.isEmpty || _orgCtrl.text.isEmpty) {
      AdminSnackbar.error(context, 'Titre, description et organisation requis');
      return;
    }
    setState(() => _isSaving = true);

    final data = {
      'title': _titleCtrl.text,
      'description': _descCtrl.text,
      'organization_name': _orgCtrl.text,
      'organization_logo': _orgLogoCtrl.text.isNotEmpty ? _orgLogoCtrl.text : null,
      'location': _locationCtrl.text.isNotEmpty ? _locationCtrl.text : null,
      'opportunity_type': _type,
      'remote_type': _remote,
      'duration': _durationCtrl.text.isNotEmpty ? _durationCtrl.text : null,
      'requirements': _requirementsCtrl.text.isNotEmpty ? _requirementsCtrl.text : null,
      'benefits': _benefitsCtrl.text.isNotEmpty ? _benefitsCtrl.text : null,
      'salary_min': _salaryMinCtrl.text.isNotEmpty ? int.tryParse(_salaryMinCtrl.text) : null,
      'salary_max': _salaryMaxCtrl.text.isNotEmpty ? int.tryParse(_salaryMaxCtrl.text) : null,
      'salary_currency': _currency,
      'application_url': _urlCtrl.text.isNotEmpty ? _urlCtrl.text : null,
      'application_deadline': _deadlineCtrl.text.isNotEmpty ? _deadlineCtrl.text : null,
      'is_published': _isPublished,
      'is_featured': _isFeatured,
    };

    try {
      final api = getIt<ApiClient>();
      if (_isEditing) {
        await api.put(ApiEndpoints.adminOpportunityById(widget.opportunityId!), data: data);
        if (mounted) AdminSnackbar.success(context, 'Opportunité mise à jour');
      } else {
        await api.post(ApiEndpoints.adminOpportunities, data: data);
        if (mounted) {
          AdminSnackbar.success(context, 'Opportunité créée');
          context.go('/opportunities');
        }
        return;
      }
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier l\'opportunité' : 'Nouvelle opportunité'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/opportunities')),
        actions: [
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Enregistrer'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.contentPadding),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Informations générales', style: AppTypography.heading3),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Titre *'))),
              const SizedBox(width: 16),
              SizedBox(width: 150, child: DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'job', child: Text('Emploi')),
                  DropdownMenuItem(value: 'internship', child: Text('Stage')),
                  DropdownMenuItem(value: 'volunteer', child: Text('Bénévolat')),
                  DropdownMenuItem(value: 'scholarship', child: Text('Bourse')),
                ],
                onChanged: (v) => setState(() => _type = v!),
              )),
            ]),
            const SizedBox(height: 16),
            TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description *'), maxLines: 5),
          ]))),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Organisation', style: AppTypography.heading3),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: TextField(controller: _orgCtrl, decoration: const InputDecoration(labelText: 'Nom *'))),
              const SizedBox(width: 16),
              Expanded(child: TextField(controller: _orgLogoCtrl, decoration: const InputDecoration(labelText: 'Logo URL'))),
            ]),
          ]))),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Détails', style: AppTypography.heading3),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: TextField(controller: _locationCtrl, decoration: const InputDecoration(labelText: 'Lieu'))),
              const SizedBox(width: 16),
              SizedBox(width: 150, child: DropdownButtonFormField<String>(
                value: _remote,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'onsite', child: Text('Sur site')),
                  DropdownMenuItem(value: 'remote', child: Text('Remote')),
                  DropdownMenuItem(value: 'hybrid', child: Text('Hybride')),
                ],
                onChanged: (v) => setState(() => _remote = v!),
              )),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: TextField(controller: _durationCtrl, decoration: const InputDecoration(labelText: 'Durée'))),
              const SizedBox(width: 16),
              Expanded(child: TextField(controller: _deadlineCtrl, decoration: const InputDecoration(labelText: 'Deadline (YYYY-MM-DD)'))),
            ]),
          ]))),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Conditions', style: AppTypography.heading3),
            const SizedBox(height: 16),
            TextField(controller: _requirementsCtrl, decoration: const InputDecoration(labelText: 'Requirements'), maxLines: 3),
            const SizedBox(height: 16),
            TextField(controller: _benefitsCtrl, decoration: const InputDecoration(labelText: 'Benefits'), maxLines: 3),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: TextField(controller: _salaryMinCtrl, decoration: const InputDecoration(labelText: 'Salaire min'), keyboardType: TextInputType.number)),
              const SizedBox(width: 16),
              Expanded(child: TextField(controller: _salaryMaxCtrl, decoration: const InputDecoration(labelText: 'Salaire max'), keyboardType: TextInputType.number)),
              const SizedBox(width: 16),
              SizedBox(width: 100, child: DropdownButtonFormField<String>(
                value: _currency,
                decoration: const InputDecoration(labelText: 'Devise'),
                items: const [
                  DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                  DropdownMenuItem(value: 'XOF', child: Text('XOF')),
                ],
                onChanged: (v) => setState(() => _currency = v!),
              )),
            ]),
          ]))),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Candidature', style: AppTypography.heading3),
            const SizedBox(height: 16),
            TextField(controller: _urlCtrl, decoration: const InputDecoration(labelText: 'URL de candidature')),
          ]))),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Publication', style: AppTypography.heading3),
            const SizedBox(height: 16),
            SwitchListTile(title: const Text('Publié'), value: _isPublished, onChanged: (v) => setState(() => _isPublished = v)),
            SwitchListTile(title: const Text('En featured'), value: _isFeatured, onChanged: (v) => setState(() => _isFeatured = v)),
          ]))),
        ]),
      ),
    );
  }
}