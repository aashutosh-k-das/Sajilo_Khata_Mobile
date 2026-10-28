import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/themes/app_theme.dart';
import '../../core/providers.dart';
import '../../core/utils/vat_calculator.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/form_dialogs.dart';
import '../../shared/widgets/ui.dart';
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
    void goTo(int tab) => ref.read(homeTabProvider.notifier).state = tab;

    return RefreshIndicator(
      onRefresh: () async => refreshData(ref),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _HeroCard(
            greeting: t['namaste'],
            salesLabel: t['todaySales'],
            sales: metrics?.todaySales ?? 0,
            creditLabel: t['totalCredit'],
            credit: metrics?.totalCredit ?? 0,
            pendingSync: metrics?.pendingSync ?? 0,
            pendingLabel: t['pendingSync'],
            onCreditTap: () => goTo(3),
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatTile(
                    label: t['lowStockItems'],
                    value: '$lowStock',
                    icon: Icons.warning_amber_rounded,
                    color: lowStock > 0
                        ? AppTheme.secondaryColor
                        : AppTheme.successColor,
                    onTap: () => goTo(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: t['activeCustomers'],
                    value: '${metrics?.activeCustomers ?? 0}',
                    icon: Icons.groups_rounded,
                    color: AppTheme.infoColor,
                    onTap: () => goTo(3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionHeader(t['quickActions']),
          Row(
            children: [
              _QuickAction(
                label: t['newSale'],
                icon: Icons.point_of_sale_rounded,
                color: AppTheme.primaryColor,
                onTap: () => goTo(1),
              ),
              const SizedBox(width: 10),
              _QuickAction(
                label: t['newProduct'],
                icon: Icons.add_box_rounded,
                color: AppTheme.violetColor,
                onTap: () => showProductDialog(context, ref),
              ),
              const SizedBox(width: 10),
              _QuickAction(
                label: t['newCustomer'],
                icon: Icons.person_add_alt_1_rounded,
                color: AppTheme.secondaryColor,
                onTap: () => showAddCustomerDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SectionHeader(t['recentTransactions']),
          Card(
            margin: EdgeInsets.zero,
            child: recent.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long_rounded,
                    message: t['noTransactions'],
                  )
                : Column(
                    children: [
                      for (final (i, tx) in recent.indexed) ...[
                        if (i > 0) const Divider(indent: 72),
                        _RecentTile(
                          tx: tx,
                          customerName: customers
                                  .where((c) => c.id == tx.customerId)
                                  .map((c) => c.name)
                                  .firstOrNull ??
                              '—',
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.greeting,
    required this.salesLabel,
    required this.sales,
    required this.creditLabel,
    required this.credit,
    required this.pendingSync,
    required this.pendingLabel,
    required this.onCreditTap,
  });

  final String greeting;
  final String salesLabel;
  final double sales;
  final String creditLabel;
  final double credit;
  final int pendingSync;
  final String pendingLabel;
  final VoidCallback onCreditTap;

  @override
  Widget build(BuildContext context) {
    const white70 = TextStyle(color: Colors.white70, fontSize: 13);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Soft decorative circles
          Positioned(
            right: -40,
            top: -50,
            child: _Bubble(size: 170, opacity: 0.08),
          ),
          Positioned(
            right: 40,
            bottom: -60,
            child: _Bubble(size: 120, opacity: 0.06),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(greeting,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text(DateFormat('EEE, d MMM').format(DateTime.now()),
                        style: white70),
                  ],
                ),
                const SizedBox(height: 18),
                Text(salesLabel, style: white70),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    VatCalculator.formatCurrency(sales),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HeroChip(
                        icon: Icons.account_balance_wallet_rounded,
                        label: creditLabel,
                        value: VatCalculator.formatCurrency(credit),
                        onTap: onCreditTap,
                      ),
                    ),
                    if (pendingSync > 0) ...[
                      const SizedBox(width: 10),
                      _HeroChip(
                        icon: Icons.cloud_upload_rounded,
                        label: pendingLabel,
                        value: '$pendingSync',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );
}

class _HeroChip extends StatelessWidget {
  const _HeroChip(
      {required this.icon,
      required this.label,
      required this.value,
      this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                    Text(value,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              IconBadge(icon, color: color, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.1)),
                    Text(label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
            child: Column(
              children: [
                IconBadge(icon, color: color, size: 48),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
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
    final color = isCredit ? AppTheme.errorColor : AppTheme.successColor;
    return ListTile(
      leading: NameAvatar(customerName),
      title: Text(customerName,
          style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        '${DateFormat.MMMd().format(tx.date)} • ${tx.description}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '${isCredit ? '+' : '−'} ${VatCalculator.formatCurrency(tx.amount)}',
          style: TextStyle(fontWeight: FontWeight.w800, color: color),
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
