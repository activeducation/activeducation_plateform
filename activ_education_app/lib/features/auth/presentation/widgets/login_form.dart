import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_input_decoration.dart';
import '../../../../shared/widgets/buttons/gradient_button.dart';
import '../bloc/auth_bloc.dart';

class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final bool isWide;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onLogin,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isWide) ...[
            const SizedBox(height: 4),
          ] else ...[
            const SizedBox(height: 16),
          ],

          // Heading
          Text(
            'Connexion',
            style: AppTypography.displaySmall.copyWith(
              color: AppColors.textPrimary,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bienvenue ! Connectez-vous pour continuer.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 32),

          // Email
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: appInputDecoration(
              label: 'Adresse email',
              hint: 'vous@exemple.com',
              prefixIcon: const Padding(
                padding: EdgeInsets.all(14),
                child: Icon(
                  Icons.email_outlined,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre email';
              }
              if (!RegExp(
                r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,63}$',
              ).hasMatch(value)) {
                return 'Email invalide';
              }
              return null;
            },
          ),

          const SizedBox(height: 14),

          // Password
          TextFormField(
            controller: passwordController,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onLogin(),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: appInputDecoration(
              label: 'Mot de passe',
              hint: '••••••••',
              prefixIcon: const Padding(
                padding: EdgeInsets.all(14),
                child: Icon(
                  Icons.lock_outline,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
                onPressed: onTogglePassword,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre mot de passe';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Login button
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthLoading) {
                return const SizedBox(
                  height: 54,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                );
              }
              return GradientButton(
                text: 'Se connecter',
                onPressed: onLogin,
                showArrow: false,
              );
            },
          ),

          const SizedBox(height: 28),

          // Divider
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OU',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.border)),
            ],
          ),

          const SizedBox(height: 24),

          // Register link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Pas encore de compte ? ',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/register'),
                child: Text(
                  'S\'inscrire',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          if (isWide) const SizedBox(height: 16),
        ],
      ),
    );
  }
}
