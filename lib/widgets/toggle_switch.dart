import 'package:flutter/material.dart';

import '../ui/palette.dart';

/// 46x27 pill toggle: on = primary fill with a
/// white knob, off = grey fill.
class ToggleSwitch extends StatelessWidget {
  const ToggleSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 46,
        height: 27,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? Palette.primary : Palette.border,
          borderRadius: BorderRadius.circular(13.5),
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 21,
            height: 21,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
