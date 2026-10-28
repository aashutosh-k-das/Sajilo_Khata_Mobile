import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/themes/app_theme.dart';
import '../../core/providers.dart';
import '../../core/utils/vat_calculator.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/form_dialogs.dart';
import '../khata/customer_detail_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final metrics = ref.watch(metricsProvider).valueOrNull;
    final recent = ref.watch(recentTransactionsProvider).valueOrNull ??
        const <KhataTransaction>[];
    final customers =
        ref.watch(customersProvider).valueOrNull ?? const <Customer>[];
    final lowStock = metrics?.lowStockCount ?? 0;

    return RefreshIndicator(
      onRefresh: () async => refreshData(ref),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metrics Section
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: t['todaySales'],
                    value:
                        VatCalculator.formatCurrency(metrics?.todaySales ?? 0),
                    icon: Icons.trending_up,
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: t['totalCredit'],
                    value:
                        VatCalculator.formatCurrency(metrics?.totalCredit ?? 0),
                    icon: Icons.credit_card,
                    color: AppTheme.errorColor,
                    onTap: () => ref.read(homeTabProvider.notifier).state = 3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: t['lowStockItems'],
                    value: '$lowStock',
                    icon: Icons.warning_amber_rounded,
                    color: AppTheme.secondaryColor,
                    hasAlert: lowStock > 0,
                    onTap: () => ref.read(homeTabProvider.notifier).state = 2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: t['activeCustomers'],
                    value: '${metrics?.activeCustomers ?? 0}',
                    icon: Icons.people,
                    color: Colors.blue,
                    onTap: () => ref.read(homeTabProvider.notifier).state = 3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions Section
            Text(
              t['quickActions'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _QuickActionButton(
                  label: t['newSale'],
                  icon: Icons.receipt_long,
                  onPressed: () => ref.read(homeTabProvider.notifier).state = 1,
                ),
                _QuickActionButton(
                  label: t['newProduct'],
                  icon: Icons.inventory_2,
                  onPressed: () => showProductDialog(context, ref),
                ),
                _QuickActionButton(
                  label: t['newCustomer'],
                  icon: Icons.person_add,
                  onPressed: () => showAddCustomerDialog(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent khata activity
            Text(
              t['recentTransactions'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: recent.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                          child: Text(t['noTransactions'],
                              style: const TextStyle(color: Colors.grey))),
                    )
                  : Column(
                      children: [
                        for (final tx in recent)
                          _RecentTile(
                            tx: tx,
                            customerName: customers
                                    .where((c) => c.id == tx.customerId)
                                    .map((c) => c.name)
                                    .firstOrNull ??
                                '—',
                          ),
                      ],
                    ),
            ),
            if ((metrics?.pendingSync ?? 0) > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.cloud_upload_outlined,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    '${metrics!.pendingSync} ${t['pendingSync']}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.tx, required this.customerName});

  final KhataTransaction tx;
  final String customerName;

  @override
  Widget build(BuildContext context) {
    final isCredit = tx.type == 'credit';
    return ListTile(
      dense: true,
      title: Text(customerName,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${DateFormat.yMMMd().format(tx.date)} • ${tx.description}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '${isCredit ? '+' : '-'} ${VatCalculator.formatCurrency(tx.amount)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isCredit ? AppTheme.errorColor : AppTheme.successColor,
        ),
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CustomerDetailScreen(customerId: tx.customerId)),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool hasAlert;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.hasAlert = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: hasAlert ? Border.all(color: color, width: 1.5) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  Icon(icon, color: color, size: 18),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton.filledTonal(
          icon: Icon(icon, color: AppTheme.primaryColor),
          onPressed: onPressed,
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(16.0),
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.08),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
