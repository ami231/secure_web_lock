import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/inactivity_provider.dart';
import 'lock_screen.dart';

/// Widget that monitors user activity and shows the lock screen when needed
class ActivityObserver extends ConsumerStatefulWidget {
  /// The child widget to wrap
  final Widget child;

  /// Custom builder for the lock screen
  final Widget Function(BuildContext, String?, VoidCallback)? lockScreenBuilder;

  /// The routes or route patterns that should not trigger the lock screen
  final List<String> excludedRoutePatterns;

  /// Custom function to determine if the current route should be excluded
  /// If provided, this takes precedence over excludedRoutePatterns
  final bool Function(BuildContext? context)? isExcludedRouteCallback;

  /// GlobalKey for NavigatorState access
  final GlobalKey<NavigatorState> navigatorKey;

  /// Constructor
  const ActivityObserver({
    Key? key,
    required this.child,
    required this.navigatorKey,
    this.lockScreenBuilder,
    this.excludedRoutePatterns = const [
      '/login',
      '/register',
      '/reset-password'
    ],
    this.isExcludedRouteCallback,
  }) : super(key: key);

  @override
  ConsumerState<ActivityObserver> createState() => _ActivityObserverState();
}

class _ActivityObserverState extends ConsumerState<ActivityObserver>
    with WidgetsBindingObserver {
  bool _lockScreenVisible = false;
  Timer? _resumeDebounceTimer;

  // Throttle activity registration
  DateTime _lastActivity = DateTime.now();
  static const _throttleDuration = Duration(milliseconds: 500);

  // Focus node for keyboard events
  final FocusNode _focusNode = FocusNode(debugLabel: 'SecurityLockFocusNode');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('Secure Web Lock: ActivityObserver initialized');
  }

  @override
  void dispose() {
    _resumeDebounceTimer?.cancel();
    _focusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('Secure Web Lock: App lifecycle state changed to: $state');

    // Only handle resumed state with debouncing
    if (state == AppLifecycleState.resumed) {
      // Cancel any pending timer
      _resumeDebounceTimer?.cancel();

      // Debounce the resume event
      _resumeDebounceTimer = Timer(const Duration(milliseconds: 300), () {
        // Only proceed if we're not on an excluded route
        if (!_isExcludedRoute()) {
          ref
              .read(inactivityNotifierProvider.notifier)
              .checkInactivityOnResume();
        }
      });
    }
  }

  // Check if current route is excluded
  bool _isExcludedRoute() {
    final context = widget.navigatorKey.currentContext;
    if (context == null) return false;

    // First try using the callback if provided
    if (widget.isExcludedRouteCallback != null) {
      try {
        return widget.isExcludedRouteCallback!(context);
      } catch (e) {
        debugPrint('Secure Web Lock: Error in isExcludedRouteCallback: $e');
        // Fall through to default implementation
      }
    }

    try {
      // Try different approaches to get the current route name
      String? currentRoute;

      // Try ModalRoute first (works with Navigator 1.0)
      currentRoute = ModalRoute.of(context)?.settings.name;

      // If that fails, try to get the current url from various routing packages
      if (currentRoute == null || currentRoute.isEmpty) {
        // Try to get the path another way - depends on routing system
        try {
          // This is a generic approach that might work with different router implementations
          final route = Navigator.of(context).widget.pages.lastOrNull?.name;
          if (route != null) {
            currentRoute = route;
          }
        } catch (_) {
          // Ignore errors, we have fallbacks
        }
      }

      // If we have a route name, check patterns
      if (currentRoute != null && currentRoute.isNotEmpty) {
        for (final pattern in widget.excludedRoutePatterns) {
          if (currentRoute.contains(pattern)) {
            return true;
          }
        }
      }

      // If all else fails, make a best effort to check the current widget tree
      // This can help detect login screens by their widgets
      return _isLikelyAuthScreen(context);
    } catch (e) {
      debugPrint('Secure Web Lock: Error checking route: $e');
      return false;
    }
  }

  // Helper method to detect if the current screen is likely an auth screen
  // based on the widget tree (fallback mechanism)
  bool _isLikelyAuthScreen(BuildContext context) {
    try {
      // Check for common auth screen widgets
      bool hasPasswordField = false;
      bool hasLoginButton = false;

      void findAuthWidgets(Element element) {
        // Check if this is a password field
        if (element.widget is TextField) {
          final textField = element.widget as TextField;
          if (textField.obscureText) {
            hasPasswordField = true;
          }
        }

        // Check if this might be a login button
        if (element.widget is ElevatedButton ||
            element.widget is TextButton ||
            element.widget is OutlinedButton) {
          final buttonWidget = element.widget as ButtonStyleButton;
          final buttonChildWidget = buttonWidget.child;

          if (buttonChildWidget is Text) {
            final buttonText = buttonChildWidget.data?.toLowerCase() ?? '';
            if (buttonText.contains('login') ||
                buttonText.contains('sign in') ||
                buttonText.contains('log in')) {
              hasLoginButton = true;
            }
          }
        }

        element.visitChildren(findAuthWidgets);
      }

      // Start traversing from context
      context.visitChildElements(findAuthWidgets);

      // If we found both a password field and a login button, it's likely a login screen
      return hasPasswordField && hasLoginButton;
    } catch (e) {
      return false;
    }
  }

  // Show lock screen if needed
  void _showLockScreenIfNeeded() {
    // Skip if already showing lock screen
    if (_lockScreenVisible) return;

    // Skip on excluded routes
    if (_isExcludedRoute()) {
      debugPrint('Secure Web Lock: On excluded route, skipping lock screen');
      return;
    }

    // Check if app is locked
    final isLocked = ref.read(inactivityNotifierProvider).isLocked;
    if (!isLocked) return;

    debugPrint('Secure Web Lock: App is locked, showing lock screen');
    _lockScreenVisible = true;

    // Use microtask to show dialog after current frame
    Future.microtask(() {
      final context = widget.navigatorKey.currentContext;
      if (context != null && mounted) {
        _showLockScreen(context);
      } else {
        _lockScreenVisible = false;
      }
    });
  }

  // Show lock screen dialog
  void _showLockScreen(BuildContext context) {
    try {
      // Get user identifier if needed (apps can customize this in lockScreenBuilder)
      String? userIdentifier;

      // Show the lock screen
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (dialogContext) {
          return WillPopScope(
            onWillPop: () async => false,
            child: widget.lockScreenBuilder != null
                ? widget.lockScreenBuilder!(
                    dialogContext,
                    userIdentifier,
                    () {
                      debugPrint('Secure Web Lock: Unlocking app');
                      ref.read(inactivityNotifierProvider.notifier).unlock();
                      Navigator.of(dialogContext).pop();
                      _lockScreenVisible = false;
                    },
                  )
                : DefaultLockScreen(
                    userIdentifier: userIdentifier,
                    onUnlock: () {
                      debugPrint('Secure Web Lock: Unlocking app');
                      ref.read(inactivityNotifierProvider.notifier).unlock();
                      Navigator.of(dialogContext).pop();
                      _lockScreenVisible = false;
                    },
                  ),
          );
        },
      ).then((_) {
        _lockScreenVisible = false;
      }).catchError((error) {
        debugPrint('Secure Web Lock: Dialog error: $error');
        _lockScreenVisible = false;
      });
    } catch (e) {
      debugPrint('Secure Web Lock: Error showing lock screen: $e');
      _lockScreenVisible = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for lock state changes
    ref.listen(
      inactivityNotifierProvider.select((state) => state.isLocked),
      (_, isLocked) {
        if (isLocked) {
          _showLockScreenIfNeeded();
        }
      },
    );

    // Create a Focus widget that captures keyboard events
    return FocusScope(
      // Make this a focus scope so it doesn't interfere with text fields
      child: Focus(
        focusNode: _focusNode,
        // Don't request focus so it doesn't interfere with normal app use
        autofocus: false,
        // This captures all key events in the app
        onKeyEvent: (_, KeyEvent event) {
          // Only respond to key down events
          if (event is KeyDownEvent || event is KeyRepeatEvent) {
            _registerActivity();
          }
          // Don't consume the event, let it continue to its target
          return KeyEventResult.ignored;
        },
        // Use MouseRegion for hover and NotificationListener for scroll events
        child: MouseRegion(
          onHover: (_) => _registerActivity(),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              _registerActivity();
              return false; // Don't stop the notification bubble
            },
            child: Listener(
              onPointerDown: (_) => _registerActivity(),
              onPointerMove: (_) => _registerActivity(),
              onPointerUp: (_) => _registerActivity(),
              // Make sure we capture events throughout the entire app
              behavior: HitTestBehavior.translucent,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }

  // Register activity with throttling
  void _registerActivity() {
    // Skip if on excluded route
    if (_isExcludedRoute()) return;

    // Skip if showing lock screen
    if (_lockScreenVisible) return;

    // Throttle activity registration
    final now = DateTime.now();
    if (now.difference(_lastActivity) < _throttleDuration) {
      return;
    }

    _lastActivity = now;

    // Register activity
    try {
      ref.read(inactivityNotifierProvider.notifier).registerActivity();
    } catch (e) {
      debugPrint('Secure Web Lock: Error registering activity: $e');
    }
  }
}
