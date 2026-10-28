import 'package:flutter/material.dart';
import '../../app/themes/app_theme.dart';

/// Rounded, tinted square holding an icon (used by tiles and list rows).
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, required this.color, this.size = 40});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

/// Initial-letter avatar with a colour picked from the name.
class NameAvatar extends StatelessWidget {
  const NameAvatar(this.name, {super.key, this.size = 44});

  final String name;
  final double size;

  static const _palette = [
    AppTheme.primaryColor,
    AppTheme.infoColor,
    AppTheme.violetColor,
    AppTheme.secondaryColor,
    Color(0xFFEC4899),
    Color(0xFF0EA5E9),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _palette[name.hashCode.abs() % _palette.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: TextStyle(
            color: color, fontWeight: FontWeight.w800, fontSize: size * 0.42),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Friendly placeholder for empty lists.
class EmptyState extends StatelessWidget {
  const EmptyState(
      {super.key, required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 14)),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// The "स" brand mark.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 36, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: onDark ? null : AppTheme.brandGradient,
        color: onDark ? Colors.white.withValues(alpha: 0.18) : null,
        borderRadius: BorderRadius.circular(size * 0.3),
        border: onDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.35))
            : null,
      ),
      child: Text(
        'स',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.5,
          height: 1.1,
        ),
      ),
    );
  }
}
