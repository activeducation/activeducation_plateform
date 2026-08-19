import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../data/orientation_data_models.dart';
import '../data/orientation_data_repository.dart';

/// Saisie des donnees alimentant le moteur d'orientation multi-criteres.
///
/// Deux criteres sur cinq restent inactifs tant que ces champs sont vides :
/// - matieres cles des metiers  -> critere "notes"
/// - cout annuel des formations -> critere "budget"
class OrientationDataPage extends StatefulWidget {
  const OrientationDataPage({super.key});

  @override
  State<OrientationDataPage> createState() => _OrientationDataPageState();
}

class _OrientationDataPageState extends State<OrientationDataPage>
    with SingleTickerProviderStateMixin {
  late final OrientationDataRepository _repo;
  late final TabController _tabs;

  List<CareerSubjects> _careers = [];
  List<ProgramCost> _programs = [];
  bool _loading = true;
  String? _error;
  bool _onlyMissing = false;

  @override
  void initState() {
    super.initState();
    _repo = OrientationDataRepository(getIt<ApiClient>());
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final careers = await _repo.getCareers();
      final programs = await _repo.getPrograms();
      if (!mounted) return;
      setState(() {
        _careers = careers;
        _programs = programs;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les donnees d\'orientation.';
      });
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donnees d\'orientation'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Matieres cles des metiers'),
            Tab(text: 'Cout des formations'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Recharger',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [_buildCareersTab(), _buildProgramsTab()],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!),
          const SizedBox(height: 12),
          FilledButton(onPressed: _load, child: const Text('Reessayer')),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // En-tete : avancement + filtre
  // ------------------------------------------------------------------

  Widget _buildHeader() {
    final onCareers = _tabs.index == 0;
    final total = onCareers ? _careers.length : _programs.length;
    final filled = onCareers
        ? _careers.where((c) => !c.isMissing).length
        : _programs.where((p) => !p.isMissing).length;
    final ratio = total == 0 ? 0.0 : filled / total;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  onCareers
                      ? '$filled / $total metiers renseignes — active le critere "notes"'
                      : '$filled / $total formations renseignees — active le critere "budget"',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 12),
              FilterChip(
                label: const Text('A completer'),
                selected: _onlyMissing,
                onSelected: (v) => setState(() => _onlyMissing = v),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: scheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Onglet 1 — matieres cles
  // ------------------------------------------------------------------

  Widget _buildCareersTab() {
    final items =
        _onlyMissing ? _careers.where((c) => c.isMissing).toList() : _careers;
    if (items.isEmpty) {
      return _buildEmpty(_onlyMissing
          ? 'Tous les metiers sont renseignes.'
          : 'Aucun metier. Lancez le seed : python scripts/seed_key_subjects.py');
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) => _buildCareerRow(items[i]),
    );
  }

  Widget _buildCareerRow(CareerSubjects career) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(career.name),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: career.isMissing
            ? Text('Aucune matiere — critere "notes" inactif',
                style: TextStyle(color: scheme.error, fontSize: 12))
            : Wrap(
                spacing: 6,
                runSpacing: 6,
                children: career.keySubjects
                    .map((s) => Chip(
                          label: Text(s, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
      ),
      trailing: IconButton(
        tooltip: 'Modifier les matieres',
        icon: const Icon(Icons.edit_rounded),
        onPressed: () => _editSubjects(career),
      ),
    );
  }

  Future<void> _editSubjects(CareerSubjects career) async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => _SubjectsDialog(career: career),
    );
    if (result == null) return;

    try {
      await _repo.saveKeySubjects(career.id, result);
      if (!mounted) return;
      setState(() {
        final i = _careers.indexWhere((c) => c.id == career.id);
        if (i != -1) _careers[i] = career.copyWith(keySubjects: result);
      });
      _toast('Matieres enregistrees');
    } catch (_) {
      _toast('Echec de l\'enregistrement');
    }
  }

  // ------------------------------------------------------------------
  // Onglet 2 — couts
  // ------------------------------------------------------------------

  Widget _buildProgramsTab() {
    final items =
        _onlyMissing ? _programs.where((p) => p.isMissing).toList() : _programs;
    if (items.isEmpty) {
      return _buildEmpty(_onlyMissing
          ? 'Toutes les formations sont renseignees.'
          : 'Aucune formation trouvee.');
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) => _buildProgramRow(items[i]),
    );
  }

  Widget _buildProgramRow(ProgramCost program) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = <String>[
      if (program.degreeLevel != null) program.degreeLevel!,
      if (program.isPublic == true) 'Public',
      if (program.isPublic == false) 'Prive',
    ].join(' · ');

    return ListTile(
      title: Text(program.name),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: program.isMissing
            ? Text('Aucun cout — critere "budget" inactif',
                style: TextStyle(color: scheme.error, fontSize: 12))
            : Text(
                '${_formatFcfa(program.tuitionAnnualFcfa!)} FCFA / an'
                '${subtitle.isEmpty ? '' : '  ·  $subtitle'}',
                style: const TextStyle(fontSize: 12),
              ),
      ),
      trailing: IconButton(
        tooltip: 'Modifier le cout',
        icon: const Icon(Icons.edit_rounded),
        onPressed: () => _editCost(program),
      ),
    );
  }

  static String _formatFcfa(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  Future<void> _editCost(ProgramCost program) async {
    final result = await showDialog<({int? tuition, bool? isPublic})>(
      context: context,
      builder: (_) => _CostDialog(program: program),
    );
    if (result == null) return;

    try {
      await _repo.saveProgramCost(
        program.id,
        tuitionAnnualFcfa: result.tuition,
        isPublic: result.isPublic,
      );
      if (!mounted) return;
      setState(() {
        final i = _programs.indexWhere((p) => p.id == program.id);
        if (i != -1) {
          _programs[i] = program.copyWith(
            tuitionAnnualFcfa: result.tuition,
            isPublic: result.isPublic,
          );
        }
      });
      _toast('Cout enregistre');
    } catch (_) {
      _toast('Echec de l\'enregistrement');
    }
  }
}

