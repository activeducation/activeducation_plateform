import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../core/auth/token_storage.dart';

class SchoolProfilePage extends StatefulWidget {
  const SchoolProfilePage({super.key});

  @override
  State<SchoolProfilePage> createState() => _SchoolProfilePageState();
}

class _SchoolProfilePageState extends State<SchoolProfilePage> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final api = getIt<ApiClient>();
      final response = await api.get(ApiEndpoints.schoolProfile);
      setState(() {
        _profile = response.data as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokenStorage = getIt<TokenStorage>();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.contentPadding),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mon Profil', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
                CircleAvatar(radius: 50, backgroundColor: AppColors.primary.withValues(alpha: 0.1), child: Text(tokenStorage.userName?.isNotEmpty == true ? tokenStorage.userName![0].toUpperCase() : 'A', style: const TextStyle(fontSize: 36, color: AppColors.primary))),
                const SizedBox(height: 16),
                Text(tokenStorage.userName ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(tokenStorage.userEmail ?? '', style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)), child: const Text('Administrateur École', style: TextStyle(color: AppColors.primary))),
              ]))),
              const SizedBox(width: 24),
              Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (_profile?['school']?['cover_image_url'] != null && _profile!['school']!['cover_image_url'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _profile!['school']!['cover_image_url'],
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, s) => Container(
                          height: 150,
                          color: AppColors.surfaceVariant,
                          child: const Center(child: Icon(Icons.broken_image, color: AppColors.textMuted)),
                        ),
                      ),
                    ),
                  ),
                 const Text('Informations de l\'école', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (_profile?['school']?['logo_url'] != null && _profile!['school']!['logo_url'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Image.network(
                      _profile!['school']!['logo_url'],
                      height: 80,
                      errorBuilder: (_, e, s) => const Icon(Icons.school, size: 48),
                    ),
                  ),
                _buildInfoRow('Nom', _profile?['school']?['name'] ?? tokenStorage.schoolName ?? '-'),
                _buildInfoRow('Ville', _profile?['school']?['city'] ?? '-'),
                _buildInfoRow('Pays', _profile?['school']?['country'] ?? '-'),
                _buildInfoRow('Type', _profile?['school']?['type'] ?? '-'),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                const Text('Contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildInfoRow('Email', _profile?['user']?['email'] ?? tokenStorage.userEmail ?? '-'),
                _buildInfoRow('Poste', _profile?['user']?['position'] ?? '-'),
              ])))),
            ]),
        ]),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 100, child: Text(label, style: TextStyle(color: AppColors.textMuted))),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
    ]));
  }
}