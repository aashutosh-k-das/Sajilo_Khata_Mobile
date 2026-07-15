import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/themes/app_theme.dart';
import '../../core/utils/vat_calculator.dart';

// Riverpod Provider definitions for state management demonstration
final networkStatusProvider = StateProvider<bool>((ref) => true); // Online default
final todaySalesProvider = StateProvider<double>((ref) => 15640.00);
final outstandingCreditProvider = StateProvider<double>((ref) => 38450.00);
final lowStockCountProvider = StateProvider<int>((ref) => 3);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(networkStatusProvider);
    final todaySales = ref.watch(todaySalesProvider);
    final totalCredit = ref.watch(outstandingCreditProvider);
    final lowStock = ref.watch(lowStockCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, py: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'स',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            const Text('सजिलो खाता'),
          ],
        ),
        actions: [
          // Simulated Connection indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOnline ? AppTheme.successColor : AppTheme.errorColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOnline ? AppTheme.successColor : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language switched to English/नेपाली')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metrics Section
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'आजको बिक्री',
                    value: VatCalculator.formatCurrency(todaySales),
                    icon: Icons.trending_up,
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'कुल उधारो',
                    value: VatCalculator.formatCurrency(totalCredit),
                    icon: Icons.credit_card,
                    color: AppTheme.errorColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'कम मौज्दात सामानहरू',
                    value: '$lowStock',
                    icon: Icons.warning_amber_rounded,
                    color: AppTheme.secondaryColor,
                    hasAlert: lowStock > 0,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: _MetricCard(
                    title: 'सक्रिय ग्राहकहरू',
                    value: '12',
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Quick Actions Section
            const Text(
              'द्रुत कार्यहरू (Quick Actions)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _QuickActionButton(
                  label: 'नयाँ बिल',
                  icon: Icons.receipt_long,
                  onPressed: () {},
                ),
                _QuickActionButton(
                  label: 'नयाँ सामान',
                  icon: Icons.inventory_2,
                  onPressed: () {},
                ),
                _QuickActionButton(
                  label: 'नयाँ ग्राहक',
                  icon: Icons.person_add,
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Demo Instructions Info Card
            Card(
              color: AppTheme.primaryColor.withOpacity(0.08),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                key: const Key('info-card'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'विकासकर्ता जानकारी (Developer Notice)',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'यो मोबाइल एपको ढाँचा (Flutter template) हो। यसलाई पूर्ण रूपमा चलाउनका लागि तपाईंको मेसिनमा Flutter SDK स्थापना गरी `flutter run` गर्नुहोस्।',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        ref.read(networkStatusProvider.notifier).state = !isOnline;
                      },
                      child: Text(
                        'सिमुलेशन: ${isOnline ? "अफलाइन जानुहोस्" : "अनलाइन जानुहोस्"}',
                        style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'ड्यासबोर्ड'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'बिलिङ'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'मौज्दात'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'खाता'),
        ],
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

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.hasAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Icon(icon, color: color, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
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
            backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
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
