import 'package:flutter/material.dart';

import 'app_logo.dart';

class AppBarTitle extends StatelessWidget {
  final String title;
  const AppBarTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.rtl,
      children: [
        const AppLogo(size: 32, rounded: true),
        const SizedBox(width: 10),
        Flexible(
          child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
