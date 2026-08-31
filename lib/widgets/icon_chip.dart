import 'package:flutter/material.dart';

/// Tinted rounded square holding a line icon:
/// 22x22 rx7 in stat cards, 40x40 rx13 in quick cards.
class IconChip extends StatelessWidget {
  const IconChip({
    super.key,
    required this.icon,
    required this.background,
    this.size = 40,
    this.radius,
    this.iconSize = 18,
  });

  /// Usually an [Icon].
  final Widget icon;
  final Color background;
  final double size;

  /// Corner radius; defaults to a 0.32 ratio of [size].
  final double? radius;

  /// Bounding box handed to [icon].
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius ?? size * 0.32),
      ),
      child: SizedBox(width: iconSize, height: iconSize, child: icon),
    );
  }
}
