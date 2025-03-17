import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// import '../providers/inactivity_provider.dart';

/// NavigatorObserver that tracks route changes and registers activity
class SecureWebLockRouterObserver extends NavigatorObserver {
  final WidgetRef ref;
  
  /// Route patterns that should be excluded from activity tracking
  final List<String> excludedRoutePatterns;
  
  /// Custom function to determine if a route should be excluded
  final bool Function(BuildContext? context)? isExcludedRouteCallback;

  SecureWebLockRouterObserver({
    required this.ref,
    this.excludedRoutePatterns = const ['/login', '/register', '/reset-password'],
    this.isExcludedRouteCallback,
  });

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _registerActivitySafely();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _registerActivitySafely();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _registerActivitySafely();
  }

  /// Check if current route should be excluded from inactivity tracking
  bool _isExcludedRoute(BuildContext? context) {
    if (context == null) return false;
    
    // First try using the callback if provided
    if (isExcludedRouteCallback != null) {
      try {
        return isExcludedRouteCallback!(context);
      } catch (e) {
        debugPrint('Secure Web Lock: Error in isExcludedRouteCallback: $e');
      }
    }
    
    try {
      // Try different approaches to get the current route name
      // (Similar logic as in ActivityObserver)
      final router = GoRouter.of(context);
      final path = router.routerDelegate.currentConfiguration.fullPath;
      
      return excludedRoutePatterns.any((pattern) => path.contains(pattern));
    } catch (e) {
      debugPrint('Secure Web Lock: Error checking route: $e');
      return false;
    }
  }

  /// This safely registers activity using a microtask to avoid the build cycle issue
  void _registerActivitySafely() {
    // TODO: Implement this
  }
}