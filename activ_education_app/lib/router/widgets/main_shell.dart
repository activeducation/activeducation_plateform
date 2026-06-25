import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/token_storage.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/di/injection_container.dart';

/// Shell de navigation principal partagé par toutes les routes authentifiées.
///
/// Affiche une sidebar verticale sur desktop (>= 768px) et une bottom bar +
/// FAB AÏDA sur mobile. Le contenu de la route active est injecté via [child]
/// par le `ShellRoute` de [AppRouter].
///
/// Extrait de app_router.dart (refacto 2026-05) pour séparer la config de
/// routing (qui doit rester centralisée et lisible) de l'UI du shell.
class MainShellWrapper extends StatefulWidget {
  final Widget child;
  const MainShellWrapper({super.key, required this.child});

  @override
  State<MainShellWrapper> createState() => _MainShellWrapperState();
}

class _MainShellWrapperState extends State<MainShellWrapper> {
  int _currentIndex = 0;
  late List<_NavItemData> _navItems;

  static const _defaultNavItems = [
    _NavItemData(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Accueil',
      route: '/home',
    ),
    _NavItemData(
      icon: Icons.school_outlined,
      activeIcon: Icons.school_rounded,
      label: 'Orientation',
      route: '/orientation',
    ),
    _NavItemData(
      icon: Icons.play_lesson_outlined,
      activeIcon: Icons.play_lesson_rounded,
      label: 'Cours',
      route: '/elearning',
    ),
    _NavItemData(
      icon: Icons.people_outline,
      activeIcon: Icons.people_rounded,
      label: 'Mentors',
      route: '/mentors',
    ),
    _NavItemData(
      icon: Icons.business_outlined,
      activeIcon: Icons.business_rounded,
      label: 'Écoles',
      route: '/schools',
    ),
    _NavItemData(
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
      label: 'Profil',
      route: '/profile',
    ),
  ];

  static const _partnerNavItem = _NavItemData(
    icon: Icons.groups_outlined,
    activeIcon: Icons.groups_rounded,
    label: 'Partenaire',
    route: '/partner/organization/create',
  );

  @override
  void initState() {
    super.initState();
    _navItems = List.from(_defaultNavItems);
    _initNav();
  }

  Future<void> _initNav() async {
    final tokenStorage = getIt<TokenStorage>();
    final role = await tokenStorage.getUserRole();
    final hasPartnerAccess = role != null && ['partner_admin', 'admin', 'super_admin'].contains(role);
    if (hasPartnerAccess && mounted) {
      setState(() => _navItems.insert(_navItems.length - 1, _partnerNavItem));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].route)) {
        _currentIndex = i;
        break;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: widget.child,
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        navItems: _navItems,
        onTap: (index, route) {
          setState(() => _currentIndex = index);
          context.go(route);
        },
      ),
      floatingActionButton: _AidaFab(onTap: () => context.push('/chat')),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// ─── Bottom Navigation ──────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItemData> navItems;
  final void Function(int index, String route) onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.navItems,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return _MobileNavItem(
                item: item,
                isActive: currentIndex == i,
                onTap: () => onTap(i, item.route),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  final _NavItemData item;
  final bool isActive;
  final VoidCallback onTap;

  const _MobileNavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primarySurface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: isActive
                      ? AppColors.primaryDark
                      : AppColors.textTertiary,
                  size: 22,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                style: AppTypography.navLabel.copyWith(
                  color: isActive
                      ? AppColors.primaryDark
                      : AppColors.textTertiary,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 10.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── AÏDA FAB ───────────────────────────────────────────────────────────────

class _AidaFab extends StatelessWidget {
  final VoidCallback onTap;
  const _AidaFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: 'aida_fab',
        onPressed: onTap,
        backgroundColor: AppColors.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.smart_toy_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

// ─── Data model ─────────────────────────────────────────────────────────────

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}
