import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../data/auth_state_provider.dart';

/// Login screen that presents an OpenID Connect button to users
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    // Check connectivity first
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      setState(() {
        _errorMessage =
            'No internet connection. Please connect to the internet and try again.';
      });
      AppLogger.warning('Login attempted while offline');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      AppLogger.debug('Starting login process...');
      await ref.read(authStateProvider.notifier).login();

      // Check if login was successful
      final authState = ref.read(authStateProvider);
      final isAuthenticated = authState.when(
        data: (state) => state == AuthState.authenticated,
        loading: () => false,
        error: (_, _) => false,
      );

      if (isAuthenticated) {
        AppLogger.info(
          'Login successful, navigation will be handled by router',
        );
        // Navigation will be handled by router redirect
      } else {
        AppLogger.warning('Login completed but state is not authenticated');
        if (mounted) {
          setState(() {
            _errorMessage = 'Login incomplete. Please try again.';
            _isLoading = false;
          });
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'User login attempt failed',
        error: e,
        stackTrace: stackTrace,
      );

      // Provide better error messages based on error type
      var errorMessage = 'Authentication failed. Please try again.';

      final errorStr = e.toString().toLowerCase();

      // Check for common network-related errors
      if (e is SocketException ||
          errorStr.contains('socketexception') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('network is unreachable')) {
        errorMessage =
            'Cannot connect to server. Please check your internet connection.';
      } else if (errorStr.contains('404')) {
        errorMessage =
            'Authentication service unavailable. Please try again later.';
      } else if (errorStr.contains('timeout') ||
          errorStr.contains('timeoutexception')) {
        errorMessage =
            'Connection timed out. Please check your internet connection.';
      } else if (errorStr.contains('could not launch')) {
        errorMessage =
            'Unable to open web browser. Please check your device settings.';
      } else if (errorStr.contains('oauth error')) {
        // Extract the actual OAuth error message
        final match = RegExp('oauth error: (.+)').firstMatch(errorStr);
        errorMessage = match != null
            ? 'Authentication error: ${match.group(1)}'
            : 'Authentication was denied. Please try again.';
      } else if (errorStr.contains('cancelled') ||
          errorStr.contains('canceled')) {
        errorMessage = 'Authentication was cancelled.';
      } else if (errorStr.contains('code exchange failed')) {
        errorMessage = 'Failed to complete authentication. Please try again.';
      } else if (errorStr.contains('no access token')) {
        errorMessage =
            'Authentication server did not return a valid token. Please try again.';
      } else if (errorStr.contains('could not save credentials')) {
        errorMessage =
            'Failed to save login credentials. Please check app permissions.';
      }

      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Logo / Icon
                // Use light banner on dark theme, dark banner on light theme
                Hero(
                  tag: 'info-logo',
                  child: Image.asset(
                    theme.brightness == Brightness.dark
                        ? 'assets/banner_transparent.png' // Light banner for dark background
                        : 'assets/banner_transparent_black.png', // Dark banner for light background
                  ),
                ),
                const SizedBox(height: 12),

                const SizedBox(height: 64),

                // Error message if any
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Login Button
                FilledButton.icon(
                  onPressed: _isLoading ? null : _handleLogin,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login),
                  label: Text(_isLoading ? 'Signing in...' : 'Get started'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Info text
                Text(
                  'By signing in, you agree to our terms of service and privacy policy',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
