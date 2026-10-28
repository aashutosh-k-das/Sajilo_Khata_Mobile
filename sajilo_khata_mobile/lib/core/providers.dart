import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared/models/models.dart';
import 'database/database_helper.dart';
import 'database/khata_repository.dart';
import 'l10n/app_strings.dart';
import 'services/auth_service.dart';
import 'services/sms_service.dart';
import 'services/sync_service.dart';

/// Overridden in main() with the result of Firebase.initializeApp().
final firebaseReadyProvider = Provider<bool>((ref) => false);

final repositoryProvider = Provider<KhataRepository>(
  (ref) => KhataRepository(DatabaseHelper.instance),
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(firebaseReady: ref.watch(firebaseReadyProvider)),
);

final sessionProvider = StreamProvider<String?>(
  (ref) => ref.watch(authServiceProvider).sessionChanges(),
);

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(ref.watch(repositoryProvider),
      firebaseReady: ref.watch(firebaseReadyProvider)),
);

/// Sparrow SMS token is supplied at build time: --dart-define=SPARROW_SMS_TOKEN=xxxx
final smsServiceProvider = Provider<SMSService?>((ref) {
  const token = String.fromEnvironment('SPARROW_SMS_TOKEN');
  return token.isEmpty ? null : SMSService(token: token);
});

// --- Language ---
class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('ne') {
    SharedPreferences.getInstance()
        .then((p) => state = p.getString(_key) ?? 'ne');
  }

  static const _key = 'sajilokhata_lang';

  Future<void> toggle() async {
    state = state == 'ne' ? 'en' : 'ne';
    (await SharedPreferences.getInstance()).setString(_key, state);
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, String>(
    (ref) => LanguageNotifier());

final stringsProvider =
    Provider<AppStrings>((ref) => AppStrings(ref.watch(languageProvider)));

// --- Data (re-fetched whenever dataVersionProvider is bumped after a write) ---
final dataVersionProvider = StateProvider<int>((ref) => 0);

void refreshData(WidgetRef ref) =>
    ref.read(dataVersionProvider.notifier).state++;

final productsProvider = FutureProvider<List<InventoryItem>>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(repositoryProvider).getProducts();
});

final customersProvider = FutureProvider<List<Customer>>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(repositoryProvider).getCustomers();
});

final metricsProvider = FutureProvider<DashboardMetrics>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(repositoryProvider).getMetrics();
});

final recentTransactionsProvider =
    FutureProvider<List<KhataTransaction>>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(repositoryProvider).getTransactions(limit: 5);
});

final customerLedgerProvider =
    FutureProvider.family<List<KhataTransaction>, int>((ref, customerId) {
  ref.watch(dataVersionProvider);
  return ref.watch(repositoryProvider).getTransactions(customerId: customerId);
});

/// Currently selected bottom navigation tab in the home shell.
final homeTabProvider = StateProvider<int>((ref) => 0);
