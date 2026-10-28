import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';
import '../../core/services/whatsapp_service.dart';
import '../../shared/models/models.dart';

/// Plain-text receipt used both for on-screen display and WhatsApp sharing.
String buildReceiptText(Bill bill) {
  final b = StringBuffer()
    ..writeln('SAJILO KHATA SHOP')
    ..writeln('Birgunj-8, Parsa, Nepal')
    ..writeln('-' * 32)
    ..writeln('Invoice: #${bill.id ?? '-'}')
    ..writeln('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(bill.date)}')
    ..writeln('Customer: ${bill.customerName}')
    ..writeln('Payment: ${bill.paymentMethod.toUpperCase()}')
    ..writeln('-' * 32);
  for (final i in bill.items) {
    final name =
        i.name.length > 18 ? i.name.substring(0, 18) : i.name.padRight(18);
    b.writeln('$name${'${i.qty}x${i.price.toStringAsFixed(0)}'.padLeft(14)}');
  }
  b
    ..writeln('-' * 32)
    ..writeln(
        'Subtotal:${'Rs. ${bill.subtotal.toStringAsFixed(2)}'.padLeft(23)}')
    ..writeln('13% VAT:${'Rs. ${bill.vat.toStringAsFixed(2)}'.padLeft(24)}')
    ..writeln('TOTAL:${'Rs. ${bill.total.toStringAsFixed(2)}'.padLeft(26)}')
    ..writeln('-' * 32)
    ..write('Thank you for your business!');
  return b.toString();
}

Future<void> showReceiptDialog(BuildContext context, Bill bill,
    {String? customerPhone}) {
  return showDialog(
    context: context,
    builder: (_) => _ReceiptDialog(bill: bill, customerPhone: customerPhone),
  );
}

class _ReceiptDialog extends ConsumerWidget {
  const _ReceiptDialog({required this.bill, this.customerPhone});

  final Bill bill;
  final String? customerPhone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final text = buildReceiptText(bill);

    return AlertDialog(
      title: Text(t['invoice']),
      content: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Text(
            text,
            style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.black,
                height: 1.4),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(t['close'])),
        FilledButton.icon(
          icon: const Icon(Icons.share),
          label: Text(t['shareWhatsApp']),
          style:
              FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
          onPressed: () => WhatsAppService()
              .shareInvoice(phone: customerPhone ?? '', invoiceText: text),
        ),
      ],
    );
  }
}
