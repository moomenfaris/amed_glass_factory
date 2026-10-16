import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Displays the brand logo at [size]. If the asset is missing (e.g. while the
/// user hasn't dropped logo.png yet), falls back to a styled placeholder so
/// the UI still renders correctly.
class AppLogo extends StatelessWidget {
  final double size;
  final bool rounded;
  const AppLogo({super.key, this.size = 96, this.rounded = true});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.22);
    final image = Image.asset(
      'assets/img/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, e, s) => _Placeholder(size: size, radius: radius),
    );

    if (!rounded) return image;
    return ClipRRect(borderRadius: radius, child: image);
  }
}

class _Placeholder extends StatelessWidget {
  final double size;
  final BorderRadius radius;
  const _Placeholder({required this.size, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.brandDark, AppTheme.brandMid],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: radius,
      ),
      alignment: Alignment.center,
      child: Icon(Icons.diamond_outlined,
          color: Colors.white, size: size * 0.5),
    );
  }
}
