import 'package:flutter/material.dart';

import '../ui/palette.dart';

/// The dark chevron-left used as the back control on every screen that
/// is not Home ([HeroBand] uses a white variant instead).
///
/// It takes an explicit [onTap] instead of popping itself, because the
/// tab-root pages have to leave the tab rather than pop a route.
class BackChevron extends StatelessWidget {
  const BackChevron({super.key, required this.onTap, this.color = Palette.ink});

  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: onTap,
      icon: Icon(Icons.chevron_left, color: color, size: 30),
    );
  }
}
