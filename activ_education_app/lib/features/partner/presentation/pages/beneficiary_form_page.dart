import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_input_decoration.dart';
import '../bloc/partner_bloc.dart';

class BeneficiaryFormPage extends StatefulWidget {
  final String organizationId;
  final String? beneficiaryId;

  const BeneficiaryFormPage({
    super.key,
    required this.organizationId,
    this.beneficiaryId,
  });

  @override
  State<BeneficiaryFormPage> createState() => _BeneficiaryFormPageState();
}

class _BeneficiaryFormPageState extends State<BeneficiaryFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _placeOfBirthController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianPhoneController = TextEditingController();
  final _guardianRelationshipController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _dateOfBirth;
  String? _gender;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _placeOfBirthController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _guardianRelationshipController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _notesController.dispose();
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
          'Nouveau bénéficiaire',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BlocListener<PartnerBloc, PartnerState>(
        listener: (context, state) {
          if (state is PartnerBeneficiaryCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Bénéficiaire créé: ${state.beneficiary.dossierNumber}'),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop();
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
              _buildSectionTitle('Informations de l\'enfant'),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: AppInputDecoration.light(
                        label: 'Prénom',
                        hint: 'Prénom de l\'enfant',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le prénom est requis';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: AppInputDecoration.light(
                        label: 'Nom',
                        hint: 'Nom de l\'enfant',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le nom est requis';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildGenderDropdown(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _placeOfBirthController,
                decoration: AppInputDecoration.light(
                  label: 'Lieu de naissance',
                  hint: 'Ville/village de naissance',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle('Parents'),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _fatherNameController,
                decoration: AppInputDecoration.light(
                  label: 'Nom du père',
                  hint: 'Nom complet du père',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _motherNameController,
                decoration: AppInputDecoration.light(
                  label: 'Nom de la mère',
                  hint: 'Nom complet de la mère',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle('Tuteur légal'),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _guardianNameController,
                decoration: AppInputDecoration.light(
                  label: 'Nom du tuteur',
                  hint: 'Personne responsable',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _guardianPhoneController,
                      decoration: AppInputDecoration.light(
                        label: 'Téléphone',
                        hint: 'Numéro de téléphone',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _guardianRelationshipController,
                      decoration: AppInputDecoration.light(
                        label: 'Relation',
                        hint: 'Ex: Oncle, Tante',
                      ),
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
                  hint: 'Ville de résidence',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle('Notes'),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _notesController,
                decoration: AppInputDecoration.light(
                  label: 'Notes',
                  hint: 'Informations supplémentaires...',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: AppSpacing.xl),
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
                        'Créer le dossier',
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

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 10)),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() => _dateOfBirth = date);
        }
      },
      child: InputDecorator(
        decoration: AppInputDecoration.light(
          label: 'Date de naissance',
          hint: 'Sélectionner',
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _dateOfBirth != null
                  ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                  : 'Sélectionner',
              style: AppTypography.bodyMedium.copyWith(
                color: _dateOfBirth != null
                    ? AppColors.textPrimary
                    : AppColors.textTertiary,
              ),
            ),
            const Icon(Icons.calendar_today, size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return InputDecorator(
      decoration: AppInputDecoration.light(
        label: 'Genre',
        hint: 'Sélectionner',
      ),
      child: DropdownButton<String>(
        value: _gender,
        hint: const Text('Sélectionner'),
        isExpanded: true,
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(value: 'male', child: Text('Garçon')),
          DropdownMenuItem(value: 'female', child: Text('Fille')),
          DropdownMenuItem(value: 'other', child: Text('Autre')),
        ],
        onChanged: (value) => setState(() => _gender = value),
      ),
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    context.read<PartnerBloc>().add(PartnerCreateBeneficiary(
          organizationId: widget.organizationId,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          dateOfBirth: _dateOfBirth,
          gender: _gender,
          placeOfBirth: _placeOfBirthController.text.trim().isNotEmpty
              ? _placeOfBirthController.text.trim()
              : null,
          fatherName: _fatherNameController.text.trim().isNotEmpty
              ? _fatherNameController.text.trim()
              : null,
          motherName: _motherNameController.text.trim().isNotEmpty
              ? _motherNameController.text.trim()
              : null,
          guardianName: _guardianNameController.text.trim().isNotEmpty
              ? _guardianNameController.text.trim()
              : null,
          guardianPhone: _guardianPhoneController.text.trim().isNotEmpty
              ? _guardianPhoneController.text.trim()
              : null,
          guardianRelationship: _guardianRelationshipController.text.trim().isNotEmpty
              ? _guardianRelationshipController.text.trim()
              : null,
          address: _addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : null,
          city: _cityController.text.trim().isNotEmpty
              ? _cityController.text.trim()
              : null,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        ));
  }
}