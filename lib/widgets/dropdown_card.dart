import 'package:flutter/material.dart';

import '../ui/palette.dart';
import 'app_card.dart';

/// White filter dropdown: left label 14 w600 ink,
/// right chevron-down primary; tapping opens a themed bottom sheet.
class DropdownCard<T> extends StatelessWidget {
  const DropdownCard({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.labelBuilder,
    this.height = 54,
  });

  final T value;
  final List<T> options;
  final ValueChanged<T> onChanged;

  /// Optional label formatter (e.g. enum -> friendly name).
  final String Function(T value)? labelBuilder;
  final double height;

  String _label(T v) => labelBuilder?.call(v) ?? v.toString();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 16,
      onTap: () => _showSheet(context),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _label(value),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Palette.ink,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Palette.primary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => OptionSheet<T>(
        options: options,
        current: value,
        labelBuilder: labelBuilder,
      ),
    );
    if (selected != null && selected != value) {
      onChanged(selected);
    }
  }
}

/// White bottom sheet with rounded top corners listing [options];
/// pops with the tapped value.
class OptionSheet<T> extends StatelessWidget {
  const OptionSheet({
    super.key,
    required this.options,
    required this.current,
    this.labelBuilder,
  });

  final List<T> options;
  final T current;
  final String Function(T value)? labelBuilder;

  String _label(T v) => labelBuilder?.call(v) ?? v.toString();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Palette.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final option in options)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(option),
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _label(option),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: option == current
                                ? Palette.primary
                                : Palette.ink,
                          ),
                        ),
                      ),
                      if (option == current)
                        const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: Palette.primary,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
