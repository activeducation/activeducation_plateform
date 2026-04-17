import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import 'brand_panel.dart';
import 'login_form.dart';

class WideLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;

  const WideLayout({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Brand Panel (gauche) ──
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
            child: const SafeArea(child: BrandPanel()),
          ),
        ),
        // ── Form Panel (droite) ──
        Expanded(
          flex: 4,
          child: Container(
            color: AppColors.background,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: LoginForm(
                      formKey: formKey,
                      emailController: emailController,
                      passwordController: passwordController,
                      obscurePassword: obscurePassword,
                      onTogglePassword: onTogglePassword,
                      onLogin: onLogin,
                      isWide: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
