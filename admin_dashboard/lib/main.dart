import 'package:flutter/material.dart';
import 'core/di/injection_container.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const AdminApp());
}
