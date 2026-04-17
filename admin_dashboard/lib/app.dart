import 'package:flutter/material.dart';
import 'core/theme/admin_theme.dart';
import 'router/admin_router.dart';

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  late final _router = createAdminRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ActivEducation Admin',
      theme: AdminTheme.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
