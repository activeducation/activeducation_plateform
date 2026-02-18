import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/auth/token_storage.dart';
import '../../core/di/injection_container.dart';

class AdminShellLayout extends StatelessWidget {
  final Widget child;

  const AdminShellLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(),
          Expanded(
            child: Column(
              children: [
                _TopBar(),
                Expanded(
                  child: Container(
                    color: AppColors.background,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Sidebar
// ============================================================================

class _Sidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    final tokenStorage = getIt<TokenStorage>();

    return Container(
      width: AppSpacing.sidebarWidth,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.sidebarBg, Color(0xFF0D4FB5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Brand header
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/logo.jpeg',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ActivEducation',
                      style: AppTypography.heading3.copyWith(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    Text('Admin Dashboard',
                      style: TextStyle(
                        color: AppColors.sidebarTextMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(color: AppColors.sidebarDivider, height: 1),
          const SizedBox(height: 12),

          // Navigation
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _SidebarItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Dashboard',
                  path: '/dashboard',
                  currentPath: currentPath,
                ),
                _SidebarItem(
                  icon: Icons.people_rounded,
                  label: 'Utilisateurs',
                  path: '/users',
                  currentPath: currentPath,
                ),
                const _SidebarSection(label: 'CONTENU'),
                _SidebarItem(
                  icon: Icons.school_rounded,
                  label: 'Ecoles',
                  path: '/schools',
                  currentPath: currentPath,
                ),
                _SidebarItem(
                  icon: Icons.work_rounded,
                  label: 'Carrieres',
                  path: '/careers',
                  currentPath: currentPath,
                ),
                _SidebarItem(
                  icon: Icons.category_rounded,
                  label: 'Secteurs',
                  path: '/careers/sectors',
                  currentPath: currentPath,
                ),
                _SidebarItem(
                  icon: Icons.quiz_rounded,
                  label: 'Tests',
                  path: '/tests',
                  currentPath: currentPath,
                ),
                const _SidebarSection(label: 'ENGAGEMENT'),
                _SidebarItem(
                  icon: Icons.emoji_events_rounded,
                  label: 'Achievements',
                  path: '/gamification/achievements',
                  currentPath: currentPath,
                ),
                _SidebarItem(
                  icon: Icons.flag_rounded,
                  label: 'Challenges',
                  path: '/gamification/challenges',
                  currentPath: currentPath,
                ),
                _SidebarItem(
                  icon: Icons.person_search_rounded,
                  label: 'Mentors',
                  path: '/mentors',
                  currentPath: currentPath,
                ),
                const _SidebarSection(label: 'SYSTEME'),
                _SidebarItem(
                  icon: Icons.campaign_rounded,
                  label: 'Annonces',
                  path: '/announcements',
                  currentPath: currentPath,
                ),
                if (tokenStorage.isSuperAdmin) ...[
                  _SidebarItem(
                    icon: Icons.tune_rounded,
                    label: 'Parametres',
                    path: '/settings',
                    currentPath: currentPath,
                  ),
                  _SidebarItem(
                    icon: Icons.history_rounded,
                    label: 'Audit Log',
                    path: '/audit-log',
                    currentPath: currentPath,
                  ),
                ],
              ],
            ),
          ),

          // User profile / Logout
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.sidebarDivider)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              hoverColor: AppColors.sidebarItemHover,
              onTap: () async {
                await tokenStorage.clear();
                if (context.mounted) context.go('/login');
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.sidebarItemActive,
                      child: Text(
                        (tokenStorage.userName ?? tokenStorage.userEmail ?? 'A')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tokenStorage.userName ?? 'Admin',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            tokenStorage.userRole == 'super_admin' ? 'Super Admin' : 'Admin',
                            style: TextStyle(
                              color: AppColors.sidebarTextMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.logout_rounded, color: AppColors.sidebarTextMuted, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String path;
  final String currentPath;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.currentPath,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovering = false;

  bool get _isActive =>
      widget.currentPath == widget.path ||
      (widget.path != '/dashboard' && widget.currentPath.startsWith(widget.path));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _isActive
                ? AppColors.sidebarItemActive.withValues(alpha: 0.2)
                : _hovering
                    ? AppColors.sidebarItemHover
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: _isActive
                ? Border(left: BorderSide(color: AppColors.sidebarItemActive, width: 3))
                : null,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => context.go(widget.path),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    color: _isActive ? AppColors.sidebarItemActive : AppColors.sidebarTextMuted,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: _isActive
                          ? Colors.white
                          : _hovering
                              ? Colors.white
                              : AppColors.sidebarTextMuted,
                      fontSize: 13,
                      fontWeight: _isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (_isActive) ...[
                    const Spacer(),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.sidebarItemActive,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  final String label;
  const _SidebarSection({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8, left: 12),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.sidebarTextMuted.withValues(alpha: 0.6),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// ============================================================================
// Top Bar
// ============================================================================

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).matchedLocation;
    final pageTitle = _getPageTitle(path);
    final tokenStorage = getIt<TokenStorage>();

    return Container(
      height: AppSpacing.topBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          // Page title
          Text(pageTitle, style: AppTypography.heading3),
          const Spacer(),

          // Search placeholder
          Container(
            width: 220,
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text('Rechercher...', style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                )),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Notification bell
          _TopBarIconButton(
            icon: Icons.notifications_none_rounded,
            onTap: () {},
          ),
          const SizedBox(width: 4),

          // Refresh
          _TopBarIconButton(
            icon: Icons.refresh_rounded,
            onTap: () {
              // Trigger page reload by navigating to same path
              context.go(path);
            },
          ),
          const SizedBox(width: 16),

          // User chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    (tokenStorage.userName ?? tokenStorage.userEmail ?? 'A')
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  tokenStorage.userName ?? tokenStorage.userEmail ?? 'Admin',
                  style: AppTypography.body.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle(String path) {
    if (path.startsWith('/dashboard')) return 'Dashboard';
    if (path.startsWith('/users')) return 'Utilisateurs';
    if (path.startsWith('/schools')) return 'Ecoles';
    if (path.startsWith('/careers/sectors')) return 'Secteurs';
    if (path.startsWith('/careers')) return 'Carrieres';
    if (path.startsWith('/tests')) return 'Tests d\'orientation';
    if (path.startsWith('/gamification/achievements')) return 'Achievements';
    if (path.startsWith('/gamification/challenges')) return 'Challenges';
    if (path.startsWith('/mentors')) return 'Mentors';
    if (path.startsWith('/announcements')) return 'Annonces';
    if (path.startsWith('/settings')) return 'Parametres';
    if (path.startsWith('/audit-log')) return 'Journal d\'audit';
    return 'Dashboard';
  }
}

class _TopBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopBarIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
