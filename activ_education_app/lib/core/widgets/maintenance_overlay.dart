import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../di/injection_container.dart';

class MaintenanceOverlay extends StatefulWidget {
  final Widget child;

  const MaintenanceOverlay({super.key, required this.child});

  @override
  State<MaintenanceOverlay> createState() => _MaintenanceOverlayState();
}

class _MaintenanceOverlayState extends State<MaintenanceOverlay> {
  bool _checking = true;
  bool _maintenanceMode = false;

  @override
  void initState() {
    super.initState();
    _checkMaintenance();
  }

  Future<void> _checkMaintenance() async {
    try {
      final dio = getIt<Dio>(instanceName: 'apiClient');
      final response = await dio.get(ApiEndpoints.publicSettings);
      final data = response.data as Map<String, dynamic>?;
      final maintenance = data?['maintenance_mode'] ?? false;
      if (mounted) {
        setState(() {
          _maintenanceMode = maintenance == true;
          _checking = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_maintenanceMode) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.construction_rounded,
                  size: 72,
                  color: AppColors.warning,
                ),
                const SizedBox(height: 24),
                Text(
                  'Maintenance en cours',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'L\'application est temporairement indisponible. Veuillez réessayer plus tard.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
