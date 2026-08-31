import 'package:flutter/material.dart';

import '../ui/palette.dart';

/// Bottom tab bar: white, 1px top border, three destinations.
/// The active tab is shown in the primary colour with a bolder label.
class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.activeIndex,
    required this.onSelect,
  });

  final int activeIndex;
  final ValueChanged<int> onSelect;

  static const _titles = ['Home', 'Analyze', 'About'];
  static const _icons = [
    Icons.home_outlined,
    Icons.bar_chart_rounded,
    Icons.info_outline_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      decoration: const BoxDecoration(
        color: Palette.card,
        border: Border(top: BorderSide(color: Palette.navLine)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (var i = 0; i < _titles.length; i++)
              Expanded(
                child: _NavItem(
                  title: _titles[i],
                  icon: _icons[i],
                  active: i == activeIndex,
                  onTap: () => onSelect(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One destination: icon on top, 10px label below.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.title,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? Palette.primary : Palette.ghost;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
