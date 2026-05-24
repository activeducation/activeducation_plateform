import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/di/injection_container.dart';

class SchoolShellLayout extends StatelessWidget {
  final Widget child;

  const SchoolShellLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final tokenStorage = getIt<TokenStorage>();
    final schoolName = tokenStorage.schoolName ?? 'Mon École';
    final userName = tokenStorage.userName ?? 'Admin';
    final currentPath = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 260,
            color: AppColors.primary,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.school_rounded, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              schoolName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              'Espace École',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _buildNavItem(context, '/school-portal/dashboard', 'Dashboard', Icons.dashboard_rounded, currentPath),
                      _buildNavItem(context, '/school-portal/courses', 'Cours', Icons.school_rounded, currentPath),
                      _buildNavItem(context, '/school-portal/profile', 'Profil', Icons.person_rounded, currentPath),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white24,
                        child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'A', style: const TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(userName, style: const TextStyle(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis),
                            const Text('Administrateur', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
                        onPressed: () async {
                          await tokenStorage.clear();
                          if (context.mounted) context.go('/school-portal/login');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String path, String label, IconData icon, String currentPath) {
    final isActive = currentPath.startsWith(path);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isActive ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.go(path),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: Colors.white70, size: 22),
                const SizedBox(width: 12),
                Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}