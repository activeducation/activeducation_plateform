import 'package:flutter/material.dart';
import 'core/di/injection_container.dart';
import 'core/observability/sentry_bootstrap.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();

  await initSentryAndRun(
    release: 'admin-dashboard@1.0.0',
    appRunner: () => runApp(
      wrapWithSentryIfEnabled(const AdminApp()),
    ),
  );
}
