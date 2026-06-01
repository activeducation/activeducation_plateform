import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/di/injection_container.dart';
import 'core/theme/theme.dart';
import 'core/widgets/maintenance_overlay.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/partner/presentation/bloc/partner_bloc.dart';
import 'router/app_router.dart';

class ActivEducationApp extends StatelessWidget {
  const ActivEducationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ActivEducation',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,

      routerConfig: AppRouter.router,

      builder: (context, child) {
        return MaintenanceOverlay(
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>(
                lazy: false,
                create: (_) =>
                    getIt<AuthBloc>()..add(const AuthCheckRequested()),
              ),
              BlocProvider<PartnerBloc>(
                lazy: true,
                create: (_) => getIt<PartnerBloc>(),
              ),
            ],
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
    );
  }
}
