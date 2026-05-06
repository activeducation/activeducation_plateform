import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../bloc/auth_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  // Master controller for the reveal sequence
  late AnimationController _revealController;
  // Infinite pulse controller for glow ring
  late AnimationController _pulseController;
  // Infinite rotate controller for orbit ring
  late AnimationController _orbitController;
  // Infinite shimmer controller for the loading bar
  late AnimationController _shimmerController;
  // Floating particles controller
  late AnimationController _particleController;

  // — Reveal animations —
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _glowOpacity;
  late Animation<double> _textFade;
  late Animation<double> _textSlide;
  late Animation<double> _taglineFade;
  late Animation<double> _barFade;

  // — Continuous animations —
  late Animation<double> _pulse;
  late Animation<double> _orbit;
  late Animation<double> _shimmer;
  late Animation<double> _particles;

  @override
  void initState() {
    super.initState();

    // ── Reveal (1 600 ms, plays once) ──────────────────────────
    _revealController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.70, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
      ),
    );
    _glowOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
      ),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
      ),
    );
    _textSlide = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.45, 0.80, curve: Curves.easeOut),
      ),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.60, 0.88, curve: Curves.easeOut),
      ),
    );
    _barFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.78, 1.0, curve: Curves.easeOut),
      ),
    );

    // ── Pulse glow ring (2 s, repeats) ──────────────────────────
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // ── Orbit ring (8 s, repeats) ────────────────────────────────
    _orbitController = AnimationController(
      duration: const Duration(milliseconds: 8000),
      vsync: this,
    )..repeat();
    _orbit = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      _orbitController,
    );

    // ── Shimmer bar (1.8 s, repeats) ────────────────────────────
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();
    _shimmer = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // ── Floating particles (6 s, repeats) ────────────────────────
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 6000),
      vsync: this,
    )..repeat();
    _particles = Tween<double>(begin: 0.0, end: 1.0).animate(
      _particleController,
    );

    _revealController.forward();
  }

  @override
  void dispose() {
    _revealController.dispose();
    _pulseController.dispose();
    _orbitController.dispose();
    _shimmerController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated ||
            state is AuthUnauthenticated ||
            state is AuthError) {
          context.go('/home');
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF030812),
                Color(0xFF060E1E),
                Color(0xFF0B1C3C),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // ── Ambient background orbs ──────────────────────
              _buildAmbientOrb(
                top: -120,
                right: -80,
                size: 340,
                color: AppColors.primary.withValues(alpha: 0.14),
              ),
              _buildAmbientOrb(
                bottom: -140,
                left: -100,
                size: 380,
                color: AppColors.secondary.withValues(alpha: 0.07),
              ),
              _buildAmbientOrb(
                top: 160,
                left: -60,
                size: 200,
                color: AppColors.primaryLight.withValues(alpha: 0.06),
              ),

              // ── Floating particles ───────────────────────────
              AnimatedBuilder(
                animation: _particles,
                builder: (context, _) => CustomPaint(
                  painter: _ParticlePainter(_particles.value),
                  size: MediaQuery.of(context).size,
                ),
              ),

              // ── Main content ─────────────────────────────────
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with glow + orbit ring
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: _buildLogo(),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // App name
                    AnimatedBuilder(
                      animation: _revealController,
                      builder: (context, child) => Opacity(
                        opacity: _textFade.value,
                        child: Transform.translate(
                          offset: Offset(0, _textSlide.value),
                          child: child,
                        ),
                      ),
                      child: _buildAppName(),
                    ),

                    const SizedBox(height: 12),

                    // Tagline
                    FadeTransition(
                      opacity: _taglineFade,
                      child: _buildTagline(),
                    ),

                    const SizedBox(height: 64),

                    // Shimmer loading bar
                    FadeTransition(
                      opacity: _barFade,
                      child: _buildShimmerBar(),
                    ),

                    const SizedBox(height: 16),

                    FadeTransition(
                      opacity: _barFade,
                      child: Text(
                        'Chargement…',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.darkTextMuted,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Logo: glow ring + orbit dot + icon
  // ────────────────────────────────────────────────────────────────
  Widget _buildLogo() {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulsing glow halo
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) => Container(
              width: 154,
              height: 154,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: _pulse.value * 0.30),
                    blurRadius: 56,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),

          // Rotating orbit ring with a dot
          AnimatedBuilder(
            animation: _orbit,
            builder: (context, _) {
              return FadeTransition(
                opacity: _glowOpacity,
                child: CustomPaint(
                  painter: _OrbitPainter(_orbit.value),
                  size: const Size(152, 152),
                ),
              );
            },
          ),

          // Subtle translucent ring
          FadeTransition(
            opacity: _glowOpacity,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.20),
                  width: 1.5,
                ),
              ),
            ),
          ),

          // Logo card
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryLight, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.55),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: AppColors.primaryLight.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(-4, -4),
                ),
              ],
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 50,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // App name with gradient text simulation
  // ────────────────────────────────────────────────────────────────
  Widget _buildAppName() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [AppColors.darkTextPrimary, Color(0xFFE0EEFF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bounds),
      child: Text(
        'ActivEducation',
        style: AppTypography.heroDisplay.copyWith(
          fontSize: 34,
          letterSpacing: -0.8,
          fontWeight: FontWeight.w800,
          color: Colors.white, // masked by shader
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Italic tagline with amber dot accent
  // ────────────────────────────────────────────────────────────────
  Widget _buildTagline() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Découvrez votre voie, jouez votre avenir.',
          style: AppTypography.heroSubtitle.copyWith(
            color: AppColors.darkTextSecondary,
            fontStyle: FontStyle.italic,
            fontSize: 13,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Animated shimmer loading bar
  // ────────────────────────────────────────────────────────────────
  Widget _buildShimmerBar() {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return Container(
          width: 180,
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: AppColors.darkSurface3,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment(_shimmer.value - 1, 0),
                end: Alignment(_shimmer.value, 0),
                colors: [
                  Colors.transparent,
                  AppColors.primary.withValues(alpha: 0.9),
                  AppColors.primaryLight,
                  AppColors.secondary.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
              ).createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: Container(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Helper: ambient orb
  // ────────────────────────────────────────────────────────────────
  Widget _buildAmbientOrb({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Orbit ring painter — draws a dashed ring + a bright dot
// ────────────────────────────────────────────────────────────────────
class _OrbitPainter extends CustomPainter {
  final double angle;
  _OrbitPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Dashed ring
    final dashPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const dashCount = 28;
    const dashAngle = 2 * math.pi / dashCount;
    for (int i = 0; i < dashCount; i++) {
      final start = i * dashAngle;
      final end = start + dashAngle * 0.5;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        end - start,
        false,
        dashPaint,
      );
    }

    // Orbiting dot
    final dotX = center.dx + radius * math.cos(angle);
    final dotY = center.dy + radius * math.sin(angle);
    canvas.drawCircle(
      Offset(dotX, dotY),
      5,
      Paint()
        ..color = AppColors.secondary
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      Offset(dotX, dotY),
      3.5,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.angle != angle;
}

// ────────────────────────────────────────────────────────────────────
// Floating particles painter
// ────────────────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double progress;

  static const _particleData = [
    // [xFrac, yFrac, size, speed, phase]
    [0.15, 0.20, 3.0, 0.8, 0.0],
    [0.85, 0.15, 2.0, 1.2, 0.3],
    [0.08, 0.65, 2.5, 0.6, 0.6],
    [0.92, 0.72, 1.8, 1.0, 0.1],
    [0.45, 0.10, 2.2, 0.9, 0.8],
    [0.72, 0.85, 3.0, 0.7, 0.4],
    [0.30, 0.90, 1.5, 1.3, 0.2],
    [0.60, 0.05, 2.0, 1.1, 0.9],
    [0.05, 0.40, 2.8, 0.5, 0.5],
    [0.95, 0.45, 1.6, 1.4, 0.7],
    [0.50, 0.95, 2.0, 0.8, 0.15],
    [0.25, 0.50, 1.4, 1.0, 0.65],
  ];

  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particleData) {
      final xFrac = p[0];
      final yFrac = p[1];
      final r = p[2];
      final speed = p[3];
      final phase = p[4];

      final t = (progress * speed + phase) % 1.0;
      final opacity = (math.sin(t * 2 * math.pi) * 0.5 + 0.5) * 0.55 + 0.05;
      final floatY = math.sin(t * 2 * math.pi) * 12;

      final paint = Paint()
        ..color = (xFrac < 0.5 ? AppColors.primaryLight : AppColors.secondary)
            .withValues(alpha: opacity);

      canvas.drawCircle(
        Offset(size.width * xFrac, size.height * yFrac + floatY),
        r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
