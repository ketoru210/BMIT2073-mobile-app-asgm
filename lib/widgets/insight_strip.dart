import 'package:flutter/material.dart';

import '../ui/palette.dart';
import 'app_card.dart';

/// The shared "INSIGHT" card: green left bar,
/// uppercase label, and up to two lines of computed insight text.
class InsightStrip extends StatelessWidget {
  const InsightStrip({super.key, String? text, List<String>? lines})
    : assert(text != null || lines != null, 'Provide text or lines'),
      assert(text == null || lines == null, 'Provide only one of them'),
      _text = text,
      _lines = lines;

  final String? _text;
  final List<String>? _lines;

  List<String> get _content => _lines ?? [_text!];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: Palette.greenBar,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INSIGHT',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Palette.green,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  for (final line in _content)
                    Text(
                      line,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Palette.body,
                        height: 1.45,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
