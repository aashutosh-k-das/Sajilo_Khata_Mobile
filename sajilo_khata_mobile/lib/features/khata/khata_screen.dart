import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/themes/app_theme.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/providers.dart';
import '../../core/utils/vat_calculator.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/form_dialogs.dart';
import '../../shared/widgets/ui.dart';
import 'customer_detail_screen.dart';

/// Human-readable balance label: positive = customer owes the shop, negative = advance.
(String, Color) balanceLabel(AppStrings t, double balance) {
  if (balance > 0)
    return (
      '${t['mustPay']}: ${VatCalculator.formatCurrency(balance)}',
      AppTheme.errorColor
    );
  if (balance < 0)
    return (
      '${t['advance']}: ${VatCalculator.formatCurrency(-balance)}',
      AppTheme.successColor
    );
  return (t['noDues'], AppTheme.successColor);
}

class KhataScreen extends ConsumerStatefulWidget {
  const KhataScreen({super.key});

  @override
  ConsumerState<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends ConsumerState<KhataScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    final all = ref.watch(customersProvider).valueOrNull ?? const <Customer>[];
    final q = _query.toLowerCase();
    final customers = all
        .where((c) => c.name.toLowerCase().contains(q) || c.phone.contains(q))
        .toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-customer',
        onPressed: () => showAddCustomerDialog(context, ref),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(t['newCustomer']),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: t['search']),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: customers.isEmpty
                ? EmptyState(
                    icon: Icons.menu_book_rounded,
                    message: t['noCustomers'],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: customers.length,
                    itemBuilder: (_, i) {
                      final c = customers[i];
                      final (label, color) = balanceLabel(t, c.balance);
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          leading: NameAvatar(c.name),
                          title: Text(c.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Row(
                            children: [
                              const Icon(Icons.call_rounded, size: 13),
                              const SizedBox(width: 4),
                              Text(c.phone),
                            ],
                          ),
                          trailing: Container(
                            constraints: const BoxConstraints(maxWidth: 130),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              label,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12),
                            ),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    CustomerDetailScreen(customerId: c.id!)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
