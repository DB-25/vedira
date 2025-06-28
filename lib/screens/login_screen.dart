import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/secure_storage_service.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';
import '../utils/theme_manager.dart';
import 'verification_screen.dart';
import 'home_screen.dart';
import 'privacy_policy_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final AuthService _authService = AuthService.instance;
  final SecureStorageService _secureStorage = SecureStorageService();

  bool _isLoading = false;
  bool _isSignUpMode = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = false;
  bool _isLoadingCredentials = true;
  bool _isModeTransitioning = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _modeTransitionController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _modeSlideAnimation;
  late Animation<double> _modeOpacityAnimation;

  static const String _tag = 'LoginScreen';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadSavedCredentials();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _modeTransitionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _modeSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _modeTransitionController,
      curve: Curves.easeInOutCubic,
    ));

    _modeOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _modeTransitionController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    ));

    _fadeController.forward();
    _modeTransitionController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _modeTransitionController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final savedCredentials = await _secureStorage.getSavedCredentials();
      if (savedCredentials != null && mounted) {
        setState(() {
          _emailController.text = savedCredentials.email;
          _passwordController.text = savedCredentials.password;
          _rememberMe = savedCredentials.rememberMe;
        });
        // Safe email logging - handle edge cases
        final emailDisplay =
            savedCredentials.email.contains('@')
                ? '${savedCredentials.email.substring(0, savedCredentials.email.indexOf('@'))}***'
                : 'user***';
        Logger.i(_tag, 'Loaded saved credentials for: $emailDisplay');
      }
    } catch (e) {
      Logger.e(
        _tag,
        'Error loading saved credentials, secure storage may not be available',
        error: e,
      );
      // Continue without saved credentials if secure storage fails
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCredentials = false;
        });
      }
    }
  }

  Future<void> _toggleMode() async {
    if (_isModeTransitioning) return; // Prevent multiple toggles during transition
    
    setState(() => _isModeTransitioning = true);
    
    // Add haptic feedback
    HapticFeedback.lightImpact();
    
    // Start the transition animation
    await _modeTransitionController.reverse();
    
    // Update the state in the middle of the animation
    setState(() {
      _isSignUpMode = !_isSignUpMode;
      // Clear form errors when switching modes
      _formKey.currentState?.reset();
    });
    
    // Complete the transition animation
    await _modeTransitionController.forward();
    
    setState(() => _isModeTransitioning = false);
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
        // Save credentials if remember me is checked
        if (_rememberMe) {
          try {
            await _secureStorage.saveCredentials(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              rememberMe: _rememberMe,
            );
          } catch (e) {
            Logger.e(
              _tag,
              'Failed to save credentials, but login successful',
              error: e,
            );
            // Don't block login if secure storage fails
            _showSnackBar(
              'Login successful, but failed to save credentials',
              isError: false,
            );
          }
        } else {
          // Clear any existing saved credentials if remember me is unchecked
          try {
            await _secureStorage.clearCredentials();
          } catch (e) {
            Logger.e(_tag, 'Failed to clear credentials', error: e);
            // Don't block login if secure storage fails
          }
        }

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

  Widget _buildLogo([bool isKeyboardVisible = false]) {
    return Container(
      height: MediaQuery.of(context).size.height * (isKeyboardVisible ? 0.1 : 0.15),
      width: MediaQuery.of(context).size.width * 0.6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 50,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          'lib/assets/full_logo.png',
          fit: BoxFit.fitWidth,
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          _isSignUpMode ? 'Create Account' : 'Welcome Back',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          _isSignUpMode
              ? 'Join the personalized learning journey'
              : 'Sign in to continue your learning',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }



  Widget _buildFormCard(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colorScheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Email field
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'Enter your email address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
              theme: theme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),

            // Phone number field (only for signup)
            if (_isSignUpMode) ...[
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: '+1 (555) 123-4567',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: _validatePhoneNumber,
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 16),
            ],

            // Password field
            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Enter your password',
              icon: Icons.lock_outlined,
              obscureText: _obscurePassword,
              validator: _validatePassword,
              theme: theme,
              colorScheme: colorScheme,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),

            // Confirm password field (only for signup)
            if (_isSignUpMode) ...[
              const SizedBox(height: 16),
              _buildTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                hint: 'Re-enter your password',
                icon: Icons.lock_outlined,
                obscureText: _obscureConfirmPassword,
                validator: _validateConfirmPassword,
                theme: theme,
                colorScheme: colorScheme,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onPressed: () {
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Remember Me checkbox (only for sign in)
            if (!_isSignUpMode) ...[
              _buildRememberMeCheckbox(theme, colorScheme),
              const SizedBox(height: 20),
            ],

            // Submit button
            _buildSubmitButton(theme, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    required ThemeData theme,
    required ColorScheme colorScheme,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: colorScheme.surface.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      ),
    );
  }

  Widget _buildRememberMeCheckbox(ThemeData theme, ColorScheme colorScheme) {
    return InkWell(
      onTap: _isLoading ? null : () {
        setState(() {
          _rememberMe = !_rememberMe;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _rememberMe ? colorScheme.primary : colorScheme.outline.withOpacity(0.5),
                  width: 2,
                ),
                color: _rememberMe ? colorScheme.primary : Colors.transparent,
              ),
              child: _rememberMe
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: colorScheme.onPrimary,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              'Remember me',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme, ColorScheme colorScheme) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : (_isSignUpMode ? _handleSignUp : _handleSignIn),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: _isLoading ? 0 : 4,
          shadowColor: colorScheme.primary.withOpacity(0.3),
          disabledBackgroundColor: colorScheme.primary.withOpacity(0.6),
          disabledForegroundColor: colorScheme.onPrimary.withOpacity(0.7),
        ),
        child: _isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colorScheme.onPrimary,
                ),
              )
            : Text(
                _isSignUpMode ? 'Create Account' : 'Sign In',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
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
              onPressed: (_isLoading || _isModeTransitioning) ? null : _toggleMode,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: _isModeTransitioning
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    )
                  : Text(
                      _isSignUpMode ? 'Sign In' : 'Sign Up',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),

        // Privacy policy link
        const SizedBox(height: 8),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Show loading indicator while credentials are being loaded
    if (_isLoadingCredentials) {
      return Scaffold(
        backgroundColor: colorScheme.bodyBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.bodyBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
            final isKeyboardVisible = keyboardHeight > 0;
            
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: keyboardHeight > 0 ? 20 : 0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top spacing - smaller when keyboard is visible
                          SizedBox(height: isKeyboardVisible ? 20 : null),
                          if (!isKeyboardVisible) const Spacer(flex: 1),
                          
                          // Logo - smaller when keyboard is visible
                          Center(child: _buildLogo(isKeyboardVisible)),
                          
                          // Spacing after logo
                          SizedBox(height: isKeyboardVisible ? 16 : null),
                          if (!isKeyboardVisible) const Spacer(flex: 1),
                          
                          // Welcome section with simple fade transition
                          AnimatedBuilder(
                            animation: _modeTransitionController,
                            builder: (context, child) {
                              return FadeTransition(
                                opacity: _modeOpacityAnimation,
                                child: _buildWelcomeSection(theme, colorScheme),
                              );
                            },
                          ),
                          
                          // Spacing after welcome
                          SizedBox(height: isKeyboardVisible ? 16 : 20),
                          
                          // Form card with simple fade transition
                          AnimatedBuilder(
                            animation: _modeTransitionController,
                            builder: (context, child) {
                              return FadeTransition(
                                opacity: _modeOpacityAnimation,
                                child: _buildFormCard(theme, colorScheme),
                              );
                            },
                          ),
                          
                          // Spacing before footer
                          SizedBox(height: isKeyboardVisible ? 8 : 12),
                          
                          // Footer with simple fade transition
                          AnimatedBuilder(
                            animation: _modeTransitionController,
                            builder: (context, child) {
                              return FadeTransition(
                                opacity: _modeOpacityAnimation,
                                child: _buildFooter(theme, colorScheme),
                              );
                            },
                          ),
                          
                          // Bottom spacing
                          if (!isKeyboardVisible) const Spacer(flex: 1),
                          if (isKeyboardVisible) const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
