import 'package:flutter/material.dart';

/// The GudMeals logo (assets/brand, made by scripts/make-brand-assets.py from assets/brand/gudmeals-logo.webp).
/// It sits on white, as in the logo itself, so it reads in dark mode too.
class GudMealsLogo extends StatelessWidget {
  const GudMealsLogo({super.key, this.height = 132});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'GudMeals',
      image: true,
      child: Container(
        padding: EdgeInsets.all(height * .06),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(height * .14)),
        child: ExcludeSemantics(child: Image.asset('assets/brand/gudmeals-logo.png', height: height, filterQuality: FilterQuality.medium)),
      ),
    );
  }
}
