import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/buttons/gradient_button.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      labelStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.textSecondary,
      ),
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.textTertiary,
      ),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/home');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildEmailField(),
                  const SizedBox(height: 14),
                  _buildPasswordField(),
                  const SizedBox(height: 6),
                  _buildForgotPassword(),
                  const SizedBox(height: 28),
                  _buildLoginButton(),
                  const SizedBox(height: 28),
                  _buildDivider(),
                  const SizedBox(height: 20),
                  _buildRegisterLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo.jpeg',
          width: 88,
          height: 88,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 20),
        Text(
          'Bienvenue',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 44,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Connectez-vous pour continuer',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: _inputDecoration(
        label: 'Email',
        hint: 'votre@email.com',
        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary, size: 20),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Veuillez entrer votre email';
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Veuillez entrer un email valide';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _onLogin(),
      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: _inputDecoration(
        label: 'Mot de passe',
        hint: '••••••••',
        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Veuillez entrer votre mot de passe';
        return null;
      },
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fonctionnalité à venir')),
          );
        },
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        ),
        child: Text(
          'Mot de passe oublié ?',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return isLoading
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              )
            : GradientButton(
                text: 'Se connecter',
                onPressed: _onLogin,
                showArrow: false,
              );
      },
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OU',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Pas encore de compte ? ',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed: () => context.push('/register'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: Text(
            'S\'inscrire',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
