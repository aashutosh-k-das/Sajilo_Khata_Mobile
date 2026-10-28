import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/themes/app_theme.dart';
import '../../core/providers.dart';
import '../../core/utils/vat_calculator.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/form_dialogs.dart';
import '../../shared/widgets/ui.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    final all =
        ref.watch(productsProvider).valueOrNull ?? const <InventoryItem>[];
    final q = _query.toLowerCase();
    final products = all
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q))
        .toList()
      // Low stock first so it is easy to spot what needs re-ordering
      ..sort((a, b) => (a.isLowStock ? 0 : 1).compareTo(b.isLowStock ? 0 : 1));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-product',
        onPressed: () => showProductDialog(context, ref),
        icon: const Icon(Icons.add),
        label: Text(t['newProduct']),
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
            child: products.isEmpty
                ? EmptyState(
                    icon: Icons.inventory_2_rounded,
                    message: t['noProducts'],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: products.length,
                    itemBuilder: (_, i) => _ProductTile(product: products[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends ConsumerWidget {
  const _ProductTile({required this.product});

  final InventoryItem product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final p = product;
    final (label, color) = p.isOutOfStock
        ? (t['outOfStock'], AppTheme.errorColor)
        : p.isLowStock
            ? (t['lowStock'], AppTheme.secondaryColor)
            : (t['inStock'], AppTheme.successColor);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        side: BorderSide(
          color: p.isLowStock
              ? color.withValues(alpha: 0.5)
              : Theme.of(context).colorScheme.outline,
          width: p.isLowStock ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: IconBadge(_categoryIcon(p.category), color: color, size: 46),
        title:
            Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${p.category} • ${VatCalculator.formatCurrency(p.sellingPrice)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${p.stockQty}',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 10.5,
                      color: color,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        onTap: () => _showStockAdjust(context, ref),
        onLongPress: () => showProductDialog(context, ref, existing: p),
      ),
    );
  }

  static IconData _categoryIcon(String category) {
    final c = category.toLowerCase();
    if (c.contains('dairy')) return Icons.water_drop_rounded;
    if (c.contains('tea') || c.contains('sugar')) return Icons.coffee_rounded;
    if (c.contains('snack')) return Icons.cookie_rounded;
    if (c.contains('grocer')) return Icons.rice_bowl_rounded;
    if (c.contains('drink') || c.contains('beverage')) {
      return Icons.local_drink_rounded;
    }
    return Icons.shopping_basket_rounded;
  }

  Future<void> _showStockAdjust(BuildContext context, WidgetRef ref) async {
    final t = ref.read(stringsProvider);
    final controller = TextEditingController(text: '${product.stockQty}');

    void step(int delta) {
      final v = (int.tryParse(controller.text) ?? 0) + delta;
      controller.text = '${v < 0 ? 0 : v}';
    }

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t['adjustStock']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(product.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton.filledTonal(
                    onPressed: () => step(-1), icon: const Icon(Icons.remove)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: t['qty']),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                    onPressed: () => step(1), icon: const Icon(Icons.add)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'edit'),
            child: Text(t['editDetails']),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'delete'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: Text(t['delete']),
          ),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, 'save'),
              child: Text(t['save'])),
        ],
      ),
    );
    final qty = int.tryParse(controller.text);
    controller.dispose();
    if (!context.mounted) return;

    final repo = ref.read(repositoryProvider);
    switch (result) {
      case 'save' when qty != null:
        await repo.updateStock(product.id!, qty);
        refreshData(ref);
        if (context.mounted) showSnack(context, t['stockUpdated']);
      case 'edit':
        await showProductDialog(context, ref, existing: product);
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('${t['delete']}: ${product.name}?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(t['cancel'])),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.errorColor),
                child: Text(t['delete']),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        await repo.deleteProduct(product.id!);
        refreshData(ref);
    }
  }
}
