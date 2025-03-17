import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'lock_screen_settings_provider.g.dart';

/// Storage key for settings
const String _enabledKey = 'secure_web_lock_enabled';

/// Provider for lock screen settings
@Riverpod(keepAlive: true)
class LockScreenSettings extends _$LockScreenSettings {
  @override
  bool build() {
    // Load the initial value from SharedPreferences
    _loadFromPrefs();
    // Default to enabled
    return true;
  }

  /// Load settings from storage
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool(_enabledKey) ?? true; // Default to enabled

      if (state != isEnabled) {
        state = isEnabled;
        debugPrint('Secure Web Lock: Lock screen settings loaded: $isEnabled');
      }
    } catch (e) {
      debugPrint('Secure Web Lock: Error loading lock screen settings: $e');
    }
  }

  /// Save settings to storage
  Future<void> _saveToPrefs(bool isEnabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, isEnabled);
      debugPrint('Secure Web Lock: Lock screen settings saved: $isEnabled');
    } catch (e) {
      debugPrint('Secure Web Lock: Error saving lock screen settings: $e');
    }
  }

  /// Toggle lock screen enabled state
  Future<void> toggle() async {
    final newValue = !state;
    state = newValue;
    await _saveToPrefs(newValue);
    debugPrint('Secure Web Lock: Lock screen setting toggled to: $newValue');
  }

  /// Set lock screen enabled state
  Future<void> setEnabled(bool enabled) async {
    if (state != enabled) {
      state = enabled;
      await _saveToPrefs(enabled);
      debugPrint('Secure Web Lock: Lock screen setting set to: $enabled');
    }
  }
}