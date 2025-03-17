import 'package:flutter/material.dart';

import '../core/inactivity_manager.dart';

/// Router observer for tracking navigation events
class SecureWebLockRouterObserver extends NavigatorObserver {
  /// The inactivity manager instance
  final InactivityManager _manager = InactivityManager();

  /// Excluded route patterns
  final List<String> excludedRoutePatterns;

  /// Custom function to determine if a route is excluded
  final bool Function(BuildContext? context)? isExcludedRouteCallback;

  /// Constructor
  SecureWebLockRouterObserver({
    this.excludedRoutePatterns = const [
      '/login',
      '/register',
      '/reset-password'
    ],
    this.isExcludedRouteCallback,
  });

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _handleRouteChange(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _handleRouteChange(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _handleRouteChange(previousRoute);
    }
  }

  /// Handle route changes
  void _handleRouteChange(Route<dynamic> route) {
    try {
      final routeName = route.settings.name;
      final context = navigator?.context;

      // First check if we have a custom callback
      if (isExcludedRouteCallback != null && context != null) {
        if (isExcludedRouteCallback!(context)) {
          debugPrint('Secure Web Lock: Excluded route detected via callback, skipping activity registration');
          return;
        }
      }

      // Then check against excluded patterns
      if (routeName != null) {
        for (final pattern in excludedRoutePatterns) {
          if (routeName.contains(pattern)) {
            debugPrint('Secure Web Lock: Excluded route detected: $routeName, skipping activity registration');
            return;
          }
        }
      }

      // Register activity for non-excluded routes
      _manager.registerActivity();
    } catch (e) {
      debugPrint('Secure Web Lock: Error in router observer: $e');
    }
  }
}