import 'package:flutter/material.dart';

import '../ui/palette.dart';

/// Small uppercase section heading:
/// 9.5 w600 faint, letter-spaced, e.g. "ANALYSIS MODE".
class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
        color: Palette.faint,
        letterSpacing: 1.2,
      ),
    );
  }
}
