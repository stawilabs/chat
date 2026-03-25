// ignore_for_file: avoid_dynamic_calls

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/navigation/navigation_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/profile_image_picker.dart';
import '../../auth/data/user_info_provider.dart';
import '../data/profile_repository.dart';
import '../domain/user_status.dart';

/// Screen for editing user profile information
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _statusMessageController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  PickedImage? _selectedImage;
  String? _currentAvatarUrl;
  bool _isRemovingPhoto = false;
  List<ContactInfo> _contacts = [];
  UserStatus _currentStatus = UserStatus.offline;
  String? _originalStatusMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _statusMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final userInfo = await ref.read(userInfoProvider.future);
      final profileRepo = ref.read(profileRepositoryProvider);

      if (userInfo != null) {
        _displayNameController.text = userInfo.displayName;
        _currentAvatarUrl = userInfo.picture;
      }

      // Load bio from local profile metadata
      final bio = await profileRepo.getCurrentBio();
      if (bio != null) {
        _bioController.text = bio;
      }

      // Load status
      _currentStatus = await profileRepo.getCurrentStatus();
      final statusMessage = await profileRepo.getCurrentStatusMessage();
      if (statusMessage != null) {
        _statusMessageController.text = statusMessage;
        _originalStatusMessage = statusMessage;
      }

      // Load contacts
      _contacts = await profileRepo.getContacts();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to load profile',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        _showError('Failed to load profile. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onImagePicked(PickedImage image) {
    setState(() {
      _selectedImage = image;
      _isRemovingPhoto = false;
    });
  }

  void _removePhoto() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Photo'),
        content: const Text(
          'Are you sure you want to remove your profile photo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedImage = null;
                _currentAvatarUrl = null;
                _isRemovingPhoto = true;
              });
            },
            child: Text('Remove', style: TextStyle(color: Colors.red.shade600)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      final userInfo = await ref.read(userInfoProvider.future);

      // Update each field independently
      final nameUpdated = await _updateDisplayName(profileRepo, userInfo);
      if (!nameUpdated) return;

      final bioUpdated = await _updateBio(profileRepo);
      if (!bioUpdated) return;

      final statusUpdated = await _updateStatus(profileRepo);
      if (!statusUpdated) return;

      final photoUpdated = await _updateProfilePhoto(profileRepo);
      if (!photoUpdated) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppTheme.brightGreen,
          ),
        );
        context.navigateBack();
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to save profile',
        error: e,
        stackTrace: stackTrace,
      );
      _showError('Failed to save profile. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Updates display name if changed. Returns false if update failed.
  Future<bool> _updateDisplayName(
    ProfileRepository profileRepo,
    userInfo,
  ) async {
    if (_displayNameController.text.isNotEmpty &&
        _displayNameController.text != userInfo?.displayName) {
      final result = await profileRepo.updateDisplayName(
        _displayNameController.text,
      );
      if (!result.success) {
        _showError('Failed to update name. Please try again.');
        return false;
      }
    }
    return true;
  }

  /// Updates bio if not empty. Returns false if update failed.
  Future<bool> _updateBio(ProfileRepository profileRepo) async {
    if (_bioController.text.isNotEmpty) {
      final result = await profileRepo.updateBio(_bioController.text);
      if (!result.success) {
        _showError('Failed to update bio. Please try again.');
        return false;
      }
    }
    return true;
  }

  /// Updates status if changed. Returns false if update failed.
  Future<bool> _updateStatus(ProfileRepository profileRepo) async {
    final currentStatusMessage = _statusMessageController.text.trim();
    final hasStatusChanged =
        _currentStatus != UserStatus.offline ||
        currentStatusMessage != (_originalStatusMessage ?? '');

    if (hasStatusChanged) {
      final result = await profileRepo.updateStatus(
        _currentStatus,
        statusMessage: currentStatusMessage.isNotEmpty
            ? currentStatusMessage
            : null,
      );
      if (!result.success) {
        _showError('Failed to update status. Please try again.');
        return false;
      }
    }
    return true;
  }

  /// Updates profile photo if selected. Returns false if update failed.
  Future<bool> _updateProfilePhoto(ProfileRepository profileRepo) async {
    if (_isRemovingPhoto) {
      return true;
    }
    if (_selectedImage != null) {
      final result = await profileRepo.updateProfilePhotoBytes(
        _selectedImage!.bytes,
      );
      if (!result.success) {
        _showError('Failed to update photo. Please try again.');
        return false;
      }
    }
    return true;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showAddEmailDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Email'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'example@email.com',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final email = controller.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                return;
              }
              Navigator.pop(context);
              await _addEmail(email);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddPhoneDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Phone'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: '+1234567890',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final phone = controller.text.trim();
              if (phone.isEmpty) {
                return;
              }
              Navigator.pop(context);
              await _addPhone(phone);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addEmail(String email) async {
    setState(() => _isSaving = true);
    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      final result = await profileRepo.addEmail(email);
      if (result.success) {
        await _loadProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email added successfully')),
          );
        }
      } else {
        _showError(result.errorMessage ?? 'Failed to add email');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _addPhone(String phone) async {
    setState(() => _isSaving = true);
    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      final result = await profileRepo.addPhone(phone);
      if (result.success) {
        await _loadProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone added successfully')),
          );
        }
      } else {
        _showError(result.errorMessage ?? 'Failed to add phone');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _removeContact(ContactInfo contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Contact'),
        content: Text('Are you sure you want to remove ${contact.value}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      setState(() => _isSaving = true);
      try {
        final profileRepo = ref.read(profileRepositoryProvider);
        final result = await profileRepo.removeContact(contact.id);
        if (result.success) {
          await _loadProfile();
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Contact removed')));
          }
        } else {
          _showError(result.errorMessage ?? 'Failed to remove contact');
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  /// Start verification process for a contact
  Future<void> _startVerification(ContactInfo contact) async {
    setState(() => _isSaving = true);
    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      final result = await profileRepo.startContactVerification(contact.id);

      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Verification code sent to ${contact.value}'),
            ),
          );
          _showVerificationCodeDialog(contact);
        }
      } else {
        _showError(result.errorMessage ?? 'Failed to send verification code');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Show dialog to enter verification code
  void _showVerificationCodeDialog(ContactInfo contact) {
    final codeController = TextEditingController();
    var isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Enter Verification Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A verification code has been sent to:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                contact.value,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  labelText: 'Verification Code',
                  hintText: '000000',
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                enabled: !isVerifying,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isVerifying
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: isVerifying
                  ? null
                  : () async {
                      final code = codeController.text.trim();
                      if (code.isEmpty || code.length != 6) {
                        return;
                      }

                      setDialogState(() => isVerifying = true);

                      final result = await _verifyContact(contact, code);

                      if (result) {
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      } else {
                        setDialogState(() => isVerifying = false);
                      }
                    },
              child: isVerifying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verify'),
            ),
          ],
        ),
      ),
    ).whenComplete(codeController.dispose);
  }

  /// Submit verification code
  Future<bool> _verifyContact(ContactInfo contact, String code) async {
    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      final result = await profileRepo.verifyContact(contact.id, code);

      if (result.success) {
        await _loadProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${contact.value} verified successfully'),
              backgroundColor: AppTheme.brightGreen,
            ),
          );
        }
        return true;
      } else {
        _showError(result.errorMessage ?? 'Invalid verification code');
        return false;
      }
    } catch (e) {
      _showError('Verification failed: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.navigateBack(),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Photo Section
                  _buildPhotoSection(theme),
                  const SizedBox(height: 24),

                  // Display Name Section
                  _buildSection(
                    theme,
                    title: 'Display Name',
                    child: TextField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bio Section
                  _buildSection(
                    theme,
                    title: 'About',
                    child: TextField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        hintText: 'Write something about yourself',
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      maxLines: 3,
                      maxLength: 200,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Status Section
                  _buildStatusSection(theme),
                  const SizedBox(height: 24),

                  // Email Section
                  _buildContactSection(
                    theme,
                    title: 'Email Addresses',
                    icon: Icons.email_outlined,
                    contacts: _contacts.where(
                      (c) => c.type == ContactType.email,
                    ),
                    onAdd: _showAddEmailDialog,
                  ),
                  const SizedBox(height: 16),

                  // Phone Section
                  _buildContactSection(
                    theme,
                    title: 'Phone Numbers',
                    icon: Icons.phone_outlined,
                    contacts: _contacts.where(
                      (c) => c.type == ContactType.phone,
                    ),
                    onAdd: _showAddPhoneDialog,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildPhotoSection(ThemeData theme) => Center(
    child: Column(
      children: [
        Stack(
          children: [
            ProfileImagePicker(
              onImagePicked: _onImagePicked,
              currentImageUrl: _currentAvatarUrl,
              size: 120,
            ),
            if (_currentAvatarUrl != null || _selectedImage != null)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _removePhoto,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _selectedImage != null || _currentAvatarUrl != null
              ? 'Tap to change photo'
              : 'Tap to add a photo',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );

  Widget _buildSection(
    ThemeData theme, {
    required String title,
    required Widget child,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryGreen,
        ),
      ),
      const SizedBox(height: 8),
      child,
    ],
  );

  Widget _buildStatusSection(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Status',
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryGreen,
        ),
      ),
      const SizedBox(height: 12),
      // Status selection chips
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: UserStatus.values.map((status) {
          final isSelected = _currentStatus == status;
          return ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status.icon,
                  size: 16,
                  color: isSelected ? Colors.white : status.color,
                ),
                const SizedBox(width: 6),
                Text(status.label),
              ],
            ),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() => _currentStatus = status);
              }
            },
            selectedColor: status.color,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : theme.colorScheme.onSurface,
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 16),
      // Status description
      Text(
        _currentStatus.shortDescription,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
      const SizedBox(height: 16),
      // Custom status message
      TextField(
        controller: _statusMessageController,
        decoration: InputDecoration(
          hintText: 'Set a custom status message',
          prefixIcon: const Icon(Icons.edit_note),
          suffixIcon: _statusMessageController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(_statusMessageController.clear);
                  },
                )
              : null,
        ),
        maxLength: 100,
        onChanged: (_) => setState(() {}),
      ),
    ],
  );

  Widget _buildContactSection(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required Iterable<ContactInfo> contacts,
    required VoidCallback onAdd,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryGreen,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: AppTheme.primaryGreen,
            onPressed: onAdd,
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (contacts.isEmpty)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Text(
                'No ${title.toLowerCase()} added',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        )
      else
        ...contacts.map((contact) => _buildContactTile(theme, contact)),
    ],
  );

  Widget _buildContactTile(ThemeData theme, ContactInfo contact) => Container(
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
      leading: Icon(
        contact.type == ContactType.email
            ? Icons.email_outlined
            : Icons.phone_outlined,
        color: AppTheme.primaryGreen,
      ),
      title: Text(contact.value),
      subtitle: Row(
        children: [
          if (contact.isVerified)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified,
                  size: 14,
                  color: AppTheme.brightGreen,
                ),
                const SizedBox(width: 4),
                Text(
                  'Verified',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.brightGreen,
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_outlined,
                  size: 14,
                  color: Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  'Not verified',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          if (contact.isPrimary) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Primary',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Verify button for unverified contacts
          if (!contact.isVerified)
            TextButton.icon(
              onPressed: _isSaving ? null : () => _startVerification(contact),
              icon: const Icon(Icons.verified_user_outlined, size: 16),
              label: const Text('Verify'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: Colors.red.shade400,
            onPressed: _isSaving ? null : () => _removeContact(contact),
          ),
        ],
      ),
    ),
  );
}
