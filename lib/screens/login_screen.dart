import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';
import 'verification_screen.dart';
import 'home_screen.dart';
import 'privacy_policy_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final AuthService _authService = AuthService.instance;

  bool _isLoading = false;
  bool _isSignUpMode = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  static const String _tag = 'LoginScreen';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (_isSignUpMode) {
      if (value == null || value.isEmpty) {
        return 'Please confirm your password';
      }
      if (value != _passwordController.text) {
        return 'Passwords do not match';
      }
    }
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    if (_isSignUpMode) {
      if (value == null || value.isEmpty) {
        return 'Phone number is required';
      }
      // Basic phone number validation (adjust regex based on your requirements)
      if (!RegExp(
        r'^\+?[\d\s\-\(\)]{10,}$',
      ).hasMatch(value.replaceAll(' ', ''))) {
        return 'Please enter a valid phone number';
      }
    }
    return null;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        _phoneController.text.trim(),
      );

      if (result['success']) {
        Logger.i(_tag, 'Signup successful, navigating to verification');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => VerificationScreen(
                    username: result['username'],
                    email: _emailController.text.trim(),
                  ),
            ),
          );
        }
      } else {
        _showSnackBar(result['message'], isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (result['success']) {
        Logger.i(_tag, 'Signin successful, navigating to home');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        _showSnackBar(result['message'], isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App logo and title
                  Icon(Icons.school, size: 80, color: colorScheme.primary),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Text(
                    'Lesson Buddy',
                    style: AppConstants.headingStyle.copyWith(
                      color: colorScheme.primary,
                      fontSize: 32,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.largePadding * 2),

                  // Title
                  Text(
                    _isSignUpMode ? 'Create Account' : 'Welcome Back',
                    style: AppConstants.headingStyle.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Text(
                    _isSignUpMode
                        ? 'Sign up to get started'
                        : 'Sign in to continue',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.largePadding),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: _validateEmail,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),

                  // Phone number field (only for signup)
                  if (_isSignUpMode) ...[
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: _validatePhoneNumber,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '+1 (555) 123-4567',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                      ),
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),
                  ],

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction:
                        _isSignUpMode
                            ? TextInputAction.next
                            : TextInputAction.done,
                    validator: _validatePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                    ),
                  ),

                  // Confirm password field (only for signup)
                  if (_isSignUpMode) ...[
                    const SizedBox(height: AppConstants.defaultPadding),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      validator: _validateConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(
                              () =>
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                            );
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                      ),
                    ),
                  ],

                  const SizedBox(height: AppConstants.largePadding),

                  // Submit button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : (_isSignUpMode ? _handleSignUp : _handleSignIn),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child:
                          _isLoading
                              ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                              : Text(
                                _isSignUpMode ? 'Sign Up' : 'Sign In',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                  ),

                  const SizedBox(height: AppConstants.largePadding),

                  // Switch between login and signup
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSignUpMode
                            ? 'Already have an account? '
                            : "Don't have an account? ",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      TextButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () {
                                  setState(() {
                                    _isSignUpMode = !_isSignUpMode;
                                    _formKey.currentState?.reset();
                                    _emailController.clear();
                                    _passwordController.clear();
                                    _confirmPasswordController.clear();
                                    _phoneController.clear();
                                  });
                                },
                        child: Text(
                          _isSignUpMode ? 'Sign In' : 'Sign Up',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Privacy policy link (especially important for signup)
                  if (_isSignUpMode) ...[
                    const SizedBox(height: AppConstants.defaultPadding),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'By signing up, you agree to our',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const PrivacyPolicyScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Privacy Policy',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Footer privacy link for both modes
                  const SizedBox(height: AppConstants.largePadding),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Privacy Policy',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        decoration: TextDecoration.underline,
                      ),
                    ),
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
