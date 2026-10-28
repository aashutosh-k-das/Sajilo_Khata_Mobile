import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/themes/app_theme.dart';
import '../../core/providers.dart';
import '../../shared/widgets/form_dialogs.dart';
import '../../shared/widgets/ui.dart';
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
        titleSpacing: 16,
        title: Row(
          children: [
            const BrandMark(size: 36),
            const SizedBox(width: 10),
            Text(t['appName']),
          ],
        ),
        actions: [
          // Cloud sync pill: green when Firebase is configured, grey in local-only mode
          Material(
            color: (cloud ? AppTheme.successColor : Colors.grey)
                .withValues(alpha: 0.12),
            shape: const StadiumBorder(),
            child: InkWell(
              onTap: () => _sync(context, ref),
              customBorder: const StadiumBorder(),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    Icon(cloud ? Icons.cloud_done_rounded : Icons.cloud_off,
                        size: 16,
                        color: cloud ? AppTheme.successColor : Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      cloud ? t['online'] : t['offline'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cloud ? AppTheme.successColor : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.translate_rounded),
            tooltip: 'नेपाली / English',
            onPressed: () => ref.read(languageProvider.notifier).toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: t['logout'],
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(index: tab, children: _tabs),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
              top: BorderSide(color: Theme.of(context).colorScheme.outline)),
        ),
        child: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) =>
              ref.read(homeTabProvider.notifier).state = i,
          destinations: [
            NavigationDestination(
                icon: const Icon(Icons.space_dashboard_outlined),
                selectedIcon: const Icon(Icons.space_dashboard_rounded),
                label: t['dashboard']),
            NavigationDestination(
                icon: const Icon(Icons.receipt_long_outlined),
                selectedIcon: const Icon(Icons.receipt_long_rounded),
                label: t['billing']),
            NavigationDestination(
                icon: const Icon(Icons.inventory_2_outlined),
                selectedIcon: const Icon(Icons.inventory_2_rounded),
                label: t['inventory']),
            NavigationDestination(
                icon: const Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
                label: t['khata']),
          ],
        ),
      ),
    );
  }
}
