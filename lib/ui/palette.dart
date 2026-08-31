import 'package:flutter/material.dart';

import '../models/sector.dart';

/// App design tokens.
///
/// Every colour, shadow and gradient the UI may use lives here so the
/// whole app stays on the design's periwinkle-primary system.
class Palette {
  Palette._();

  // Core accents
  static const Color primary = Color(0xFF9A9CEA);
  static const Color primaryLight = Color(0xFFA2B9EE);
  static const Color accentLight = Color(0xFFA2DCEE);

  // Text
  static const Color ink = Color(0xFF1E2240);
  static const Color body = Color(0xFF4A4F6E);
  static const Color muted = Color(0xFF6B7194);
  static const Color faint = Color(0xFF8A8FAD);
  static const Color ghost = Color(0xFF9AA0B5);

  // Surfaces & lines
  static const Color ground = Color(0xFFF5F6FB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color gridline = Color(0xFFEEF0F8);
  static const Color navLine = Color(0xFFE7E9F4);
  static const Color border = Color(0xFFD9DCEC);

  // Chips
  static const Color chipPeri = Color(0xFFECEDFB);
  static const Color chipGreenBg = Color(0xFFE4F7F1);
  static const Color chipCyanBg = Color(0xFFE8F7FB);
  static const Color riskBg = Color(0xFFFDE7EC);
  static const Color riskText = Color(0xFFD14D6B);

  // Semantic accents
  static const Color green = Color(0xFF177E6C);
  static const Color greenBar = Color(0xFFADEEE2);
  static const Color cyan = Color(0xFF48BEDC);
  static const Color cyanText = Color(0xFF2E96B4);
  static const Color periText = Color(0xFF5A5DC4);
  static const Color orange1 = Color(0xFFE8804D);
  static const Color orange2 = Color(0xFFF0A03C);

  // Shadows
  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x219A9CEA), // primary @ 13%
    blurRadius: 9,
    offset: Offset(0, 5),
  );
  static const BoxShadow heroShadow = BoxShadow(
    color: Color(0x599A9CEA), // primary @ 35%
    blurRadius: 14,
    offset: Offset(0, 9),
  );

  // Gradients
  static const LinearGradient gradHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
  static const LinearGradient gradDetail = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accentLight],
  );
  static const LinearGradient gradArea = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x479A9CEA), Color(0x059A9CEA)], // primary @ 28% -> @ 2%
  );

  /// One colour per sector for donut and bar charts, all drawn from the
  /// token palette.
  static const Map<Sector, Color> sectorColors = {
    Sector.agriculture: greenBar, // #ADEEE2
    Sector.mining: orange2, // #F0A03C
    Sector.manufacturing: primary, // #9A9CEA
    Sector.construction: primaryLight, // #A2B9EE
    Sector.services: accentLight, // #A2DCEE
    Sector.importDuties: orange1, // #E8804D
  };
}

/// RM million -> short money label, e.g. 110002 -> `RM 110.0B`,
/// 475.6 -> `RM 476m`.
String formatRm(double valueMillion) {
  if (valueMillion >= 1000) {
    return 'RM ${(valueMillion / 1000).toStringAsFixed(1)}B';
  }
  return 'RM ${valueMillion.toStringAsFixed(0)}m';
}
