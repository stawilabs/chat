import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/navigation_helper.dart';
import '../../../core/security/screenshot_prevention_service.dart';
import '../../../core/settings/settings_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../contacts/data/roster_repository.dart';
import 'visibility_picker.dart';

/// Privacy settings screen with all privacy options
class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() =>
      _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  late SettingsService _settingsService;
  bool _isInitialized = false;

  // Settings values
  String _lastSeenVisible = SettingsDefaults.lastSeenVisible;
  String _profilePhotoVisible = SettingsDefaults.profilePhotoVisible;
  String _aboutVisible = SettingsDefaults.aboutVisible;
  String _groupsAddPermission = SettingsDefaults.groupsAddPermission;
  bool _readReceiptsEnabled = SettingsDefaults.readReceiptsEnabled;
  bool _liveLocationSharingEnabled =
      SettingsDefaults.liveLocationSharingEnabled;
  bool _fingerprintLockEnabled = SettingsDefaults.fingerprintLockEnabled;
  bool _screenshotPreventionEnabled = false;
  bool _analyticsEnabled = true;

  @override
  void initState() {
    super.initState();
    _initSettings();
  }

  Future<void> _initSettings() async {
    _settingsService = ref.read(settingsServiceProvider);
    await _settingsService.initialize();

    final screenshotService = ref.read(screenshotPreventionServiceProvider);

    if (mounted) {
      setState(() {
        _lastSeenVisible = _settingsService.lastSeenVisible;
        _profilePhotoVisible = _settingsService.profilePhotoVisible;
        _aboutVisible = _settingsService.aboutVisible;
        _groupsAddPermission = _settingsService.groupsAddPermission;
        _readReceiptsEnabled = _settingsService.readReceiptsEnabled;
        _liveLocationSharingEnabled =
            _settingsService.liveLocationSharingEnabled;
        _fingerprintLockEnabled = _settingsService.fingerprintLockEnabled;
        _screenshotPreventionEnabled = screenshotService.isEnabled;
        _analyticsEnabled = _settingsService.analyticsEnabled;
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final blockedCountAsync = ref.watch(blockedRosterEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.navigateBack('/settings'),
        ),
      ),
      body: !_isInitialized
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryGreen,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Who can see my personal info section
                _buildSettingsSection(
                  context,
                  title: 'Who can see my personal info',
                  items: [
                    VisibilityPicker(
                      title: 'Last seen',
                      description:
                          'Choose who can see when you were last '
                          'active on Chat.',
                      currentValue: _lastSeenVisible,
                      onChanged: _updateLastSeenVisibility,
                    ),
                    VisibilityPicker(
                      title: 'Profile photo',
                      description: 'Choose who can see your profile photo.',
                      currentValue: _profilePhotoVisible,
                      onChanged: _updateProfilePhotoVisibility,
                    ),
                    VisibilityPicker(
                      title: 'About',
                      description:
                          'Choose who can see your about/bio information.',
                      currentValue: _aboutVisible,
                      onChanged: _updateAboutVisibility,
                    ),
                  ],
                ),

                // Groups section
                _buildSettingsSection(
                  context,
                  title: 'Groups',
                  items: [
                    VisibilityPicker(
                      title: 'Who can add me to groups',
                      description: 'Control who can add you to group chats.',
                      currentValue: _groupsAddPermission,
                      onChanged: _updateGroupsAddPermission,
                    ),
                  ],
                ),

                // Blocking section
                _buildSettingsSection(
                  context,
                  title: 'Blocking',
                  items: [
                    _buildSettingsItem(
                      context,
                      title: 'Blocked contacts',
                      subtitle: blockedCountAsync.when(
                        data: (blocked) =>
                            '${blocked.length} contact${blocked.length == 1 ? '' : 's'}',
                        loading: () => 'Loading...',
                        error: (error, stackTrace) => 'Error loading',
                      ),
                      onTap: () => Navigator.of(
                        context,
                      ).push(_createBlockedContactsRoute()),
                    ),
                  ],
                ),

                // Read receipts section
                _buildSettingsSection(
                  context,
                  title: 'Read receipts',
                  items: [
                    _buildSwitchItem(
                      context,
                      title: 'Read receipts',
                      subtitle:
                          'If turned off, you won\'t send or receive read receipts. '
                          'Read receipts are always sent in group chats.',
                      value: _readReceiptsEnabled,
                      onChanged: _toggleReadReceipts,
                    ),
                  ],
                ),

                // Live location section
                _buildSettingsSection(
                  context,
                  title: 'Live location',
                  items: [
                    _buildSwitchItem(
                      context,
                      title: 'Live location sharing',
                      subtitle:
                          'Allow others to request your live location. '
                          'You can still choose whether to share for each request.',
                      value: _liveLocationSharingEnabled,
                      onChanged: _toggleLiveLocationSharing,
                    ),
                  ],
                ),

                // Security section
                _buildSettingsSection(
                  context,
                  title: 'Security',
                  items: [
                    _buildSwitchItem(
                      context,
                      title: 'Fingerprint lock',
                      subtitle:
                          'Require fingerprint or face recognition to open Chat. '
                          'You can still answer calls when Chat is locked.',
                      value: _fingerprintLockEnabled,
                      onChanged: _toggleFingerprintLock,
                    ),
                    _buildSwitchItem(
                      context,
                      title: 'Screenshot prevention',
                      subtitle:
                          'Prevent screenshots and screen recording in the app. '
                          'This helps protect your conversations from being captured.',
                      value: _screenshotPreventionEnabled,
                      onChanged: _toggleScreenshotPrevention,
                    ),
                  ],
                ),

                // Data & Analytics section
                _buildSettingsSection(
                  context,
                  title: 'Data & Analytics',
                  items: [
                    _buildSwitchItem(
                      context,
                      title: 'Usage analytics',
                      subtitle:
                          'Help improve Chat by sharing anonymous usage data. '
                          'This includes app crashes and feature usage, never message content.',
                      value: _analyticsEnabled,
                      onChanged: _toggleAnalytics,
                    ),
                  ],
                ),

                // Info section
                _buildInfoSection(context),
              ],
            ),
    );
  }

  Route<void> _createBlockedContactsRoute() {
    // Dynamically import to avoid circular dependencies
    return MaterialPageRoute(
      builder: (context) {
        // Lazy import the blocked contacts list
        return Consumer(
          builder: (context, ref, _) {
            return const _BlockedContactsListWrapper();
          },
        );
      },
    );
  }

  void _updateLastSeenVisibility(String value) {
    setState(() => _lastSeenVisible = value);
    _settingsService.setLastSeenVisible(value);
    _showSettingsSavedSnackBar('Last seen visibility');
  }

  void _updateProfilePhotoVisibility(String value) {
    setState(() => _profilePhotoVisible = value);
    _settingsService.setProfilePhotoVisible(value);
    _showSettingsSavedSnackBar('Profile photo visibility');
  }

  void _updateAboutVisibility(String value) {
    setState(() => _aboutVisible = value);
    _settingsService.setAboutVisible(value);
    _showSettingsSavedSnackBar('About visibility');
  }

  void _updateGroupsAddPermission(String value) {
    setState(() => _groupsAddPermission = value);
    _settingsService.setGroupsAddPermission(value);
    _showSettingsSavedSnackBar('Groups add permission');
  }

  void _toggleReadReceipts(bool value) {
    setState(() => _readReceiptsEnabled = value);
    _settingsService.setReadReceiptsEnabled(value);
    _showSettingsSavedSnackBar('Read receipts');
  }

  void _toggleLiveLocationSharing(bool value) {
    setState(() => _liveLocationSharingEnabled = value);
    _settingsService.setLiveLocationSharingEnabled(value);
    _showSettingsSavedSnackBar('Live location sharing');
  }

  void _toggleFingerprintLock(bool value) {
    setState(() => _fingerprintLockEnabled = value);
    _settingsService.setFingerprintLockEnabled(value);
    _showSettingsSavedSnackBar('Fingerprint lock');
  }

  Future<void> _toggleScreenshotPrevention(bool value) async {
    final screenshotService = ref.read(screenshotPreventionServiceProvider);
    bool success;
    if (value) {
      success = await screenshotService.enableScreenshotPrevention();
    } else {
      success = await screenshotService.disableScreenshotPrevention();
    }
    if (success) {
      setState(() => _screenshotPreventionEnabled = value);
      _showSettingsSavedSnackBar('Screenshot prevention');
    }
  }

  void _toggleAnalytics(bool value) {
    setState(() => _analyticsEnabled = value);
    _settingsService.setAnalyticsEnabled(value);
    _showSettingsSavedSnackBar('Usage analytics');
  }

  void _showSettingsSavedSnackBar(String settingName) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$settingName updated'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryGreen,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppTheme.primaryGreen,
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Changes to your privacy settings may take a few minutes '
                'to be reflected for other users.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wrapper widget to dynamically load BlockedContactsListScreen
