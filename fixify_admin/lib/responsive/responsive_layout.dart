import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget desktopBody;

  const ResponsiveLayout({
    super.key,
    required this.mobileBody,
    required this.desktopBody,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Agar screen width 950 pixels se kam hai toh mobile view dikhao
        if (constraints.maxWidth < 950) {
          return mobileBody;
        } else {
          return desktopBody;
        }
      },
    );
  }
}