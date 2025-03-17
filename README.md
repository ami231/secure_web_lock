# Secure Web Lock

A Flutter package that implements session lock functionality for web applications. It automatically locks the app after a period of inactivity and prevents users from bypassing the lock screen via page refreshes or navigation.

## Features

- 🔒 Auto-locks app after configurable period of inactivity
- 🛡️ Prevents lock screen bypass via refresh/navigation in browsers
- 🕹️ Track user activity including mouse moves, scrolling, and keyboard input
- 🚫 Exclude specific routes from being locked (e.g., login screens)
- 🎨 Customizable lock screen UI
- 💾 Persists settings across sessions
- 🌐 Works with any state management solution (no dependencies on Riverpod)

## Installation

```yaml
dependencies:
  secure_web_lock: ^0.1.0

flutter:
  assets:
    - packages/secure_web_lock/web/secure_web_lock.js
```

## Quick Start

### 1. Initialize the package

In your `main.dart` file:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize web lock (must be called before runApp)
  if (kIsWeb) {
    SecureWebLock.initialize();
  }
  
  runApp(MyApp());
}
```

### 2. Set up the activity observer

Wrap your app with the `ActivityObserver` widget:

```dart
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _isLocked = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize the manager after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SecureWebLock.initializeManager(
        timeout: const Duration(minutes: 5), // Lock after 5 minutes of inactivity
        onLock: () {
          print('App locked due to inactivity');
          setState(() => _isLocked = true);
        },
        onUnlock: () {
          print('App unlocked');
          setState(() => _isLocked = false);
        },
        onLockEscape: () {
          // Handle lock screen escape attempts
          print('User attempted to escape lock screen!');
          // Here you might want to log out the user or take other action
        },
      );
      
      // Optional: Listen to state changes
      SecureWebLock.stateStream.listen((state) {
        setState(() => _isLocked = state.isLocked);
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return ActivityObserver(
      navigatorKey: _navigatorKey,
      excludedRoutePatterns: ['/login', '/register'], // Routes to exclude from locking
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'My App',
        navigatorObservers: [
          SecureWebLock.createRouterObserver(), // Add observer for route tracking
        ],
        home: HomePage(isLocked: _isLocked),
      ),
    );
  }
}
```

## Handling Authentication Routes

To prevent the lock screen from appearing on authentication pages:

### 1. Using route patterns:

```dart
ActivityObserver(
  navigatorKey: _navigatorKey,
  excludedRoutePatterns: ['/login', '/auth', '/register'],
  child: MaterialApp(...),
)
```

### 2. Using a custom callback (for advanced routing systems):

```dart
ActivityObserver(
  navigatorKey: _navigatorKey,
  isExcludedRouteCallback: (context) {
    // Your custom logic to determine if this is an auth route
    final currentRoute = /* get current route from your router */;
    return currentRoute.startsWith('/auth/');
  },
  child: MaterialApp(...),
)
```

## API Reference

### Control the Lock Screen

```dart
// Lock the app manually
SecureWebLock.lock();

// Unlock the app
SecureWebLock.unlock();

// Check if the app is currently locked
bool isLocked = SecureWebLock.isLocked;

// Enable or disable the lock screen feature
SecureWebLock.setEnabled(true);

// Toggle lock screen enabled state
SecureWebLock.toggle();

// Set a new timeout duration
SecureWebLock.setTimeout(const Duration(minutes: 10));

// Get current timeout
Duration timeout = SecureWebLock.getTimeout();

// Manual activity registration
SecureWebLock.registerActivity();
```

### State Changes

You can listen to lock state changes using the provided stream:

```dart
SecureWebLock.stateStream.listen((state) {
  bool isLocked = state.isLocked;
  bool isEnabled = state.isEnabled;
  
  // Update your UI or take actions based on the new state
});
```

## Custom Lock Screen

You can provide your own custom lock screen:

```dart
ActivityObserver(
  navigatorKey: _navigatorKey,
  lockScreenBuilder: (context, userIdentifier, onUnlock) {
    return CustomLockScreen(
      userIdentifier: userIdentifier,
      onUnlock: onUnlock,
    );
  },
  child: MaterialApp(...),
)
```

## Using with Different Routing Systems

### 1. For Navigator 1.0:
Use the provided setup with `navigatorKey`.

### 2. For Navigator 2.0 / go_router:
Add the navigator observer to your router:

```dart
final router = GoRouter(
  observers: [
    SecureWebLock.createRouterObserver(),
  ],
  routes: [
    // ...your routes
  ],
);
```

### 3. For other routing solutions:
Use the `isExcludedRouteCallback` for custom route tracking.

## License

This package is available under the MIT License.