class _BlockedContactsListWrapper extends StatelessWidget {
  const _BlockedContactsListWrapper();

  @override
  Widget build(BuildContext context) {
    // Import and return the BlockedContactsListScreen
    return const _BlockedContactsListScreenImpl();
  }
}

/// Implementation of blocked contacts list
/// This is kept in the same file to avoid circular imports
class _BlockedContactsListScreenImpl extends ConsumerWidget {
  const _BlockedContactsListScreenImpl();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedContactsAsync = ref.watch(blockedRosterEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Contacts'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Block a contact',
            onPressed: () => _showAddBlockedContactDialog(context, ref),
          ),
        ],
      ),
      body: blockedContactsAsync.when(
        data: (blockedContacts) {
          if (blockedContacts.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildBlockedContactsList(context, ref, blockedContacts);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
          ),
        ),
        error: (error, stackTrace) => _buildErrorState(context, ref, error),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block,
              size: 80,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No blocked contacts',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Contacts you block will appear here. '
              'Blocked contacts cannot send you messages or see your updates.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedContactsList(
    BuildContext context,
    WidgetRef ref,
    List<RosterEntry> blockedContacts,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: blockedContacts.length,
      itemBuilder: (context, index) {
        final contact = blockedContacts[index];
        return _buildBlockedContactTile(context, ref, contact);
      },
    );
  }

  Widget _buildBlockedContactTile(
    BuildContext context,
    WidgetRef ref,
    RosterEntry contact,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
          child: Text(
            _getInitials(contact.displayName ?? contact.contactDetail),
            style: const TextStyle(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Text(
          contact.displayName ?? contact.contactDetail,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: contact.displayName != null
            ? Text(
                contact.contactDetail,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: TextButton(
          onPressed: () => _unblockContact(context, ref, contact),
          child: const Text('Unblock'),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load blocked contacts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(blockedRosterEntriesProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddBlockedContactDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final rosterAsync = ref.read(rosterEntriesProvider);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return _ContactSelectionSheet(
            scrollController: scrollController,
            rosterAsync: rosterAsync,
            onContactSelected: (contact) async {
              Navigator.of(context).pop();
              await _blockContact(context, ref, contact);
            },
          );
        },
      ),
    );
  }

  Future<void> _blockContact(
    BuildContext context,
    WidgetRef ref,
    RosterEntry contact,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block Contact'),
        content: Text(
          'Are you sure you want to block ${contact.displayName ?? contact.contactDetail}? '
          'They will not be able to send you messages or see your updates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      try {
        final repo = await ref.read(rosterRepositoryProvider.future);
        await repo.blockRosterEntry(contact.id);
        ref.invalidate(blockedRosterEntriesProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${contact.displayName ?? contact.contactDetail} has been blocked',
              ),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () async {
                  await repo.unblockRosterEntry(contact.id);
                  ref.invalidate(blockedRosterEntriesProvider);
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to block contact: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _unblockContact(
    BuildContext context,
    WidgetRef ref,
    RosterEntry contact,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock Contact'),
        content: Text(
          'Are you sure you want to unblock ${contact.displayName ?? contact.contactDetail}? '
          'They will be able to send you messages again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      try {
        final repo = await ref.read(rosterRepositoryProvider.future);
        await repo.unblockRosterEntry(contact.id);
        ref.invalidate(blockedRosterEntriesProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${contact.displayName ?? contact.contactDetail} has been unblocked',
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to unblock contact: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class _ContactSelectionSheet extends ConsumerWidget {
  const _ContactSelectionSheet({
    required this.scrollController,
    required this.rosterAsync,
    required this.onContactSelected,
  });

  final ScrollController scrollController;
  final AsyncValue<List<RosterEntry>> rosterAsync;
  final ValueChanged<RosterEntry> onContactSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Select a contact to block',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const Divider(),
        Expanded(
          child: rosterAsync.when(
            data: (contacts) {
              // Filter out already blocked contacts
              final unblockedContacts = contacts
                  .where((c) => !c.isBlocked)
                  .toList();

              if (unblockedContacts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No contacts available to block',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                controller: scrollController,
                itemCount: unblockedContacts.length,
                itemBuilder: (context, index) {
                  final contact = unblockedContacts[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryGreen.withValues(
                        alpha: 0.1,
                      ),
                      child: Text(
                        _getInitials(
                          contact.displayName ?? contact.contactDetail,
                        ),
                        style: const TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    title: Text(contact.displayName ?? contact.contactDetail),
                    subtitle: contact.displayName != null
                        ? Text(contact.contactDetail)
                        : null,
                    onTap: () => onContactSelected(contact),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryGreen,
                ),
              ),
            ),
            error: (error, _) =>
                Center(child: Text('Error loading contacts: $error')),
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
