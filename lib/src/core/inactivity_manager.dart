import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/js_interop.dart';

/// State for the inactivity manager
class InactivityState {
  /// Whether the app is currently locked
  final bool isLocked;

  /// Whether the lock screen is enabled
  final bool isEnabled;

  /// When the last activity was detected
  final DateTime lastActivityTime;

  /// Constructor
  InactivityState({
    required this.isLocked,
    required this.isEnabled,
    required this.lastActivityTime,
  });

  /// Create a copy with some fields replaced
  InactivityState copyWith({
    bool? isLocked,
    bool? isEnabled,
    DateTime? lastActivityTime,
  }) {
    return InactivityState(
      isLocked: isLocked ?? this.isLocked,
      isEnabled: isEnabled ?? this.isEnabled,
      lastActivityTime: lastActivityTime ?? this.lastActivityTime,
    );
  }
}

/// Manager for inactivity state
class InactivityManager {
  // Singleton instance
  static final InactivityManager _instance = InactivityManager._internal();

  // Factory constructor to return the singleton instance
  factory InactivityManager() => _instance;

  // Private constructor
  InactivityManager._internal();

  // State
  InactivityState _state = InactivityState(
    isLocked: false,
    isEnabled: true,
    lastActivityTime: DateTime.now(),
  );

  // Stream controller for state changes
  final _stateController = StreamController<InactivityState>.broadcast();

  // Getters
  Stream<InactivityState> get stateStream => _stateController.stream;
  InactivityState get currentState => _state;
  bool get isLocked => _state.isLocked;
  bool get isEnabled => _state.isEnabled;

  // Timer
  Timer? _inactivityTimer;
  Duration _timeout = const Duration(seconds: 10);

  // Callbacks
  VoidCallback? _onLock;
  VoidCallback? _onUnlock;
  VoidCallback? _onLockEscape;

  // Storage keys
  static const String _lastActivityTimeKey = 'secure_web_lock_last_active_time';
  static const String _enabledKey = 'secure_web_lock_enabled';

  /// Initialize the manager
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

    // Load settings from storage
    _loadSettings();

    // Set up JS interop if on web
    if (kIsWeb) {
      JsInterop.initializeJavaScript();
      JsInterop.registerEscapeCallback(() {
        _handleLockEscape();
      });
    }

    // Start timer if enabled
    if (_state.isEnabled) {
      _startInactivityTimer();
    }
  }

  /// Load settings from storage
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled =
          prefs.getBool(_enabledKey) ?? true; // Default to enabled

      _state = _state.copyWith(isEnabled: isEnabled);
      _notifyStateChange();

      debugPrint('Secure Web Lock: Lock screen settings loaded: $isEnabled');
    } catch (e) {
      debugPrint('Secure Web Lock: Error loading settings: $e');
    }
  }

  /// Save settings to storage
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, _state.isEnabled);
      debugPrint(
          'Secure Web Lock: Lock screen settings saved: ${_state.isEnabled}');
    } catch (e) {
      debugPrint('Secure Web Lock: Error saving settings: $e');
    }
  }

  /// Notify listeners of state change
  void _notifyStateChange() {
    _stateController.add(_state);
  }

  /// Handle lock escape attempts
  void _handleLockEscape() {
    debugPrint("Secure Web Lock: Lock escape attempt detected");
    _onLockEscape?.call();
  }

  /// Start or restart the inactivity timer
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_timeout, lockApp);
  }

  /// Register user activity
  void registerActivity() {
    // If lock screen is disabled or already locked, don't register activity
    if (!_state.isEnabled || _state.isLocked) {
      return;
    }

    debugPrint("Secure Web Lock: Registering activity");
    _state = _state.copyWith(lastActivityTime: DateTime.now());
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
    // If lock screen is disabled, don't check inactivity
    if (!_state.isEnabled) {
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
    // If lock screen is disabled, don't lock the app
    if (!_state.isEnabled) {
      debugPrint("Secure Web Lock: Lock screen is disabled, skipping app lock");
      return;
    }

    debugPrint("Secure Web Lock: Locking app");
    if (!_state.isLocked) {
      _state = _state.copyWith(isLocked: true);
      _notifyStateChange();

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
    _state = _state.copyWith(
      isLocked: false,
      lastActivityTime: DateTime.now(),
    );
    _notifyStateChange();

    // Set the lock state in JavaScript
    if (kIsWeb) {
      JsInterop.setLockState(false);
    }

    // Call the unlock callback if provided
    _onUnlock?.call();

    _startInactivityTimer();
  }

  /// Enable or disable the lock screen
  Future<void> setEnabled(bool enabled) async {
    if (_state.isEnabled != enabled) {
      _state = _state.copyWith(isEnabled: enabled);
      _notifyStateChange();

      await _saveSettings();

      if (enabled) {
        debugPrint(
            "Secure Web Lock: Lock screen enabled, starting inactivity timer");
        _startInactivityTimer();
      } else {
        debugPrint(
            "Secure Web Lock: Lock screen disabled, canceling inactivity timer");
        _inactivityTimer?.cancel();

        // If currently locked, unlock
        if (_state.isLocked) {
          debugPrint(
              "Secure Web Lock: Unlocking app due to lock screen setting change");
          unlock();
        }
      }
    }
  }

  /// Toggle lock screen enabled state
  Future<void> toggle() async {
    await setEnabled(!_state.isEnabled);
  }

  /// Set the timeout duration
  void setTimeout(Duration timeout) {
    _timeout = timeout;
    if (_state.isEnabled && !_state.isLocked) {
      _startInactivityTimer();
    }
  }

  /// Get the current timeout duration
  Duration getTimeout() {
    return _timeout;
  }

  /// Dispose resources
  void dispose() {
    _inactivityTimer?.cancel();
    _stateController.close();
  }
}
