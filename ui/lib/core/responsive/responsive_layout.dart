import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// A widget that displays different layouts based on screen size
///
/// This widget automatically selects the appropriate layout based on
/// the current screen width using the defined breakpoints:
/// - Mobile (< 600px): mobileLayout
/// - Tablet (600-1200px): tabletLayout
/// - Desktop (>= 1200px): desktopLayout
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.mobileLayout,
    required this.tabletLayout,
    required this.desktopLayout,
    super.key,
  });
  final Widget mobileLayout;
  final Widget tabletLayout;
  final Widget desktopLayout;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (AppBreakpoints.isMobile(width)) {
      return mobileLayout;
    } else if (AppBreakpoints.isTablet(width)) {
      return tabletLayout;
    } else {
      return desktopLayout;
    }
  }
}
