import 'package:flutter/material.dart';

import '../ui/palette.dart';

/// Risk vs Balanced tag style.
enum BadgeStyle { risk, balanced }

/// Small rounded badge: Risk (red) or Balanced (green).
class BadgeChip extends StatelessWidget {
  const BadgeChip({super.key, required this.style, required this.label});

  final BadgeStyle style;
  final String label;

  @override
  Widget build(BuildContext context) {
    // pick the colour pair for this style
    Color background;
    Color foreground;
    switch (style) {
      case BadgeStyle.risk:
        background = Palette.riskBg;
        foreground = Palette.riskText;
        break;
      case BadgeStyle.balanced:
        background = Palette.chipGreenBg;
        foreground = Palette.green;
        break;
    }
    return Container(
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
      ),
    );
  }
}
