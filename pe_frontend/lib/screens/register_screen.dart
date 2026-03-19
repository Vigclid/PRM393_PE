import 'dart:async';
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/user_api.dart';

enum _EmailStatus { idle, checking, available, taken }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;
  _EmailStatus _emailStatus = _EmailStatus.idle;
  Timer? _debounce;

  static final _emailRegex = RegExp(
    r'^[\w.+\-]+@[a-zA-Z0-9\-]+\.[a-zA-Z0-9\-.]+$',
  );

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Email existence check — debounced 600 ms
  // ---------------------------------------------------------------------------
  void _onEmailChanged() {
    _debounce?.cancel();
    final email = _emailController.text.trim();

    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      setState(() => _emailStatus = _EmailStatus.idle);
      return;
    }

    setState(() => _emailStatus = _EmailStatus.checking);
    _debounce = Timer(
      const Duration(milliseconds: 600),
      () => _checkEmail(email),
    );
  }

  Future<void> _checkEmail(String email) async {
    try {
      final exists = await UserApi.checkEmailExists(email);
      if (!mounted) return;
      // Only apply result if the field hasn't changed since the call started.
      if (_emailController.text.trim() == email) {
        setState(
          () => _emailStatus = exists
              ? _EmailStatus.taken
              : _EmailStatus.available,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _emailStatus = _EmailStatus.idle);
    }
  }

  // ---------------------------------------------------------------------------
  // Validators
  // ---------------------------------------------------------------------------
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (value.length > 255) return 'Email must not exceed 255 characters';
    if (!_emailRegex.hasMatch(value)) return 'Enter a valid email address';
    if (_emailStatus == _EmailStatus.taken) {
      return 'This email is already registered';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    if (value.length > 255) return 'Password must not exceed 255 characters';
    return null;
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------
  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    setState(() => _loading = true);
    try {
      await UserApi.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! You can now log in.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } on NetworkException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Email suffix indicator
  // ---------------------------------------------------------------------------
  Widget? get _emailSuffix => switch (_emailStatus) {
    _EmailStatus.idle => null,
    _EmailStatus.checking => const Padding(
      padding: EdgeInsets.all(12),
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
    _EmailStatus.available => const Icon(
      Icons.check_circle_outline,
      color: Colors.greenAccent,
      size: 20,
    ),
    _EmailStatus.taken => const Icon(
      Icons.cancel_outlined,
      color: Colors.redAccent,
      size: 20,
    ),
  };

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create Account',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign up to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    maxLength: 255,
                    enabled: !_loading,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      suffixIcon: _emailSuffix,
                    ),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    maxLength: 255,
                    enabled: !_loading,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _onRegister,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                        : const Text('Register'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
