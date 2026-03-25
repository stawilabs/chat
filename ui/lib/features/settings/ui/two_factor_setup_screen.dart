import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/navigation/navigation_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../data/account_service.dart';

/// Screen for setting up two-factor authentication
class TwoFactorSetupScreen extends ConsumerStatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  ConsumerState<TwoFactorSetupScreen> createState() =>
      _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends ConsumerState<TwoFactorSetupScreen> {
  int _currentStep = 0;
  bool _is2FAEnabled = false;
  bool _isLoading = false;
  bool _isInitializing = true;
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();

  // 2FA setup data from server
  TwoFactorSetupData? _setupData;
  List<String> _backupCodes = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final service = ref.read(accountServiceProvider);
      final status = await service.get2FAStatus();

      if (mounted) {
        setState(() {
          _is2FAEnabled = status.isEnabled;
          _isInitializing = false;
        });

        // If already enabled, fetch backup codes
        if (status.isEnabled) {
          await _loadBackupCodes();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Failed to check 2FA status';
        });
      }
    }
  }

  Future<void> _loadBackupCodes() async {
    try {
      final service = ref.read(accountServiceProvider);
      final codes = await service.getBackupCodes();
      if (mounted) {
        setState(() => _backupCodes = codes);
      }
    } catch (e) {
      // Non-fatal, just log
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Two-Step Verification'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.navigateBack('/settings/account'),
        ),
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView(theme)
          : _is2FAEnabled
          ? _buildEnabledView(theme)
          : _buildSetupStepper(theme),
    );
  }

  Widget _buildErrorView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(_errorMessage ?? 'An error occurred'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _errorMessage = null;
                _isInitializing = true;
              });
              _initialize();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEnabledView(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.brightGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.brightGreen),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.brightGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Two-Step Verification is ON',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your account is protected with an extra layer of security.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Options
        _buildOptionTile(
          theme,
          icon: Icons.password,
          title: 'View backup codes',
          subtitle: 'See your recovery codes',
          onTap: () => _showBackupCodesDialog(context),
        ),

        _buildOptionTile(
          theme,
          icon: Icons.refresh,
          title: 'Regenerate backup codes',
          subtitle: 'Get new recovery codes',
          onTap: () => _showRegenerateCodesDialog(context),
        ),

        _buildOptionTile(
          theme,
          icon: Icons.remove_circle_outline,
          title: 'Turn off two-step verification',
          subtitle: 'Remove extra security layer',
          iconColor: Colors.red,
          onTap: () => _showDisable2FADialog(context),
        ),
      ],
    );
  }

  Widget _buildOptionTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? AppTheme.primaryGreen).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppTheme.primaryGreen,
            size: 24,
          ),
        ),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSetupStepper(ThemeData theme) {
    return Stepper(
      currentStep: _currentStep,
      onStepContinue: _handleStepContinue,
      onStepCancel: _handleStepCancel,
      controlsBuilder: (context, details) {
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            children: [
              if (_currentStep < 2)
                ElevatedButton(
                  onPressed: _isLoading ? null : details.onStepContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_currentStep == 1 ? 'Verify' : 'Next'),
                ),
              if (_currentStep == 2)
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Done'),
                ),
              const SizedBox(width: 12),
              if (_currentStep > 0 && _currentStep < 2)
                TextButton(
                  onPressed: details.onStepCancel,
                  child: const Text('Back'),
                ),
            ],
          ),
        );
      },
      steps: [
        Step(
          title: const Text('Set up authenticator'),
          subtitle: const Text('Scan QR code or enter key'),
          content: _buildStep1Content(theme),
          isActive: _currentStep >= 0,
          state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        ),
        Step(
          title: const Text('Verify code'),
          subtitle: const Text('Enter code from app'),
          content: _buildStep2Content(theme),
          isActive: _currentStep >= 1,
          state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        ),
        Step(
          title: const Text('Save backup codes'),
          subtitle: const Text('Keep these codes safe'),
          content: _buildStep3Content(theme),
          isActive: _currentStep >= 2,
          state: _currentStep > 2 ? StepState.complete : StepState.indexed,
        ),
      ],
    );
  }

  Widget _buildStep1Content(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Use an authenticator app like Google Authenticator, Authy, or 1Password '
          'to scan the QR code below.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),

        // QR Code
        Center(
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: _setupData != null
                ? QrImageView(
                    data: _setupData!.qrCodeUrl,
                    size: 180,
                  )
                : Center(
                    child: Icon(
                      Icons.qr_code_2,
                      size: 120,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // Manual entry option
        Text(
          'Can\'t scan? Enter this key manually:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _setupData?.secretKey ?? '',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: 'monospace',
                    letterSpacing: 2,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: _setupData?.secretKey ?? ''),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Key copied to clipboard'),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                },
                tooltip: 'Copy key',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Content(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter the 6-digit code from your authenticator app to verify setup.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),

        // Code input
        TextField(
          controller: _codeController,
          focusNode: _codeFocusNode,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            letterSpacing: 8,
            fontFamily: 'monospace',
          ),
          decoration: InputDecoration(
            hintText: '000000',
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),

        const SizedBox(height: 16),

        Text(
          'Code refreshes every 30 seconds',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Content(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Save these codes in a safe place. You can use them to access '
                  'your account if you lose access to your authenticator app.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Backup codes grid
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: _backupCodes
                    .map(
                      (code) => Text(
                        code,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: _backupCodes.join('\n')),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Backup codes copied to clipboard'),
                          backgroundColor: AppTheme.primaryGreen,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy codes'),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Each backup code can only be used once.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Future<void> _handleStepContinue() async {
    if (_currentStep == 0) {
      await _initiate2FASetup();
    } else if (_currentStep == 1) {
      await _verifyCode();
    } else if (_currentStep == 2) {
      setState(() => _is2FAEnabled = true);
      ref.invalidate(twoFactorStatusProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Two-step verification enabled!'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  Future<void> _initiate2FASetup() async {
    setState(() => _isLoading = true);

    try {
      final service = ref.read(accountServiceProvider);
      final setupData = await service.initiate2FASetup();

      if (!mounted) return;

      if (setupData != null) {
        setState(() {
          _setupData = setupData;
          _currentStep = 1;
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _codeFocusNode.requestFocus();
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to initiate 2FA setup'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a 6-digit code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = ref.read(accountServiceProvider);
      final success = await service.verify2FACode(code);

      if (!mounted) return;

      if (success) {
        // Fetch backup codes after successful verification
        final codes = await service.getBackupCodes();

        setState(() {
          _backupCodes = codes;
          _currentStep = 2;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid code. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBackupCodesDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Codes'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Use these codes to sign in if you lose access to your authenticator app. '
                'Each code can only be used once.',
              ),
              const SizedBox(height: 16),
              ..._backupCodes.map(
                (code) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _backupCodes.join('\n')));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Backup codes copied'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRegenerateCodesDialog(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Regenerate Backup Codes'),
        content: const Text(
          'This will invalidate all your current backup codes and generate new ones. '
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();

              try {
                final service = ref.read(accountServiceProvider);
                final newCodes = await service.regenerateBackupCodes();

                if (mounted && newCodes.isNotEmpty) {
                  setState(() => _backupCodes = newCodes);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('New backup codes generated'),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                  // Show the new codes
                  _showBackupCodesDialog(this.context);
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to regenerate codes: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDisable2FADialog(BuildContext context) async {
    final codeController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Turn Off Two-Step Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your current 2FA code to disable two-step verification.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Verification code',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Warning: This will reduce the security of your account.',
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.length != 6) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a 6-digit code'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.of(dialogContext).pop();

              try {
                final service = ref.read(accountServiceProvider);
                final success = await service.disable2FA(code);

                if (mounted) {
                  if (success) {
                    setState(() => _is2FAEnabled = false);
                    ref.invalidate(twoFactorStatusProvider);
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Two-step verification disabled'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Invalid code. Please try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to disable 2FA: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    codeController.dispose();
  }
}
