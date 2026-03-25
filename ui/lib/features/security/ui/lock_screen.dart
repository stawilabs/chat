import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/biometric_service.dart';
import '../../../core/theme/app_theme.dart';

/// Lock screen shown when the app is locked
///
/// This screen displays only the app icon and provides a button to trigger
/// biometric authentication. It serves as a secure overlay that prevents
/// access to app content until the user authenticates.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({required this.onUnlock, super.key});

  /// Callback triggered when the user successfully authenticates
  final VoidCallback onUnlock;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with SingleTickerProviderStateMixin {
  bool _isAuthenticating = false;
  String? _errorMessage;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Automatically trigger authentication on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    final biometricService = ref.read(biometricServiceProvider);
    final result = await biometricService.authenticate(
      localizedReason: 'Authenticate to unlock the app',
    );

    if (!mounted) return;

    setState(() {
      _isAuthenticating = false;
    });

    switch (result) {
      case BiometricAuthResult.success:
        widget.onUnlock();
      case BiometricAuthResult.failed:
        setState(() {
          _errorMessage = 'Authentication failed. Please try again.';
        });
      case BiometricAuthResult.cancelled:
        setState(() {
          _errorMessage = 'Authentication cancelled.';
        });
      case BiometricAuthResult.notAvailable:
        setState(() {
          _errorMessage = 'Biometric authentication is not available.';
        });
      case BiometricAuthResult.notEnrolled:
        setState(() {
          _errorMessage =
              'No biometrics enrolled. Please set up biometrics in device settings.';
        });
      case BiometricAuthResult.lockedOut:
        setState(() {
          _errorMessage =
              'Too many failed attempts. Please try again later or use device PIN.';
        });
      case BiometricAuthResult.error:
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final biometricDescriptionAsync = ref.watch(biometricDescriptionProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.primaryGreen,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // App icon with pulse animation
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      size: 64,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // App name
                const Text(
                  'AntInvestor Chat',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 8),

                // Locked message
                Text(
                  'App is locked',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),

                const Spacer(),

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Unlock button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isAuthenticating ? null : _authenticate,
                    icon: _isAuthenticating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.fingerprint, size: 24),
                    label: Text(
                      _isAuthenticating ? 'Authenticating...' : 'Unlock',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Biometric type indicator
                biometricDescriptionAsync.when(
                  data: (description) => Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
