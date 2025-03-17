import 'package:flutter/material.dart';

/// Default lock screen widget
class DefaultLockScreen extends StatelessWidget {
  /// User identifier (email, username) to display
  final String? userIdentifier;
  
  /// Function to call when unlocking
  final VoidCallback onUnlock;
  
  /// Constructor
  const DefaultLockScreen({
    Key? key,
    this.userIdentifier,
    required this.onUnlock,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              Text(
                'Session Locked',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                'Your session has been locked due to inactivity',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              if (userIdentifier != null) ...[
                Text(
                  userIdentifier!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onUnlock,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text('Unlock'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This is a demo lock screen. In production, implement your own authentication mechanism.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A more advanced lock screen with password
class PasswordLockScreen extends StatefulWidget {
  /// User identifier (email, username) to display
  final String? userIdentifier;
  
  /// Function to call when unlocking
  final bool Function(String) onPasswordSubmit;
  
  /// Function to call after successful unlock
  final VoidCallback onUnlock;
  
  /// Error message to display
  final String? errorMessage;
  
  /// Placeholder text for password field
  final String passwordHint;
  
  /// Constructor
  const PasswordLockScreen({
    Key? key,
    this.userIdentifier,
    required this.onPasswordSubmit,
    required this.onUnlock,
    this.errorMessage,
    this.passwordHint = 'Enter your password',
  }) : super(key: key);

  @override
  State<PasswordLockScreen> createState() => _PasswordLockScreenState();
}

class _PasswordLockScreenState extends State<PasswordLockScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _showError = false;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _errorMessage = widget.errorMessage;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _attemptUnlock() async {
    if (_passwordController.text.isEmpty) {
      setState(() {
        _showError = true;
        _errorMessage = 'Please enter your password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showError = false;
    });

    // Try to validate password
    final success = widget.onPasswordSubmit(_passwordController.text);

    if (success) {
      widget.onUnlock();
    } else {
      setState(() {
        _showError = true;
        _errorMessage = 'Incorrect password';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 48,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              Text(
                'Session Locked',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                'Your session has been locked due to inactivity',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              if (widget.userIdentifier != null) ...[
                Text(
                  widget.userIdentifier!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: widget.passwordHint,
                  errorText: _showError ? _errorMessage : null,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
                onSubmitted: (_) => _attemptUnlock(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _attemptUnlock,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Unlock'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}