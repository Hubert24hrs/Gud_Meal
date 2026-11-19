import 'package:flutter/material.dart';

/// The Yummy Chops logo (assets/brand, made by scripts/make-brand-assets.py from assets/brand/yummychops-logo.webp).
/// It sits on white, as in the logo itself, so it reads in dark mode too.
class YummyChopsLogo extends StatelessWidget {
  const YummyChopsLogo({super.key, this.height = 132});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Yummy Chops',
      image: true,
      child: Container(
        padding: EdgeInsets.all(height * .06),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(height * .14)),
        child: ExcludeSemantics(child: Image.asset('assets/brand/yummychops-logo.png', height: height, filterQuality: FilterQuality.medium)),
      ),
    );
  }
}
