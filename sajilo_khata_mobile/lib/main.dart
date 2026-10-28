import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/themes/app_theme.dart';
import 'core/database/database_helper.dart';
import 'core/providers.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // sqflite has no browser backend; use the wasm SQLite build when running on web.
  // The no-worker variant runs on the page itself, so it also works in mobile
  // browsers. web/sqlite3.wasm must match the resolved package:sqlite3 version.
  if (kIsWeb) databaseFactory = databaseFactoryFfiWebNoWebWorker;

  // Initialize SQLite database instance for offline use
  final dbHelper = DatabaseHelper.instance;
  await dbHelper.database;

  // Initialize Firebase (wrapped in a try-catch for offline first execution if configuration is missing)
  var firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (e) {
    debugPrint(
        "Firebase init bypassed: running in local offline-only mode. Details: $e");
  }

  runApp(
    ProviderScope(
      overrides: [firebaseReadyProvider.overrideWithValue(firebaseReady)],
      child: const SajiloKhataApp(),
    ),
  );
}

class SajiloKhataApp extends ConsumerWidget {
  const SajiloKhataApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    return MaterialApp(
      title: 'Sajilo Khata',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: session.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const LoginScreen(),
        data: (user) => user != null ? const HomeShell() : const LoginScreen(),
      ),
    );
  }
}
