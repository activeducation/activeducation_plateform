import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/buttons/gradient_button.dart';
import '../bloc/auth_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  String _password = '';

  bool get _hasMinLength => _password.length >= 8;
  bool get _hasUppercase => _password.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => _password.contains(RegExp(r'[a-z]'));
  bool get _hasDigit => _password.contains(RegExp(r'[0-9]'));
  bool get _hasSpecialChar =>
      _password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\/~`]'));
  bool get _isPasswordValid =>
      _hasMinLength && _hasUppercase && _hasLowercase && _hasDigit && _hasSpecialChar;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() => _password = _passwordController.text);
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez accepter les conditions d\'utilisation'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthRegisterRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
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
      labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
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
                  _buildHeader(),
                  const SizedBox(height: 28),
                  _buildNameFields(),
                  const SizedBox(height: 14),
                  _buildEmailField(),
                  const SizedBox(height: 14),
                  _buildPasswordField(),
                  if (_password.isNotEmpty && !_isPasswordValid) ...[
                    const SizedBox(height: 10),
                    _buildPasswordChecklist(),
                  ],
                  const SizedBox(height: 14),
                  _buildConfirmPasswordField(),
                  const SizedBox(height: 14),
                  _buildTermsCheckbox(),
                  const SizedBox(height: 24),
                  _buildRegisterButton(),
                  const SizedBox(height: 20),
                  _buildLoginLink(),
                  const SizedBox(height: 24),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Créer un compte',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Rejoignez ActivEducation pour découvrir votre avenir',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildNameFields() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _firstNameController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
            decoration: _inputDecoration(
              label: 'Prénom',
              prefixIcon: const Icon(Icons.person_outline,
                  color: AppColors.textSecondary, size: 20),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Requis';
              if (value.length < 2) return 'Min 2 caractères';
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _lastNameController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
            decoration: _inputDecoration(label: 'Nom'),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Requis';
              if (value.length < 2) return 'Min 2 caractères';
              return null;
            },
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
        prefixIcon: const Icon(Icons.email_outlined,
            color: AppColors.textSecondary, size: 20),
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
      textInputAction: TextInputAction.next,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: _inputDecoration(
        label: 'Mot de passe',
        hint: 'Min 8 caractères',
        prefixIcon: const Icon(Icons.lock_outline,
            color: AppColors.textSecondary, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Veuillez entrer un mot de passe';
        if (!_isPasswordValid) return 'Veuillez remplir toutes les conditions';
        return null;
      },
    );
  }

  Widget _buildPasswordChecklist() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isPasswordValid ? AppColors.successLight : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isPasswordValid
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCheckItem('Au moins 8 caractères', _hasMinLength),
          const SizedBox(height: 5),
          _buildCheckItem('Une lettre majuscule (A-Z)', _hasUppercase),
          const SizedBox(height: 5),
          _buildCheckItem('Une lettre minuscule (a-z)', _hasLowercase),
          const SizedBox(height: 5),
          _buildCheckItem('Un chiffre (0-9)', _hasDigit),
          const SizedBox(height: 5),
          _buildCheckItem('Un caractère spécial (!@#%&*...)', _hasSpecialChar),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String label, bool isMet) {
    return Row(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            key: ValueKey(isMet),
            size: 18,
            color: isMet ? AppColors.success : AppColors.textTertiary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isMet ? AppColors.successDark : AppColors.textSecondary,
            fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _onRegister(),
      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: _inputDecoration(
        label: 'Confirmer le mot de passe',
        prefixIcon: const Icon(Icons.lock_outline,
            color: AppColors.textSecondary, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onPressed: () =>
              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Veuillez confirmer le mot de passe';
        if (value != _passwordController.text) return 'Les mots de passe ne correspondent pas';
        return null;
      },
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _acceptTerms,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (value) => setState(() => _acceptTerms = value ?? false),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _acceptTerms = !_acceptTerms),
            child: RichText(
              text: TextSpan(
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                children: [
                  const TextSpan(text: 'J\'accepte les '),
                  TextSpan(
                    text: 'conditions d\'utilisation',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ' et la '),
                  TextSpan(
                    text: 'politique de confidentialité',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
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
                text: 'Créer mon compte',
                onPressed: _onRegister,
                showArrow: false,
              );
      },
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Déjà un compte ? ',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed: () => context.pop(),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: Text(
            'Se connecter',
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
