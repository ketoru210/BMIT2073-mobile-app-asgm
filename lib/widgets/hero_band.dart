import 'package:flutter/material.dart';

import '../ui/palette.dart';

/// Full-width gradient band at the top of result pages
///
/// Contents: white back arrow (pops), eyebrow, title, subtitle —
/// plus optional [trailing] (top-right, e.g. the year pill on the
/// breakdown page) and [footer] (below the title, e.g. the
/// "Sector composition" chip).
class HeroBand extends StatelessWidget {
  const HeroBand({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.gradient = Palette.gradHero,
    this.height = 168,
    this.titleSize = 21,
    this.showBack = true,
    this.trailing,
    this.footer,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final LinearGradient gradient;

  /// Band height: ~168 for the comparison/diversity pages,
  /// ~210 for the breakdown page.
  final double height;

  /// Title font size: 21 default, 27 on the breakdown page.
  final double titleSize;
  final bool showBack;
  final Widget? trailing;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    // add the status bar inset on top of the design height
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      height: height + topInset,
      decoration: BoxDecoration(gradient: gradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showBack) const _BackArrow(),
                  const Spacer(),
                  trailing ?? const SizedBox(),
                ],
              ),
              const Spacer(),
              Text(
                eyebrow,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.82),
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 5),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
              if (footer != null) ...[const SizedBox(height: 14), footer!],
            ],
          ),
        ),
      ),
    );
  }
}

/// White chevron-left that pops the route.
class _BackArrow extends StatelessWidget {
  const _BackArrow();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: () => Navigator.of(context).maybePop(),
      icon: const Icon(
        Icons.chevron_left_rounded,
        color: Colors.white,
        size: 30,
      ),
    );
  }
}
