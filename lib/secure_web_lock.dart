library secure_web_lock;

import 'package:flutter/foundation.dart';
// Export a helper class to make implementation easier
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/inactivity_provider.dart';
import 'providers/lock_screen_settings_provider.dart';
import 'src/router/router_observer.dart';
import 'utils/js_interop.dart';

export 'providers/inactivity_provider.dart';
export 'providers/lock_screen_settings_provider.dart';
export 'src/router/router_observer.dart';
// Export core functionality
export 'src/widgets/activity_observer.dart';
export 'src/widgets/lock_screen.dart';
export 'utils/js_interop.dart';

// Core functionality

/// Helper class for easy implementation of SecureWebLock
class SecureWebLock {
  /// Initialize the secure web lock functionality
  ///
  /// This should be called as early as possible in your app,
  /// typically in main() before runApp()
  static void initialize() {
    if (kIsWeb) {
      JsInterop.initializeJavaScript();
    }
  }

  /// Initialize the inactivity notifier with custom settings
  ///
  /// This should be called after your ProviderScope is set up
  static void initializeProvider(
    WidgetRef ref, {
    Duration? timeout,
    VoidCallback? onLock,
    VoidCallback? onUnlock,
    VoidCallback? onLockEscape, // Add new parameter
  }) {
    ref.read(inactivityNotifierProvider.notifier).initialize(
          timeout: timeout,
          onLock: onLock,
          onUnlock: onUnlock,
          onLockEscape: onLockEscape,
        );
  }

  /// Create a GoRouter observer for activity tracking
  ///
  /// Usage:
  /// ```dart
  /// final router = GoRouter(
  ///   observers: [
  ///     SecureWebLock.createRouterObserver(ref),
  ///   ],
  ///   // ...other router config
  /// );
  /// ```
  static NavigatorObserver createRouterObserver(
    WidgetRef ref, {
    List<String> excludedRoutePatterns = const [
      '/login',
      '/register',
      '/reset-password'
    ],
    bool Function(BuildContext? context)? isExcludedRouteCallback,
  }) {
    return SecureWebLockRouterObserver(
      ref: ref,
      excludedRoutePatterns: excludedRoutePatterns,
      isExcludedRouteCallback: isExcludedRouteCallback,
    );
  }

  /// Enable or disable the lock screen
  static void setEnabled(WidgetRef ref, bool enabled) {
    ref.read(lockScreenSettingsProvider.notifier).setEnabled(enabled);
  }

  /// Toggle lock screen enabled/disabled state
  static void toggle(WidgetRef ref) {
    ref.read(lockScreenSettingsProvider.notifier).toggle();
  }

  /// Check if lock screen is enabled
  static bool isEnabled(WidgetRef ref) {
    return ref.read(lockScreenSettingsProvider);
  }

  /// Manually lock the app
  static void lock(WidgetRef ref) {
    ref.read(inactivityNotifierProvider.notifier).lockApp();
  }

  /// Manually unlock the app
  static void unlock(WidgetRef ref) {
    ref.read(inactivityNotifierProvider.notifier).unlock();
  }

  /// Check if the app is currently locked
  static bool isLocked(WidgetRef ref) {
    return ref.read(inactivityNotifierProvider).isLocked;
  }

  /// Set the timeout duration
  static void setTimeout(WidgetRef ref, Duration timeout) {
    ref.read(inactivityNotifierProvider.notifier).setTimeout(timeout);
  }

  /// Get the current timeout duration
  static Duration getTimeout(WidgetRef ref) {
    return ref.read(inactivityNotifierProvider.notifier).getTimeout();
  }

  /// Register activity manually
  static void registerActivity(WidgetRef ref) {
    ref.read(inactivityNotifierProvider.notifier).registerActivity();
  }
}
