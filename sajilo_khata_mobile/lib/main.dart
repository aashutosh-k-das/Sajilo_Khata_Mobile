import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/themes/app_theme.dart';
import 'core/database/database_helper.dart';
import 'features/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SQLite database instance for offline use
  final dbHelper = DatabaseHelper.instance;
  await dbHelper.database;
  
  // Initialize Firebase (wrapped in a try-catch for offline first execution if configuration is missing)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init bypassed: running in local offline-only mode. Details: $e");
  }

  runApp(
    const ProviderScope(
      child: SajiloKhataApp(),
    ),
  );
}

class SajiloKhataApp extends StatelessWidget {
  const SajiloKhataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sajilo Khata',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const DashboardScreen(),
    );
  }
}
