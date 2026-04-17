import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/school_model.dart';
import 'contact_item.dart';

class ContactTab extends StatelessWidget {
  final SchoolDetail school;

  const ContactTab({super.key, required this.school});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Coordonnees',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (school.address != null)
            ContactItem(
              icon: Iconsax.location,
              label: 'Adresse',
              value: school.address!,
              onTap: null,
            ),
          if (school.phone != null)
            ContactItem(
              icon: Iconsax.call,
              label: 'Telephone',
              value: school.phone!,
              onTap: () => launchUrl(Uri.parse('tel:${school.phone}')),
            ),
          if (school.email != null)
            ContactItem(
              icon: Iconsax.sms,
              label: 'Email',
              value: school.email!,
              onTap: () => launchUrl(Uri.parse('mailto:${school.email}')),
            ),
          if (school.website != null)
            ContactItem(
              icon: Iconsax.global,
              label: 'Site web',
              value: school.website!,
              onTap: () => launchUrl(
                Uri.parse(school.website!),
                mode: LaunchMode.externalApplication,
              ),
            ),
          if (school.address == null &&
              school.phone == null &&
              school.email == null &&
              school.website == null)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  Icon(
                    Iconsax.info_circle,
                    size: 48,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Aucune information de contact disponible',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
