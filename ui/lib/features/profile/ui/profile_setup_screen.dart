import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/profile_image_picker.dart';
import '../../auth/data/user_info_provider.dart';
import '../../onboarding/data/onboarding_repository.dart';
import '../data/profile_repository.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _displayNameController = TextEditingController();

  PickedImage? _selectedImage;
  String? _currentAvatarUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasExistingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final userInfo = await ref.read(userInfoProvider.future);
      if (userInfo != null) {
        _displayNameController.text = userInfo.displayName;
        _currentAvatarUrl = userInfo.picture;
        _hasExistingAvatar = userInfo.picture != null;
      }
    } catch (e) {
      AppLogger.warning('Failed to load profile for setup', error: e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onImagePicked(PickedImage image) {
    setState(() {
      _selectedImage = image;
    });
  }

  Future<void> _saveAndContinue() async {
    if (_isSaving) return;

    if (!_hasExistingAvatar && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a profile photo to continue')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final profileRepo = ref.read(profileRepositoryProvider);

      if (_selectedImage != null) {
        AppLogger.debug(
          'Uploading profile photo, size: ${_selectedImage!.bytes.length} bytes',
        );

        final result = await profileRepo
            .updateProfilePhotoBytes(_selectedImage!.bytes)
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                AppLogger.warning('Profile photo upload timed out');
                throw Exception(
                  'Upload timed out. Please check your connection and try again.',
                );
              },
            );

        AppLogger.debug(
          'Upload result: success=${result.success}, error=${result.errorMessage}',
        );

        if (!result.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result.errorMessage ??
                      'Failed to upload photo. Please try again.',
                ),
              ),
            );
          }
          return;
        }
      } else {
        AppLogger.debug('No new image selected, using existing avatar');
      }

      final onboarding = ref.read(onboardingRepositoryProvider);
      await onboarding.markProfileSetupComplete();

      if (mounted) context.go('/');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Profile setup save failed',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final requiresPhoto = !_hasExistingAvatar;

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    Text(
                      'Set up your profile',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      requiresPhoto
                          ? 'Add a profile photo so your contacts can recognize you'
                          : 'You can update your profile photo or continue',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const Spacer(),

                    ProfileImagePicker(
                      onImagePicked: _onImagePicked,
                      currentImageUrl: _currentAvatarUrl,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _displayNameController.text,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const Spacer(flex: 2),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _saveAndContinue,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                requiresPhoto ? 'Continue' : 'Save & Continue',
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}
