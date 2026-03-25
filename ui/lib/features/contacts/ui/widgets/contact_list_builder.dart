import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/roster_repository.dart';
import '../../services/contact_service.dart';
import '../contact_permission_view.dart';

/// A reusable widget that handles the common pattern of:
/// 1. Checking contact permission
/// 2. Showing ContactPermissionView if not granted
/// 3. Loading and displaying contacts when permission granted
///
/// Use [builder] to customize how contacts are displayed.
class ContactListBuilder extends ConsumerWidget {
  const ContactListBuilder({
    required this.builder,
    this.emptyBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    super.key,
  });

  /// Builder for displaying the list of contacts
  final Widget Function(
    BuildContext context,
    List<ProfileWithContacts> contacts,
  )
  builder;

  /// Builder for empty state (no contacts found)
  final Widget Function(BuildContext context)? emptyBuilder;

  /// Builder for loading state
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Builder for error state
  final Widget Function(BuildContext context, Object error, StackTrace stack)?
  errorBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(contactPermissionGrantedProvider);

    return permissionAsync.when(
      data: (hasPermission) {
        if (!hasPermission) {
          return ContactPermissionView(
            onPermissionGranted: () async {
              // Invalidate permission provider to refresh state
              ref.invalidate(contactPermissionGrantedProvider);
              // Phase 1: Read device contacts locally (~200ms)
              final rosterRepo = await ref.read(
                rosterRepositoryProvider.future,
              );
              await rosterRepo.syncContactsLocal();
              // Phase 2: Server sync in background (stream auto-updates)
              unawaited(rosterRepo.syncContactsToServer());
            },
          );
        }

        // Permission granted - show contacts (stream auto-updates)
        final contactsAsync = ref.watch(profilesWithContactsStreamProvider);

        return contactsAsync.when(
          data: (contacts) {
            if (contacts.isEmpty) {
              return emptyBuilder?.call(context) ?? _defaultEmptyState(context);
            }
            return builder(context, contacts);
          },
          loading: () =>
              loadingBuilder?.call(context) ?? _defaultLoadingState(),
          error: (error, stack) =>
              errorBuilder?.call(context, error, stack) ??
              _defaultErrorState(context, error, ref),
        );
      },
      loading: () => loadingBuilder?.call(context) ?? _defaultLoadingState(),
      error: (error, stack) =>
          errorBuilder?.call(context, error, stack) ??
          _defaultPermissionErrorState(context, error, ref),
    );
  }

  Widget _defaultEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text('No contacts found', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'None of your contacts are on the app yet',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _defaultLoadingState() =>
      const Center(child: CircularProgressIndicator());

  Widget _defaultErrorState(BuildContext context, Object error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error: $error'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => ref.invalidate(profilesWithContactsStreamProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _defaultPermissionErrorState(
    BuildContext context,
    Object error,
    WidgetRef ref,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error checking permission: $error'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => ref.invalidate(contactPermissionGrantedProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// A sliver version of [ContactListBuilder] for use in CustomScrollView
class SliverContactListBuilder extends ConsumerWidget {
  const SliverContactListBuilder({
    required this.builder,
    this.emptyBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    super.key,
  });

  /// Builder for displaying the list of contacts as slivers
  final Widget Function(
    BuildContext context,
    List<ProfileWithContacts> contacts,
  )
  builder;

  /// Builder for empty state (no contacts found)
  final Widget Function(BuildContext context)? emptyBuilder;

  /// Builder for loading state
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Builder for error state
  final Widget Function(BuildContext context, Object error, StackTrace stack)?
  errorBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(contactPermissionGrantedProvider);

    return permissionAsync.when(
      data: (hasPermission) {
        if (!hasPermission) {
          return SliverFillRemaining(
            child: ContactPermissionView(
              onPermissionGranted: () async {
                ref.invalidate(contactPermissionGrantedProvider);
                // Phase 1: Read device contacts locally (~200ms)
                final rosterRepo = await ref.read(
                  rosterRepositoryProvider.future,
                );
                await rosterRepo.syncContactsLocal();
                // Phase 2: Server sync in background (stream auto-updates)
                unawaited(rosterRepo.syncContactsToServer());
              },
            ),
          );
        }

        // Permission granted - show contacts (stream auto-updates)
        final contactsAsync = ref.watch(profilesWithContactsStreamProvider);

        return contactsAsync.when(
          data: (contacts) {
            if (contacts.isEmpty) {
              return SliverFillRemaining(
                child:
                    emptyBuilder?.call(context) ?? _defaultEmptyState(context),
              );
            }
            return builder(context, contacts);
          },
          loading: () => SliverFillRemaining(
            child: loadingBuilder?.call(context) ?? _defaultLoadingState(),
          ),
          error: (error, stack) => SliverFillRemaining(
            child:
                errorBuilder?.call(context, error, stack) ??
                _defaultErrorState(context, error, ref),
          ),
        );
      },
      loading: () => SliverFillRemaining(
        child: loadingBuilder?.call(context) ?? _defaultLoadingState(),
      ),
      error: (error, stack) => SliverFillRemaining(
        child:
            errorBuilder?.call(context, error, stack) ??
            _defaultPermissionErrorState(context, error, ref),
      ),
    );
  }

  Widget _defaultEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text('No contacts found', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'None of your contacts are on the app yet',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _defaultLoadingState() =>
      const Center(child: CircularProgressIndicator());

  Widget _defaultErrorState(BuildContext context, Object error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error: $error'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => ref.invalidate(profilesWithContactsStreamProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _defaultPermissionErrorState(
    BuildContext context,
    Object error,
    WidgetRef ref,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error checking permission: $error'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => ref.invalidate(contactPermissionGrantedProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
