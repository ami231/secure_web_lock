import 'package:flutter/material.dart';

/// Default lock screen widget
class DefaultLockScreen extends StatelessWidget {
  /// Optional user identifier to display
  final String? userIdentifier;

  /// Callback when the user unlocks the screen
  final VoidCallback onUnlock;

  /// Constructor
  const DefaultLockScreen({
    Key? key,
    this.userIdentifier,
    required this.onUnlock,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              const Text(
                'Your session is locked',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (userIdentifier != null) ...[
                const SizedBox(height: 8),
                Text(
                  'User: $userIdentifier',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.lock_open),
                label: const Text('Unlock Session'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                onPressed: onUnlock,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
