import 'dart:js' as js;

import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

/// Handles JavaScript interoperability for secure web lock
class JsInterop {
  /// Whether JS is initialized
  static bool _initialized = false;

  static void initializeJavaScript() {
    if (!kIsWeb || _initialized) return;

    try {
      // Create a script element
      final scriptElement = html.ScriptElement()
        ..type = 'text/javascript'
        ..src = 'packages/secure_web_lock/web/secure_web_lock.js';

      // Add the script to the document head
      html.document.head!.append(scriptElement);

      _initialized = true;
      debugPrint('Secure Web Lock: JavaScript interface initialized');
    } catch (e) {
      debugPrint(
          'Secure Web Lock: Error initializing JavaScript interface: $e');
    }
  }

  /// Set the lock state in JavaScript
  static void setLockState(bool isLocked) {
    if (!kIsWeb) return;

    try {
      js.context.callMethod('setLockState', [isLocked]);
      debugPrint('Secure Web Lock: Lock state set to $isLocked in JavaScript');
    } catch (e) {
      debugPrint('Secure Web Lock: Error setting lock state in JavaScript: $e');
    }
  }

  /// Register a callback for when the user tries to escape the lock screen
  static void registerEscapeCallback(Function callback) {
    if (!kIsWeb) return;

    try {
      js.context['_secureLockEscapeCallback'] = callback;
      debugPrint('Secure Web Lock: Escape callback registered');
    } catch (e) {
      debugPrint('Secure Web Lock: Error registering escape callback: $e');
    }
  }
}