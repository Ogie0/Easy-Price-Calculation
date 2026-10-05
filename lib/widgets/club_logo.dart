import 'package:flutter/material.dart';

import '../theme.dart';

/// Vereinslogo. Wird nur in der angezeigten Größe dekodiert statt in voller
/// Auflösung; das spart Speicher und Rechenzeit beim Zeichnen.
class ClubLogo extends StatelessWidget {
  final double height;

  const ClubLogo({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      kClubLogo,
      height: height,
      cacheHeight: (height * MediaQuery.devicePixelRatioOf(context)).ceil(),
    );
  }
}
