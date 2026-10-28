import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../models/models.dart';

void showSnack(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
    ));
}

String? _required(String? v, String msg) =>
    (v == null || v.trim().isEmpty) ? msg : null;

/// Add (or edit, when [existing] is given) an inventory product.
Future<void> showProductDialog(BuildContext context, WidgetRef ref,
    {InventoryItem? existing}) {
  return showDialog(
    context: context,
    builder: (_) => _ProductDialog(existing: existing),
  );
}

class _ProductDialog extends ConsumerStatefulWidget {
  const _ProductDialog({this.existing});

  final InventoryItem? existing;

  @override
  ConsumerState<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends ConsumerState<_ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _category =
      TextEditingController(text: widget.existing?.category ?? 'Groceries');
  late final _qty =
      TextEditingController(text: '${widget.existing?.stockQty ?? 0}');
  late final _buying = TextEditingController(
      text: widget.existing?.buyingPrice.toStringAsFixed(0));
  late final _selling = TextEditingController(
      text: widget.existing?.sellingPrice.toStringAsFixed(0));
  late final _threshold =
      TextEditingController(text: '${widget.existing?.minThreshold ?? 5}');

  @override
  void dispose() {
    for (final c in [_name, _category, _qty, _buying, _selling, _threshold]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final t = ref.read(stringsProvider);
    await ref.read(repositoryProvider).saveProduct(InventoryItem(
          id: widget.existing?.id,
          name: _name.text.trim(),
          category: _category.text.trim(),
          stockQty: int.parse(_qty.text),
          buyingPrice: double.parse(_buying.text),
          sellingPrice: double.parse(_selling.text),
          minThreshold: int.parse(_threshold.text),
        ));
    refreshData(ref);
    if (!mounted) return;
    Navigator.pop(context);
    showSnack(context, t['productSaved']);
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    String? numeric(String? v) {
      final err = _required(v, t['requiredField']);
      if (err != null) return err;
      return (num.tryParse(v!) ?? -1) < 0 ? t['invalidQtyPrice'] : null;
    }

    Widget field(TextEditingController c, String label,
        {bool isNumber = false, bool decimal = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          decoration: InputDecoration(labelText: label),
          keyboardType: isNumber
              ? TextInputType.numberWithOptions(decimal: decimal)
              : TextInputType.text,
          inputFormatters: isNumber
              ? [
                  FilteringTextInputFormatter.allow(
                      RegExp(decimal ? r'[0-9.]' : r'[0-9]'))
                ]
              : null,
          validator:
              isNumber ? numeric : (v) => _required(v, t['requiredField']),
        ),
      );
    }

    return AlertDialog(
      title: Text(
          widget.existing == null ? t['newProduct'] : widget.existing!.name),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              field(_name, t['productName']),
              field(_category, t['category']),
              field(_qty, t['qty'], isNumber: true),
              Row(
                children: [
                  Expanded(
                      child: field(_buying, t['buyingPrice'],
                          isNumber: true, decimal: true)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: field(_selling, t['sellingPrice'],
                          isNumber: true, decimal: true)),
                ],
              ),
              field(_threshold, t['minThreshold'], isNumber: true),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(t['cancel'])),
        FilledButton(onPressed: _save, child: Text(t['save'])),
      ],
    );
  }
}

/// Adds a customer. Returns the new customer's id, or null if cancelled.
Future<int?> showAddCustomerDialog(BuildContext context, WidgetRef ref) {
  return showDialog<int>(
      context: context, builder: (_) => const _CustomerDialog());
}

class _CustomerDialog extends ConsumerStatefulWidget {
  const _CustomerDialog();

  @override
  ConsumerState<_CustomerDialog> createState() => _CustomerDialogState();
}

class _CustomerDialogState extends ConsumerState<_CustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final t = ref.read(stringsProvider);
    final id =
        await ref.read(repositoryProvider).addCustomer(_name.text, _phone.text);
    refreshData(ref);
    if (!mounted) return;
    Navigator.pop(context, id);
    showSnack(context, t['customerAdded']);
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    return AlertDialog(
      title: Text(t['newCustomer']),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: t['customerName']),
              validator: (v) => _required(v, t['requiredField']),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: InputDecoration(
                  labelText: t['phone'], hintText: '98XXXXXXXX'),
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => RegExp(r'^9[78]\d{8}$').hasMatch(v ?? '')
                  ? null
                  : t['invalidPhone'],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(t['cancel'])),
        FilledButton(onPressed: _save, child: Text(t['save'])),
      ],
    );
  }
}
