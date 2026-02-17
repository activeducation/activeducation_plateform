import 'package:flutter/material.dart';
import 'core/theme/admin_theme.dart';
import 'router/admin_router.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = createAdminRouter();

    return MaterialApp.router(
      title: 'ActivEducation Admin',
      theme: AdminTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
