import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/themes/app_theme.dart';
import '../../core/providers.dart';
import '../../core/services/sms_service.dart';
import '../../core/utils/vat_calculator.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/form_dialogs.dart';
import '../../shared/widgets/ui.dart';
import 'khata_screen.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final int customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final customer =
        (ref.watch(customersProvider).valueOrNull ?? const <Customer>[])
            .where((c) => c.id == customerId)
            .firstOrNull;
    final ledger = ref.watch(customerLedgerProvider(customerId)).valueOrNull ??
        const <KhataTransaction>[];

    if (customer == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final (label, color) = balanceLabel(t, customer.balance);

    return Scaffold(
      appBar: AppBar(title: Text(customer.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Balance summary
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    customer.name.isEmpty
                        ? '?'
                        : customer.name.characters.first.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 10),
                Text(t['balance'],
                    style: const TextStyle(color: Colors.white70)),
                Text(
                  VatCalculator.formatCurrency(customer.balance.abs()),
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(label,
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.call_rounded,
                        size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(customer.phone,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.errorColor),
                  icon: const Icon(Icons.north_east_rounded),
                  label: Text(t['giveCredit']),
                  onPressed: () =>
                      _showEntryDialog(context, ref, customer, 'credit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.successColor),
                  icon: const Icon(Icons.south_west_rounded),
                  label: Text(t['receivePayment']),
                  onPressed: () =>
                      _showEntryDialog(context, ref, customer, 'payment'),
                ),
              ),
            ],
          ),
          if (customer.balance > 0) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.sms_rounded),
              label: Text(t['sendReminder']),
              onPressed: () => _sendReminder(context, ref, customer),
            ),
          ],
          const SizedBox(height: 20),
          SectionHeader(t['khata']),
          Card(
            margin: EdgeInsets.zero,
            child: ledger.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long_rounded,
                    message: t['noLedger'],
                  )
                : Column(
                    children: [
                      for (final (i, tx) in ledger.indexed) ...[
                        if (i > 0) const Divider(indent: 68),
                        ListTile(
                          leading: IconBadge(
                            tx.type == 'credit'
                                ? Icons.north_east_rounded
                                : Icons.south_west_rounded,
                            color: tx.type == 'credit'
                                ? AppTheme.errorColor
                                : AppTheme.successColor,
                          ),
                          title: Text(
                              tx.type == 'credit'
                                  ? t['credit']
                                  : t['receivePayment'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                              '${DateFormat.yMMMd().add_jm().format(tx.date)}\n${tx.description}'),
                          isThreeLine: true,
                          trailing: Text(
                            '${tx.type == 'credit' ? '+' : '−'} ${VatCalculator.formatCurrency(tx.amount)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: tx.type == 'credit'
                                  ? AppTheme.errorColor
                                  : AppTheme.successColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEntryDialog(BuildContext context, WidgetRef ref,
      Customer customer, String type) async {
    final t = ref.read(stringsProvider);
    final amount = TextEditingController();
    final desc = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type == 'credit' ? t['giveCredit'] : t['receivePayment']),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amount,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                ],
                decoration:
                    InputDecoration(labelText: t['amount'], prefixText: 'रु. '),
                validator: (v) => (double.tryParse(v ?? '') ?? 0) > 0
                    ? null
                    : t['invalidQtyPrice'],
              ),
              const SizedBox(height: 12),
              TextFormField(
                  controller: desc,
                  decoration: InputDecoration(labelText: t['description'])),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t['cancel'])),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: Text(t['save']),
          ),
        ],
      ),
    );

    final value = double.tryParse(amount.text);
    final description = desc.text.trim();
    amount.dispose();
    desc.dispose();
    if (ok != true || value == null) return;

    await ref.read(repositoryProvider).addTransaction(
          customerId: customer.id!,
          type: type,
          amount: value,
          description: description.isNotEmpty
              ? description
              : (type == 'credit' ? 'Credit given' : 'Payment received'),
        );
    refreshData(ref);
    if (context.mounted) showSnack(context, t['entryUpdated']);
  }

  Future<void> _sendReminder(
      BuildContext context, WidgetRef ref, Customer customer) async {
    final t = ref.read(stringsProvider);
    final sms = ref.read(smsServiceProvider);
    final text = t.isNepali
        ? SMSService.generateNepaliReminderText(
            customerName: customer.name,
            outstandingAmount: customer.balance,
            shopName: t['shopName'],
          )
        : 'Namaste ${customer.name}, your outstanding balance at ${t['shopName']} is '
            'Rs. ${customer.balance.toStringAsFixed(2)}. Kindly clear it soon. Thank you!';

    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t['sendReminder']),
        content: Text(text),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t['cancel'])),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t['send'])),
        ],
      ),
    );
    if (send != true) return;

    bool sent;
    if (sms != null) {
      // Sparrow SMS gateway configured via --dart-define=SPARROW_SMS_TOKEN
      sent =
          await sms.sendReminderSMS(toPhone: customer.phone, messageText: text);
    } else {
      // No gateway token: hand off to the phone's own SMS app
      sent = await launchUrl(Uri(
          scheme: 'sms',
          path: customer.phone,
          query: 'body=${Uri.encodeComponent(text)}'));
    }
    if (context.mounted) {
      showSnack(context, sent ? t['reminderSent'] : t['reminderFailed'],
          isError: !sent);
    }
  }
}
