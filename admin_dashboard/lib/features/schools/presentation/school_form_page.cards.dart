part of 'school_form_page.dart';

// Cartes du formulaire ecole, extraites de school_form_page.dart pour
// alleger le fichier principal. Meme librairie (part) => acces complet
// aux champs/methodes prives de _SchoolFormPageState.

extension _SchoolFormCards on _SchoolFormPageState {
  // =========================================================================
  // CARD: Informations generales
  // =========================================================================

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informations generales', style: AppTypography.heading3),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'etablissement *',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Le nom est requis' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: 'Type *'),
                    items: AdminConstants.schoolTypes
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(
                              AdminConstants.schoolTypeLabels[t] ?? t,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => refresh(() => _type = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cityCtrl,
                    decoration: const InputDecoration(labelText: 'Ville *'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'La ville est requise'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Adresse complete'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Telephone',
                      hintText: '+228 XX XX XX XX',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) {
                      if (v != null && v.isNotEmpty && !v.contains('@')) {
                        return 'Email invalide';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _websiteCtrl,
              decoration: const InputDecoration(
                labelText: 'Site web',
                hintText: 'https://...',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _foundingYearCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Annee de fondation',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        final year = int.tryParse(v);
                        if (year == null || year < 1800 || year > 2100) {
                          return 'Annee invalide';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _studentCountCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre d\'etudiants',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // CARD: Admission & Frais
  // =========================================================================

  Widget _buildAdmissionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admission & Frais', style: AppTypography.heading3),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tuitionRangeCtrl,
              decoration: const InputDecoration(
                labelText: 'Frais de scolarite',
                hintText: 'Ex: 500 000 - 1 200 000 FCFA/an',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _admissionReqCtrl,
              decoration: const InputDecoration(
                labelText: 'Conditions d\'admission',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // CARD: Options (switches)
  // =========================================================================

  Widget _buildOptionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Options', style: AppTypography.heading3),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Etablissement public'),
              subtitle: Text(
                _isPublic ? 'Publique' : 'Privee',
                style: AppTypography.bodySmall,
              ),
              value: _isPublic,
              onChanged: (v) => refresh(() => _isPublic = v),
            ),
            if (_isEditing)
              SwitchListTile(
                title: const Text('Actif'),
                subtitle: Text(
                  _isActive ? 'Visible dans l\'app' : 'Masque',
                  style: AppTypography.bodySmall,
                ),
                value: _isActive,
                onChanged: (v) => refresh(() => _isActive = v),
              ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // CARD: Images (logo + banniere)
  // =========================================================================

  Widget _buildImagesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Images', style: AppTypography.heading3),
            const SizedBox(height: 16),

            // Logo
            Text(
              'Logo',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildImageUpload(
              url: _logoUrl,
              isUploading: _isUploadingLogo,
              onUpload: () => _uploadImage(isLogo: true),
              onRemove: () => refresh(() => _logoUrl = null),
              height: 100,
            ),

            const SizedBox(height: 20),

            // Cover
            Text(
              'Banniere',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildImageUpload(
              url: _coverImageUrl,
              isUploading: _isUploadingCover,
              onUpload: () => _uploadImage(isLogo: false),
              onRemove: () => refresh(() => _coverImageUrl = null),
              height: 120,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUpload({
    String? url,
    required bool isUploading,
    required VoidCallback onUpload,
    required VoidCallback onRemove,
    double height = 100,
  }) {
    if (isUploading) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (url != null && url.isNotEmpty) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: height,
                color: AppColors.surfaceVariant,
                child: const Center(
                  child: Icon(Icons.broken_image, color: AppColors.textMuted),
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _miniIconButton(Icons.edit, onUpload),
                const SizedBox(width: 4),
                _miniIconButton(Icons.close, onRemove, color: AppColors.error),
              ],
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: onUpload,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.textMuted.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_upload_outlined, color: AppColors.textMuted),
              SizedBox(height: 4),
              Text(
                'Cliquer pour uploader',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniIconButton(
    IconData icon,
    VoidCallback onPressed, {
    Color? color,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: color ?? AppColors.textMuted),
        ),
      ),
    );
  }

  // =========================================================================
  // CARD: Accreditations
  // =========================================================================

  Widget _buildAccreditationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Accreditations', style: AppTypography.heading3),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => _addTag(isAccreditation: true),
                  tooltip: 'Ajouter',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_accreditations.isEmpty)
              Text('Aucune accreditation', style: AppTypography.bodySmall),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _accreditations
                  .map(
                    (a) => Chip(
                      label: Text(a),
                      onDeleted: () =>
                          refresh(() => _accreditations.remove(a)),
                      backgroundColor: AppColors.success.withValues(alpha: 0.1),
                      labelStyle: TextStyle(color: AppColors.success),
                      deleteIconColor: AppColors.success,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // CARD: Domaines de formation (programs_offered)
  // =========================================================================

  Widget _buildProgramsOfferedCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Domaines', style: AppTypography.heading3),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => _addTag(isAccreditation: false),
                  tooltip: 'Ajouter',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_programsOffered.isEmpty)
              Text('Aucun domaine', style: AppTypography.bodySmall),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _programsOffered
                  .map(
                    (p) => Chip(
                      label: Text(p),
                      onDeleted: () =>
                          refresh(() => _programsOffered.remove(p)),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // CARD: Filieres (programmes)
  // =========================================================================

  Widget _buildProgramsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Filieres (${_programs.length})',
                  style: AppTypography.heading3,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _addProgram,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Ajouter'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_programs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Aucune filiere. Cliquez sur "Ajouter" pour creer des filieres.',
                    style: AppTypography.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ..._programs.map((p) => _buildProgramTile(p)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramTile(Map<String, dynamic> program) {
    final levelLabel =
        AdminConstants.programLevelLabels[program['level']] ??
        program['level'] ??
        '';
    final duration = program['duration_years'];
    final subtitle = [
      if (levelLabel.isNotEmpty) levelLabel,
      if (duration != null) '$duration an${duration > 1 ? 's' : ''}',
    ].join(' - ');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(
        program['name'] ?? '',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: TextStyle(color: AppColors.primary, fontSize: 12),
            ),
          if (program['description'] != null &&
              (program['description'] as String).isNotEmpty)
            Text(
              program['description'],
              style: AppTypography.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: () => _editProgram(program),
            tooltip: 'Modifier',
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
            onPressed: () => _deleteProgram(program['id']),
            tooltip: 'Supprimer',
          ),
        ],
      ),
    );
  }
}
