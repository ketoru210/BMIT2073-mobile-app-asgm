import 'package:flutter/material.dart';

import '../ui/palette.dart';
import 'app_card.dart';

/// White pill for picking a state:
/// 5px colour dot + state name 13 w600 + ghost chevron-down.
class StatePill extends StatelessWidget {
  const StatePill({
    super.key,
    required this.state,
    required this.dotColor,
    required this.onTap,
  });

  final String state;
  final Color dotColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 21,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      onTap: onTap,
      child: SizedBox(
        height: 42,
        child: Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                state,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Palette.ink,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: Palette.ghost,
            ),
          ],
        ),
      ),
    );
  }
}
