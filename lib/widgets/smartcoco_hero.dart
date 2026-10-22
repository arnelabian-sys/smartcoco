import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// SmartCoco brand colors (shared by the homepage + auth screens).
/// ---------------------------------------------------------------------------
class SmartCocoColors {
  static const darkGreen = Color(0xFF0B4D2C); // "Smart"
  static const leafGreen = Color(0xFF4C9A2A); // "Coco"
  static const lightLeaf = Color(0xFF6DB33F);
  static const shellBrown = Color(0xFF5A3A1E);
  static const cream = Color(0xFFF3E9D8);
  static const textGreen = Color(0xFF14532D);
}

/// ---------------------------------------------------------------------------
/// FULL HERO — background image only.
/// Ang logo, text, ug feature widgets tangtanga na; ang Register / Log in
/// buttons gikan sa HomeScreen nga naka-overlay sa taas.
/// ---------------------------------------------------------------------------
class SmartCocoHero extends StatelessWidget {
  /// Reused background image. Override if a different one is wanted.
  final String backgroundAsset;

  const SmartCocoHero({
    super.key,
    this.backgroundAsset = 'assets/images/smartcoco_background.png',
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image (text-free version).
        Image.asset(
          backgroundAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFBFE3F7),
                  Color(0xFFEAF6FC),
                  Color(0xFF2E7D32),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),

        // Soft light scrim at the very top so the overlaid buttons stay
        // readable, fading out towards the middle of the image.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.45),
                Colors.white.withOpacity(0.18),
                Colors.white.withOpacity(0.0),
              ],
              stops: const [0.0, 0.18, 0.4],
            ),
          ),
        ),
      ],
    );
  }
}
