import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Initialise Sentry si un DSN est fourni via --dart-define=SENTRY_DSN=...
///
/// Aucune donnee n'est envoyee si le DSN est vide.
Future<void> initSentryAndRun({
  required FutureOr<void> Function() appRunner,
  required String release,
}) async {
  const dsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
  const environment = String.fromEnvironment(
    'SENTRY_ENVIRONMENT',
    defaultValue: 'production',
  );

  if (dsn.isEmpty) {
    await appRunner();
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = dsn;
      options.environment = environment;
      options.release = release;
      options.tracesSampleRate = kReleaseMode ? 0.1 : 1.0;
      options.sendDefaultPii = false;
      options.attachStacktrace = true;
      options.debug = !kReleaseMode;
    },
    appRunner: appRunner,
  );
}

Widget wrapWithSentryIfEnabled(Widget app) {
  const dsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
  if (dsn.isEmpty) return app;
  return SentryWidget(child: app);
}
