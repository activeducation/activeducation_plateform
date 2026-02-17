import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/di/injection_container.dart';
import 'core/theme/theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'router/app_router.dart';

class ActivEducationApp extends StatelessWidget {
  const ActivEducationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => getIt<AuthBloc>()..add(const AuthCheckRequested()),
        ),
      ],
      child: MaterialApp.router(
        title: 'ActivEducation',
        debugShowCheckedModeBanner: false,

        // Theme
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,

        // Routing
        routerConfig: AppRouter.router,

        // Localisation
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr', 'FR'), // Francais par defaut
          Locale('en', 'US'),
        ],
      ),
    );
  }
}