// ===========================================================================
// Dialogue — matieres cles
// ===========================================================================

class _SubjectsDialog extends StatefulWidget {
  final CareerSubjects career;
  const _SubjectsDialog({required this.career});

  @override
  State<_SubjectsDialog> createState() => _SubjectsDialogState();
}

class _SubjectsDialogState extends State<_SubjectsDialog> {
  late List<String> _subjects;
  final _controller = TextEditingController();

  /// Meme vocabulaire que le script de seed : le moteur fait une
  /// correspondance exacte avec les matieres saisies par l'eleve.
  static const _common = [
    'Mathematiques', 'Physique', 'Chimie', 'SVT', 'Francais',
    'Philosophie', 'Histoire', 'Geographie', 'Anglais', 'Economie',
    'Comptabilite', 'Informatique', 'Arts plastiques',
  ];

  @override
  void initState() {
    super.initState();
    _subjects = List.of(widget.career.keySubjects);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return;
    if (_subjects.any((s) => s.toLowerCase() == value.toLowerCase())) {
      _controller.clear();
      return;
    }
    setState(() {
      _subjects.add(value);
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _common
        .where((s) => !_subjects.any((v) => v.toLowerCase() == s.toLowerCase()))
        .toList();

    return AlertDialog(
      title: Text(widget.career.name),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Matieres scolaires determinantes pour ce metier. Les notes de '
                'l\'eleve dans ces matieres alimentent le critere "notes".',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 14),
              if (_subjects.isEmpty)
                const Text('Aucune matiere selectionnee',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic))
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _subjects
                      .map((s) => Chip(
                            label: Text(s),
                            onDeleted: () => setState(() => _subjects.remove(s)),
                          ))
                      .toList(),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Ajouter une matiere',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () => _add(_controller.text),
                  ),
                ),
                onSubmitted: _add,
              ),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: suggestions
                      .map((s) => ActionChip(
                            label: Text('+ $s',
                                style: const TextStyle(fontSize: 11)),
                            onPressed: () => _add(s),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _subjects),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

// ===========================================================================
// Dialogue — cout de formation
// ===========================================================================

class _CostDialog extends StatefulWidget {
  final ProgramCost program;
  const _CostDialog({required this.program});

  @override
  State<_CostDialog> createState() => _CostDialogState();
}

class _CostDialogState extends State<_CostDialog> {
  late final TextEditingController _controller;
  bool? _isPublic;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.program.tuitionAnnualFcfa?.toString() ?? '',
    );
    _isPublic = widget.program.isPublic;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.program.name),
      content: SizedBox(
        width: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cout annuel de la formation. Compare au budget saisi par '
              'l\'eleve pour le critere "budget".',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Cout annuel',
                suffixText: 'FCFA / an',
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Public')),
                ButtonSegment(value: false, label: Text('Prive')),
              ],
              selected: _isPublic == null ? <bool>{} : {_isPublic!},
              emptySelectionAllowed: true,
              onSelectionChanged: (sel) =>
                  setState(() => _isPublic = sel.isEmpty ? null : sel.first),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            final tuition = int.tryParse(_controller.text.trim());
            Navigator.pop(context, (tuition: tuition, isPublic: _isPublic));
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
