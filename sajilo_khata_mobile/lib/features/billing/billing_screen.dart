import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/themes/app_theme.dart';
import '../../core/providers.dart';
import '../../core/utils/vat_calculator.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/form_dialogs.dart';
import 'receipt_dialog.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  final _cart = <CartItem>[];
  final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  int? _customerId;
  int? _productId;
  String _paymentMethod = 'cash';
  bool _saving = false;

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  double get _subtotal => _cart.fold(0, (sum, i) => sum + i.total);

  void _selectProduct(int? id, List<InventoryItem> products) {
    setState(() {
      _productId = id;
      final p = products.where((p) => p.id == id).firstOrNull;
      _priceController.text =
          p == null ? '' : p.sellingPrice.toStringAsFixed(0);
    });
  }

  void _addToCart(List<InventoryItem> products) {
    final t = ref.read(stringsProvider);
    final product = products.where((p) => p.id == _productId).firstOrNull;
    final qty = int.tryParse(_qtyController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;

    if (product == null) {
      showSnack(context, t['selectItem'], isError: true);
      return;
    }
    if (qty <= 0 || price <= 0) {
      showSnack(context, t['invalidQtyPrice'], isError: true);
      return;
    }
    final index =
        _cart.indexWhere((i) => i.productId == product.id && i.price == price);
    final inCart = _cart
        .where((i) => i.productId == product.id)
        .fold(0, (sum, i) => sum + i.qty);
    if (inCart + qty > product.stockQty) {
      showSnack(context, '${t['notEnoughStock']} (${product.stockQty})',
          isError: true);
      return;
    }

    setState(() {
      if (index >= 0) {
        _cart[index] = _cart[index].copyWith(qty: _cart[index].qty + qty);
      } else {
        _cart.add(CartItem(
            productId: product.id, name: product.name, qty: qty, price: price));
      }
      _productId = null;
      _qtyController.text = '1';
      _priceController.clear();
    });
  }

  Future<void> _checkout(List<Customer> customers) async {
    final t = ref.read(stringsProvider);
    if (_cart.isEmpty) {
      showSnack(context, t['cartEmpty'], isError: true);
      return;
    }
    final customer = customers.where((c) => c.id == _customerId).firstOrNull;
    if (_paymentMethod == 'credit' && customer == null) {
      showSnack(context, t['creditNeedsCustomer'], isError: true);
      return;
    }

    setState(() => _saving = true);
    final bill = await ref.read(repositoryProvider).saveBill(
          items: List.of(_cart),
          paymentMethod: _paymentMethod,
          customer: customer,
          anonymousName: t['anonymousCustomer'],
        );
    refreshData(ref);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _cart.clear();
      _paymentMethod = 'cash';
    });
    showSnack(context, t['billSaved']);
    await showReceiptDialog(context, bill, customerPhone: customer?.phone);
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    final products =
        ref.watch(productsProvider).valueOrNull ?? const <InventoryItem>[];
    final customers =
        ref.watch(customersProvider).valueOrNull ?? const <Customer>[];
    final subtotal = _subtotal;

    // Drop selections that no longer exist (e.g. after a data reset)
    if (_customerId != null && !customers.any((c) => c.id == _customerId))
      _customerId = null;
    if (_productId != null && !products.any((p) => p.id == _productId))
      _productId = null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Customer selection
        Row(
          children: [
            Expanded(
              child: _Dropdown<int?>(
                label: t['customer'],
                value: _customerId,
                items: [
                  DropdownMenuItem(
                      value: null, child: Text(t['anonymousCustomer'])),
                  for (final c in customers)
                    DropdownMenuItem(
                        value: c.id, child: Text('${c.name} (${c.phone})')),
                ],
                onChanged: (v) => setState(() => _customerId = v),
              ),
            ),
            IconButton.filledTonal(
              tooltip: t['newCustomer'],
              icon: const Icon(Icons.person_add),
              onPressed: () async {
                final id = await showAddCustomerDialog(context, ref);
                if (id != null) setState(() => _customerId = id);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Item entry
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _Dropdown<int?>(
                  label: t['selectItem'],
                  value: _productId,
                  items: [
                    for (final p in products)
                      DropdownMenuItem(
                        value: p.id,
                        enabled: !p.isOutOfStock,
                        child: Text(
                          '${p.name} (${t['qty']}: ${p.stockQty})',
                          style: p.isOutOfStock
                              ? const TextStyle(color: Colors.grey)
                              : null,
                        ),
                      ),
                  ],
                  onChanged: (v) => _selectProduct(v, products),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(labelText: t['qty']),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                        ],
                        decoration: InputDecoration(
                            labelText: t['rate'], prefixText: 'रु. '),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => _addToCart(products),
                      icon: const Icon(Icons.add_shopping_cart),
                      label: Text(t['addToCart']),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Cart
        Card(
          child: Column(
            children: [
              if (_cart.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(t['cartEmpty'],
                      style: const TextStyle(color: Colors.grey)),
                )
              else
                for (var i = 0; i < _cart.length; i++)
                  ListTile(
                    dense: true,
                    title: Text(_cart[i].name),
                    subtitle: Text(
                        '${_cart[i].qty} × ${VatCalculator.formatCurrency(_cart[i].price)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          VatCalculator.formatCurrency(_cart[i].total),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              size: 18, color: AppTheme.errorColor),
                          onPressed: () => setState(() => _cart.removeAt(i)),
                        ),
                      ],
                    ),
                  ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _TotalRow(t['subtotal'], subtotal),
                    _TotalRow(t['vat'], VatCalculator.calculateVat(subtotal)),
                    const SizedBox(height: 4),
                    _TotalRow(
                        t['grandTotal'], VatCalculator.calculateTotal(subtotal),
                        bold: true),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Payment method
        Text(t['paymentMethod'],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(
                value: 'cash',
                label: Text(t['cash']),
                icon: const Icon(Icons.payments_outlined)),
            ButtonSegment(
                value: 'credit',
                label: Text(t['credit']),
                icon: const Icon(Icons.book_outlined)),
            ButtonSegment(
                value: 'online',
                label: Text(t['online_pay']),
                icon: const Icon(Icons.qr_code)),
          ],
          selected: {_paymentMethod},
          onSelectionChanged: (s) => setState(() => _paymentMethod = s.first),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _saving ? null : () => _checkout(customers),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(t['checkout'],
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown(
      {required this.label,
      required this.value,
      required this.items,
      required this.onChanged});

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.amount, {this.bold = false});

  final String label;
  final double amount;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
        fontSize: bold ? 16 : 13,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(VatCalculator.formatCurrency(amount), style: style)
        ],
      ),
    );
  }
}
