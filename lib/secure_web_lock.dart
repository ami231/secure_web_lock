library secure_web_lock;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'src/core/inactivity_manager.dart';
import 'src/router/router_observer.dart';
import 'utils/js_interop.dart';

// Export core functionality
export 'src/core/inactivity_manager.dart' show InactivityState;
export 'src/widgets/activity_observer.dart';
export 'src/widgets/lock_screen.dart';
export 'utils/js_interop.dart';

/// Helper class for easy implementation of SecureWebLock
class SecureWebLock {
  /// Get the singleton instance of InactivityManager
  static final InactivityManager _manager = InactivityManager();

  /// Initialize the secure web lock functionality
  ///
  /// This should be called as early as possible in your app,
  /// typically in main() before runApp()
  static void initialize() {
    if (kIsWeb) {
      JsInterop.initializeJavaScript();
    }
  }

  /// Initialize the inactivity manager with custom settings
  ///
  /// This should be called early in your app's lifecycle
  static void initializeManager({
    Duration? timeout,
    VoidCallback? onLock,
    VoidCallback? onUnlock,
    VoidCallback? onLockEscape,
  }) {
    _manager.initialize(
      timeout: timeout,
      onLock: onLock,
      onUnlock: onUnlock,
      onLockEscape: onLockEscape,
    );
  }

  /// Create a navigator observer for activity tracking
  ///
  /// Usage:
  /// ```dart
  /// final navigatorObservers = [
  ///   SecureWebLock.createRouterObserver(),
  /// ];
  /// ```
  static NavigatorObserver createRouterObserver({
    List<String> excludedRoutePatterns = const [
      '/login',
      '/register',
      '/reset-password'
    ],
    bool Function(BuildContext? context)? isExcludedRouteCallback,
  }) {
    return SecureWebLockRouterObserver(
      excludedRoutePatterns: excludedRoutePatterns,
      isExcludedRouteCallback: isExcludedRouteCallback,
    );
  }

  /// Get a stream of inactivity state changes
  static Stream<InactivityState> get stateStream => _manager.stateStream;

  /// Get the current inactivity state
  static InactivityState get currentState => _manager.currentState;

  /// Enable or disable the lock screen
  static Future<void> setEnabled(bool enabled) async {
    await _manager.setEnabled(enabled);
  }

  /// Toggle lock screen enabled/disabled state
  static Future<void> toggle() async {
    await _manager.toggle();
  }

  /// Check if lock screen is enabled
  static bool get isEnabled => _manager.isEnabled;

  /// Manually lock the app
  static void lock() {
    _manager.lockApp();
  }

  /// Manually unlock the app
  static void unlock() {
    _manager.unlock();
  }

  /// Check if the app is currently locked
  static bool get isLocked => _manager.isLocked;

  /// Set the timeout duration
  static void setTimeout(Duration timeout) {
    _manager.setTimeout(timeout);
  }

  /// Get the current timeout duration
  static Duration getTimeout() {
    return _manager.getTimeout();
  }

  /// Register activity manually
  static void registerActivity() {
    _manager.registerActivity();
  }

  /// Check inactivity when app resumes
  static Future<void> checkInactivityOnResume() async {
    await _manager.checkInactivityOnResume();
  }
}
