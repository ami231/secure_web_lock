import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/js_interop.dart';
import 'lock_screen_settings_provider.dart';

part 'inactivity_provider.g.dart';

/// State for the inactivity provider
class InactivityState {
  /// Whether the app is currently locked
  final bool isLocked;

  /// When the last activity was detected
  final DateTime lastActivityTime;

  /// Constructor
  InactivityState({
    required this.isLocked,
    required this.lastActivityTime,
  });

  /// Create a copy with some fields replaced
  InactivityState copyWith({
    bool? isLocked,
    DateTime? lastActivityTime,
  }) {
    return InactivityState(
      isLocked: isLocked ?? this.isLocked,
      lastActivityTime: lastActivityTime ?? this.lastActivityTime,
    );
  }
}

/// Provider for inactivity state
@Riverpod(keepAlive: true)
class InactivityNotifier extends _$InactivityNotifier {
  Timer? _inactivityTimer;
  Duration _timeout = const Duration(seconds: 10);
  VoidCallback? _onLock;
  VoidCallback? _onUnlock;
  VoidCallback? _onLockEscape;

  /// Key for storing last activity time
  static const String _lastActivityTimeKey = 'secure_web_lock_last_active_time';

  /// Initialize with custom timeout and callbacks
  void initialize({
    Duration? timeout,
    VoidCallback? onLock,
    VoidCallback? onUnlock,
    VoidCallback? onLockEscape,
  }) {
    _timeout = timeout ?? _timeout;
    _onLock = onLock;
    _onUnlock = onUnlock;
    _onLockEscape = onLockEscape;

    // Set up JS interop if on web
    if (kIsWeb) {
      JsInterop.initializeJavaScript();
      JsInterop.registerEscapeCallback(() {
        _handleLockEscape();
      });
    }

    _startInactivityTimer();
  }

  @override
  InactivityState build() {
    ref.onDispose(() {
      _inactivityTimer?.cancel();
    });

    // Listen for changes in lock screen settings
    ref.listen(lockScreenSettingsProvider, (previous, current) {
      if (previous == false && current == true) {
        debugPrint(
            "Secure Web Lock: Lock screen enabled, starting inactivity timer");
        _startInactivityTimer();
      }

      if (previous == true && current == false) {
        debugPrint(
            "Secure Web Lock: Lock screen disabled, canceling inactivity timer");
        _inactivityTimer?.cancel();

        // If currently locked, unlock
        if (state.isLocked) {
          debugPrint(
              "Secure Web Lock: Unlocking app due to lock screen setting change");
          unlock();
        }
      }
    });

    // Only start timer if lock screen is enabled
    final lockScreenEnabled = ref.read(lockScreenSettingsProvider);
    if (lockScreenEnabled) {
      _startInactivityTimer();
    } else {
      debugPrint(
          "Secure Web Lock: Lock screen disabled, not starting inactivity timer");
    }

    return InactivityState(
      isLocked: false,
      lastActivityTime: DateTime.now(),
    );
  }

  /// Handle lock escape attempts
  void _handleLockEscape() {
    debugPrint("Secure Web Lock: Lock escape attempt detected");
    // Call the escape callback if provided
    _onLockEscape?.call();
  }


  /// Start or restart the inactivity timer
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_timeout, lockApp);
  }

  /// Register user activity
  void registerActivity() {
    // Check if lock screen is enabled in settings
    final lockScreenEnabled = ref.read(lockScreenSettingsProvider);

    // If lock screen is disabled or already locked, don't register activity
    if (!lockScreenEnabled || state.isLocked) {
      return;
    }

    debugPrint("Secure Web Lock: Registering activity");
    state = state.copyWith(lastActivityTime: DateTime.now());
    _saveLastActiveTime();
    _startInactivityTimer();
  }

  /// Save the last active time to storage
  Future<void> _saveLastActiveTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _lastActivityTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint("Secure Web Lock: Error saving last active time: $e");
    }
  }

  /// Check inactivity when app resumes
  Future<void> checkInactivityOnResume() async {
    // Check if lock screen is enabled in settings
    final lockScreenEnabled = ref.read(lockScreenSettingsProvider);

    // If lock screen is disabled, don't check inactivity
    if (!lockScreenEnabled) {
      debugPrint(
          "Secure Web Lock: Lock screen is disabled, skipping inactivity check");
      return;
    }

    debugPrint("Secure Web Lock: Checking inactivity on resume");
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActiveTime = prefs.getInt(_lastActivityTimeKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - lastActiveTime > _timeout.inMilliseconds) {
        lockApp();
      } else {
        _startInactivityTimer();
      }
    } catch (e) {
      debugPrint("Secure Web Lock: Error checking inactivity: $e");
    }
  }

  /// Lock the app
  void lockApp() {
    // Check if lock screen is enabled in settings
    final lockScreenEnabled = ref.read(lockScreenSettingsProvider);

    // If lock screen is disabled, don't lock the app
    if (!lockScreenEnabled) {
      debugPrint("Secure Web Lock: Lock screen is disabled, skipping app lock");
      return;
    }

    debugPrint("Secure Web Lock: Locking app");
    if (!state.isLocked) {
      state = state.copyWith(isLocked: true);

      // Set the lock state in JavaScript
      if (kIsWeb) {
        JsInterop.setLockState(true);
      }

      // Call the lock callback if provided
      _onLock?.call();
    }
  }

  /// Unlock the app
  void unlock() {
    debugPrint("Secure Web Lock: Unlocking app");
    state = state.copyWith(
      isLocked: false,
      lastActivityTime: DateTime.now(),
    );

    // Set the lock state in JavaScript
    if (kIsWeb) {
      JsInterop.setLockState(false);
    }

    // Call the unlock callback if provided
    _onUnlock?.call();

    _startInactivityTimer();
  }

  /// Set the timeout duration
  void setTimeout(Duration timeout) {
    _timeout = timeout;
    if (ref.read(lockScreenSettingsProvider) && !state.isLocked) {
      _startInactivityTimer();
    }
  }

  /// Get the current timeout duration
  Duration getTimeout() {
    return _timeout;
  }
}
