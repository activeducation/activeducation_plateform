import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/auth/token_storage.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/injection_container.dart';
import '../../core/theme/theme_cubit.dart';

/// Pages de detail plein ecran : le dock est masque pour ne pas recouvrir
/// leurs actions fixes en bas (inscription, completion de lecon, examen).
const List<String> _dockHiddenRoutePrefixes = [
  '/elearning/course/',
  '/elearning/lesson/',
];

/// En dessous de cette largeur, le dock passe en mode compact : cellules de
/// largeur egale qui tiennent dans l'ecran (sinon ~515 px deborde sur mobile).
const double _compactDockBreakpoint = 600;
const double _compactDockSideMargin = 16;

/// Shell de navigation principal (Refonte Bento & Dock)
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
      icon: Iconsax.home_2,
      activeIcon: Iconsax.home_25,
      label: 'Accueil',
      route: '/home',
    ),
    _NavItemData(
      icon: Iconsax.map_1,
      activeIcon: Iconsax.map5,
      label: 'Orientation',
      route: '/orientation',
    ),
    // video_play5 (0x641) et teacher5 (0x604) ont des codepoints dans le bloc
    // Unicode arabe : le rendu web les affiche vides. On garde l'icone contour,
    // l'etat actif reste signale par la couleur, le fond et le point.
    _NavItemData(
      icon: Iconsax.video_play,
      activeIcon: Iconsax.video_play,
      label: 'Cours',
      route: '/elearning',
    ),
    _NavItemData(
      icon: Iconsax.teacher,
      activeIcon: Iconsax.teacher,
      label: 'Mentors',
      route: '/mentors',
    ),
    _NavItemData(
      icon: Iconsax.buildings,
      activeIcon: Iconsax.buildings5,
      label: 'Écoles',
      route: '/schools',
    ),
    _NavItemData(
      icon: Iconsax.profile_circle,
      activeIcon: Iconsax.profile_circle5,
      label: 'Profil',
      route: '/profile',
    ),
  ];

  static const _partnerNavItem = _NavItemData(
    icon: Iconsax.people,
    activeIcon: Iconsax.people5,
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

    final hideDock =
        _dockHiddenRoutePrefixes.any((prefix) => location.startsWith(prefix));
    final isDarkMode = context.watch<ThemeCubit>().state == ThemeMode.dark;

    return Scaffold(
      extendBody: true, // Très important pour que le dock flotte sur le contenu
      body: Stack(
        children: [
          // Le contenu principal
          Positioned.fill(
            child: widget.child,
          ),

          // Le Dock Flottant
          if (!hideDock)
            Positioned(
              left: 0,
              right: 0,
              bottom: 24, // Flottant au-dessus du bas
              child: SafeArea(
                child: Center(
                  child: _FloatingDock(
                    currentIndex: _currentIndex,
                    navItems: _navItems,
                    isDarkMode: isDarkMode,
                    onTap: (index, route) {
                      setState(() => _currentIndex = index);
                      context.go(route);
                    },
                    onToggleTheme: () => context.read<ThemeCubit>().toggleTheme(),
                    onAida: () => context.push('/chat'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Floating Dock (Style VisionOS / iPad) ──────────────────────────────────

class _FloatingDock extends StatelessWidget {
  final int currentIndex;
  final List<_NavItemData> navItems;
  final bool isDarkMode;
  final void Function(int index, String route) onTap;
  final VoidCallback onToggleTheme;
  final VoidCallback onAida;

  const _FloatingDock({
    required this.currentIndex,
    required this.navItems,
    required this.isDarkMode,
    required this.onTap,
    required this.onToggleTheme,
    required this.onAida,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < _compactDockBreakpoint;

    // En compact, chaque action occupe une cellule de largeur egale ;
    // FittedBox reduit l'icone sur les ecrans tres etroits (< 360 px).
    Widget cell(Widget child) => compact
        ? Expanded(
            child: Center(
              child: FittedBox(fit: BoxFit.scaleDown, child: child),
            ),
          )
        : child;

    final dock = ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 6, vertical: 8)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.black.withOpacity(0.5)
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.1),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
            children: [
              // Logo simple ou icône de menu (optionnel)

              // Les items de navigation
              ...navItems.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                return cell(_DockIcon(
                  item: item,
                  isActive: currentIndex == i,
                  isDarkMode: isDarkMode,
                  compact: compact,
                  onTap: () => onTap(i, item.route),
                ));
              }),

              // Séparateur vertical
              Container(
                width: 1.5,
                height: compact ? 24 : 32,
                margin: EdgeInsets.symmetric(horizontal: compact ? 4 : 8),
                color: isDarkMode
                    ? Colors.white.withOpacity(0.15)
                    : Colors.black.withOpacity(0.1),
              ),

              // AÏDA bouton spécial (Glow)
              cell(_DockIconAida(
                isDarkMode: isDarkMode,
                compact: compact,
                onTap: onAida,
              )),

              if (!compact) const SizedBox(width: 8),

              // Thème Toggle
              cell(_DockIconButton(
                icon: isDarkMode ? Iconsax.sun_1 : Iconsax.moon,
                isDarkMode: isDarkMode,
                compact: compact,
                onTap: onToggleTheme,
              )),
            ],
          ),
        ),
      ),
    );

    return compact
        ? SizedBox(
            width: screenWidth - 2 * _compactDockSideMargin,
            child: dock,
          )
        : dock;
  }
}

class _DockIcon extends StatefulWidget {
  final _NavItemData item;
  final bool isActive;
  final bool isDarkMode;
  final bool compact;
  final VoidCallback onTap;

  const _DockIcon({
    required this.item,
    required this.isActive,
    required this.isDarkMode,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_DockIcon> createState() => _DockIconState();
}

class _DockIconState extends State<_DockIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorActive = widget.isDarkMode ? AppColors.primaryLight : AppColors.primary;
    final colorInactive = widget.isDarkMode ? Colors.white70 : AppColors.textSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          margin: widget.compact
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 4),
          padding: EdgeInsets.all(widget.compact ? 8 : 12),
          transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: widget.isActive
                ? (widget.isDarkMode ? colorActive.withOpacity(0.2) : colorActive.withOpacity(0.1))
                : (_hovered
                    ? (widget.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05))
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isActive ? widget.item.activeIcon : widget.item.icon,
                color: widget.isActive ? colorActive : colorInactive,
                size: widget.compact
                    ? 22
                    : (widget.isActive || _hovered ? 28 : 24),
              ),
              if (widget.isActive)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorActive,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockIconAida extends StatefulWidget {
  final bool isDarkMode;
  final bool compact;
  final VoidCallback onTap;

  const _DockIconAida({
    required this.isDarkMode,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_DockIconAida> createState() => _DockIconAidaState();
}

class _DockIconAidaState extends State<_DockIconAida> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          margin: widget.compact
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 4),
          padding: EdgeInsets.all(widget.compact ? 8 : 12),
          transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: _hovered ? AppColors.glowShadow : AppColors.primaryShadow,
          ),
          child: Icon(
            Icons.smart_toy_rounded,
            color: Colors.white,
            size: widget.compact ? 22 : 26,
          ),
        ),
      ),
    );
  }
}

class _DockIconButton extends StatefulWidget {
  final IconData icon;
  final bool isDarkMode;
  final bool compact;
  final VoidCallback onTap;

  const _DockIconButton({
    required this.icon,
    required this.isDarkMode,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_DockIconButton> createState() => _DockIconButtonState();
}

class _DockIconButtonState extends State<_DockIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isDarkMode ? Colors.white70 : AppColors.textSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: widget.compact
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 4),
          padding: EdgeInsets.all(widget.compact ? 8 : 12),
          decoration: BoxDecoration(
            color: _hovered
                ? (widget.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05))
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.icon,
            color: color,
            size: widget.compact ? 22 : 24,
          ),
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
