import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

/// Helper utility for consistent navigation patterns across the app
class NavigationHelper {
  /// Navigate to room details with proper animation and fallback
  static void navigateToRoomDetails(
    BuildContext context, {
    required String roomId,
    required String roomName,
  }) {
    context.push('/room/$roomId/details?name=${Uri.encodeComponent(roomName)}');
  }

  /// Navigate to chat screen with proper animation and fallback
  static void navigateToChat(
    BuildContext context, {
    required String roomId,
    required String roomName,
  }) {
    context.push('/chat/$roomId?name=${Uri.encodeComponent(roomName)}');
  }

  /// Navigate to profile screen with proper animation and fallback
  static void navigateToProfile(
    BuildContext context, {
    required String profileId,
  }) {
    context.push('/profile/$profileId');
  }

  /// Navigate to settings screen with proper animation and fallback
  static void navigateToSettings(BuildContext context) {
    context.go('/settings');
  }

  /// Navigate to account settings screen
  static void navigateToAccountSettings(BuildContext context) {
    context.push('/settings/account');
  }

  /// Navigate to privacy settings screen
  static void navigateToPrivacySettings(BuildContext context) {
    context.push('/settings/privacy');
  }

  /// Navigate to chat settings screen
  static void navigateToChatSettings(BuildContext context) {
    context.push('/settings/chats');
  }

  /// Navigate to notification settings screen
  static void navigateToNotificationSettings(BuildContext context) {
    context.push('/settings/notifications');
  }

  /// Navigate to storage settings screen
  static void navigateToStorageSettings(BuildContext context) {
    context.push('/settings/storage');
  }

  /// Navigate to security settings screen
  static void navigateToSecuritySettings(BuildContext context) {
    context.push('/settings/security');
  }

  /// Navigate to group settings screen
  static void navigateToGroupSettings(
    BuildContext context, {
    required String roomId,
    required String roomName,
  }) {
    context.push(
      '/room/$roomId/settings?name=${Uri.encodeComponent(roomName)}',
    );
  }

  /// Navigate to media compression settings screen
  static void navigateToMediaCompressionSettings(BuildContext context) {
    context.push('/settings/storage/compression');
  }

  /// Navigate to cache settings screen
  static void navigateToCacheSettings(BuildContext context) {
    context.push('/settings/storage/cache');
  }

  /// Navigate to profile edit screen
  static void navigateToProfileEdit(BuildContext context) {
    context.push('/profile/edit');
  }

  /// Navigate back with proper fallback handling
  static void navigateBack(BuildContext context, {String? fallbackRoute}) {
    if (Navigator.canPop(context)) {
      context.pop();
    } else if (fallbackRoute != null) {
      context.go(fallbackRoute);
    } else {
      context.go('/');
    }
  }

  /// Navigate to contact selection screen
  static void navigateToContactSelection(BuildContext context) {
    context.go('/contacts/select');
  }

  /// Navigate with slide transition for better UX
  static void navigateWithTransition(
    BuildContext context,
    String route, {
    PageTransitionType transitionType = PageTransitionType.slide,
  }) {
    context.push(route);
  }
}

/// Types of page transitions for navigation
enum PageTransitionType { slide, fade, scale }

/// Extension method for easier access to navigation helpers
extension NavigationContext on BuildContext {
  void navigateToRoomDetails({
    required String roomId,
    required String roomName,
  }) => NavigationHelper.navigateToRoomDetails(
    this,
    roomId: roomId,
    roomName: roomName,
  );

  void navigateToChat({required String roomId, required String roomName}) =>
      NavigationHelper.navigateToChat(this, roomId: roomId, roomName: roomName);

  void navigateToProfile({required String profileId}) =>
      NavigationHelper.navigateToProfile(this, profileId: profileId);

  void navigateToSettings() => NavigationHelper.navigateToSettings(this);

  void navigateToAccountSettings() =>
      NavigationHelper.navigateToAccountSettings(this);

  void navigateToPrivacySettings() =>
      NavigationHelper.navigateToPrivacySettings(this);

  void navigateToChatSettings() =>
      NavigationHelper.navigateToChatSettings(this);

  void navigateToNotificationSettings() =>
      NavigationHelper.navigateToNotificationSettings(this);

  void navigateToStorageSettings() =>
      NavigationHelper.navigateToStorageSettings(this);

  void navigateToSecuritySettings() =>
      NavigationHelper.navigateToSecuritySettings(this);

  void navigateToGroupSettings({
    required String roomId,
    required String roomName,
  }) => NavigationHelper.navigateToGroupSettings(
    this,
    roomId: roomId,
    roomName: roomName,
  );

  void navigateToMediaCompressionSettings() =>
      NavigationHelper.navigateToMediaCompressionSettings(this);

  void navigateToCacheSettings() =>
      NavigationHelper.navigateToCacheSettings(this);

  void navigateBack([String? fallbackRoute]) =>
      NavigationHelper.navigateBack(this, fallbackRoute: fallbackRoute);

  void navigateToContactSelection() =>
      NavigationHelper.navigateToContactSelection(this);

  void navigateToProfileEdit() => NavigationHelper.navigateToProfileEdit(this);
}
