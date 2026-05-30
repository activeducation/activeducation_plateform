import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_input_decoration.dart';
import '../bloc/partner_bloc.dart';

class CreateOrganizationPage extends StatefulWidget {
  const CreateOrganizationPage({super.key});

  @override
  State<CreateOrganizationPage> createState() => _CreateOrganizationPageState();
}

class _CreateOrganizationPageState extends State<CreateOrganizationPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  String _selectedType = 'cdej';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _contactPersonController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Créer une organisation',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BlocListener<PartnerBloc, PartnerState>(
        listener: (context, state) {
          if (state is PartnerOrganizationCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Organisation créée: ${state.organization.partnerCode}'),
                backgroundColor: AppColors.success,
              ),
            );
            context.push('/partner/organization/${state.organization.id}');
          } else if (state is PartnerError) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _buildSectionTitle('Type d\'organisation'),
              const SizedBox(height: AppSpacing.md),
              _buildTypeSelector(),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle('Informations générales'),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _nameController,
                decoration: AppInputDecoration.light(
                  label: 'Nom de l\'organisation',
                  hint: 'Ex: CDEJ de Lomé',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _descriptionController,
                decoration: AppInputDecoration.light(
                  label: 'Description',
                  hint: 'Brève description de l\'organisation',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle('Contact'),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _contactPersonController,
                decoration: AppInputDecoration.light(
                  label: 'Personne de contact',
                  hint: 'Nom de la personne responsable',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _contactEmailController,
                      decoration: AppInputDecoration.light(
                        label: 'Email',
                        hint: 'email@organisation.tg',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _contactPhoneController,
                      decoration: AppInputDecoration.light(
                        label: 'Téléphone',
                        hint: 'Numéro de téléphone',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle('Adresse'),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _addressController,
                decoration: AppInputDecoration.light(
                  label: 'Adresse',
                  hint: 'Rue, quartier',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _cityController,
                decoration: AppInputDecoration.light(
                  label: 'Ville',
                  hint: 'Ville',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.infoDark),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Une fois créée, vous deviendrez l\'administrateur de cette organisation et pourrez gérer les bénéficiaires.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.infoDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        'Créer l\'organisation',
                        style: AppTypography.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.titleSmall.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        _buildTypeOption('cdej', 'CDEJ', Icons.child_care),
        const SizedBox(width: AppSpacing.md),
        _buildTypeOption('ong', 'ONG', Icons.volunteer_activism),
        const SizedBox(width: AppSpacing.md),
        _buildTypeOption('school', 'École', Icons.school),
      ],
    );
  }

  Widget _buildTypeOption(String type, String label, IconData icon) {
    final isSelected = _selectedType == type;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedType = type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySurface : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    context.read<PartnerBloc>().add(PartnerCreateOrganization(
          name: _nameController.text.trim(),
          type: _selectedType,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          contactEmail: _contactEmailController.text.trim().isNotEmpty
              ? _contactEmailController.text.trim()
              : null,
          contactPhone: _contactPhoneController.text.trim().isNotEmpty
              ? _contactPhoneController.text.trim()
              : null,
          contactPerson: _contactPersonController.text.trim().isNotEmpty
              ? _contactPersonController.text.trim()
              : null,
          address: _addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : null,
          city: _cityController.text.trim().isNotEmpty
              ? _cityController.text.trim()
              : null,
        ));
  }
}