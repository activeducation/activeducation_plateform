import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/di/injection_container.dart';
import 'core/observability/sentry_bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  await configureDependencies();

  await initSentryAndRun(
    release: 'activ-education-app@1.0.0',
    appRunner: () => runApp(
      wrapWithSentryIfEnabled(const ActivEducationApp()),
    ),
  );
}
