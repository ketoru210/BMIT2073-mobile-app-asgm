import 'package:flutter/material.dart';

import '../ui/palette.dart';

/// The white rounded card shell used across the app
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 18,
    this.color = Palette.card,
    this.shadows = const [Palette.cardShadow],
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;

  /// Shadow list, overridable so the hero CTA can use [Palette.heroShadow].
  final List<BoxShadow> shadows;

  /// Optional tap handler; cards that are not tappable omit it.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadows,
      ),
      child: onTap == null
          ? content
          // opaque so the whole card responds, not just the icon and text
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: content,
            ),
    );
  }
}
