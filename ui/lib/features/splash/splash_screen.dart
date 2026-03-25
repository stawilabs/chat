import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/startup/startup_service.dart';

/// Wrapper that triggers app initialization on startup.
///
/// Shows the child immediately without displaying a splash screen.
/// Initialization runs in the background.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Start initialization in the background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(startupServiceProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch progress to keep initialization running
    ref.watch(startupServiceProvider);

    // Show the app immediately without waiting for initialization
    return widget.child;
  }
}
