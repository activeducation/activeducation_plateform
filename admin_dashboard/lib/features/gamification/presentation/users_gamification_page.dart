import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/feedback/admin_snackbar.dart';
import '../../../shared/widgets/dialogs/confirm_dialog.dart';

class UsersGamificationPage extends StatefulWidget {
  const UsersGamificationPage({super.key});

  @override
  State<UsersGamificationPage> createState() => _UsersGamificationPageState();
}

class _UsersGamificationPageState extends State<UsersGamificationPage> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  int _total = 0;
  int _page = 1;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final api = getIt<ApiClient>();
      final params = {'page': '$_page', 'per_page': '50'};
      if (_searchCtrl.text.isNotEmpty) params['search'] = _searchCtrl.text;
      final response = await api.get(ApiEndpoints.adminGamificationUsers, queryParameters: params);
      final data = response.data as Map<String, dynamic>;
      setState(() {
        _users = List.from(data['items'] ?? []);
        _total = data['total'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _awardXp(Map<String, dynamic> user) async {
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController(text: 'Attribution manuelle');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Attribuer XP à ${user['full_name'] ?? user['email']}'),
        content: SizedBox(
          width: 400,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Montant XP *'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Motif'), maxLines: 2),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Attribuer')),
        ],
      ),
    );

    if (result != true || amountCtrl.text.isEmpty) return;

    try {
      final api = getIt<ApiClient>();
      await api.post(ApiEndpoints.adminGamificationUserAwardXp(user['id']), data: {
        'amount': int.tryParse(amountCtrl.text) ?? 0,
        'reason': reasonCtrl.text,
      });
      if (mounted) {
        AdminSnackbar.success(context, '+${amountCtrl.text} XP attribués');
        _load();
      }
    } catch (e) {
      if (mounted) AdminSnackbar.error(context, 'Erreur');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('XP & Niveaux'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
      ]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  labelText: 'Rechercher par nom ou email',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchCtrl.clear(); _load(); })
                      : null,
                ),
                onChanged: (_) => _load(),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('$_total utilisateurs', style: AppTypography.subtitle),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? const Center(child: Text('Aucun utilisateur'))
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (_, i) {
                        final user = _users[i];
                        final xp = user['total_xp'] ?? 0;
                        final level = user['current_level'] ?? 1;
                        final streak = user['current_streak'] ?? 0;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: Text('$level', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            ),
                            title: Text(user['full_name'] ?? user['email'] ?? ''),
                            subtitle: Text('${user['email'] ?? ''}'),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text('$xp XP', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.xpBar)),
                                Text('Niv. $level · Séquence: $streak', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ]),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: AppColors.primary),
                                tooltip: 'Attribuer XP',
                                onPressed: () => _awardXp(user),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}
