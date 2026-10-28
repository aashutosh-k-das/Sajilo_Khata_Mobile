import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/themes/app_theme.dart';
import '../../core/providers.dart';
import '../../shared/widgets/form_dialogs.dart';
import '../billing/billing_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../inventory/inventory_screen.dart';
import '../khata/khata_screen.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const _tabs = [
    DashboardScreen(),
    BillingScreen(),
    InventoryScreen(),
    KhataScreen()
  ];

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    final t = ref.read(stringsProvider);
    if (!ref.read(firebaseReadyProvider)) {
      showSnack(context, t['offlineMode']);
      return;
    }
    try {
      final uid = ref.read(authServiceProvider).currentUser?.uid;
      await ref.read(syncServiceProvider).syncNow(uid);
      refreshData(ref);
      if (context.mounted) showSnack(context, t['syncDone']);
    } catch (e) {
      if (context.mounted)
        showSnack(context, '${t['syncFailed']}: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final tab = ref.watch(homeTabProvider);
    final cloud = ref.watch(firebaseReadyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'स',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Text(t['appName']),
          ],
        ),
        actions: [
          // Cloud sync indicator: green when Firebase is configured, grey in local-only mode
          InkWell(
            onTap: () => _sync(context, ref),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: cloud ? AppTheme.successColor : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    cloud ? t['online'] : t['offline'],
                    style: TextStyle(
                      fontSize: 12,
                      color: cloud ? AppTheme.successColor : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: 'नेपाली / English',
            onPressed: () => ref.read(languageProvider.notifier).toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: t['logout'],
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: IndexedStack(index: tab, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tab,
        onTap: (i) => ref.read(homeTabProvider.notifier).state = i,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard), label: t['dashboard']),
          BottomNavigationBarItem(
              icon: const Icon(Icons.receipt), label: t['billing']),
          BottomNavigationBarItem(
              icon: const Icon(Icons.inventory), label: t['inventory']),
          BottomNavigationBarItem(
              icon: const Icon(Icons.account_balance_wallet),
              label: t['khata']),
        ],
      ),
    );
  }
}
