import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../models/course.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/secure_storage_service.dart';
import '../utils/theme_manager.dart';
import '../utils/logger.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  final String _tag = 'SplashScreen';
  bool _initialized = false;
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService.instance;
  final SecureStorageService _secureStorage = SecureStorageService();
  late Future<List<Course>> _coursesFuture;
  String _statusMessage = 'Initializing...';

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _particleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  // Particle animation variables
  final List<Particle> _particles = [];
  final int _particleCount = 20;

  @override
  void initState() {
    super.initState();
    Logger.i(_tag, 'Initializing splash screen');
    
    // Initialize animation controllers
    _setupAnimations();
    
    // Generate particles
    _generateParticles();
    
    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
    _initializeApp();
  }

  void _setupAnimations() {
    // Pulse animation for the logo
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Rotation animation for decorative elements
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotationController);

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    // Start animations
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
    _particleController.repeat();
  }

  void _generateParticles() {
    final random = math.Random();
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 4 + 2,
        speed: random.nextDouble() * 0.5 + 0.1,
        opacity: random.nextDouble() * 0.6 + 0.2,
      ));
    }
  }

  Future<void> _initializeApp() async {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);

    Logger.i(_tag, 'Waiting for theme to initialize');
    _updateStatus('Loading theme...');

    // Wait for theme initialization
    bool isThemeReady = false;
    try {
      await themeManager.initialized;
      isThemeReady = true;
      Logger.i(_tag, 'Theme initialized successfully');
    } catch (e) {
      Logger.e(_tag, 'Error during theme initialization', error: e);
      isThemeReady = themeManager.isInitialized;
      if (isThemeReady) {
        Logger.i(_tag, 'Theme was already initialized');
      }
    }

    if (!isThemeReady) {
      Logger.i(_tag, 'Waiting for theme manager to complete initialization');
      while (!themeManager.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 50));
        if (!mounted) return;
      }
      Logger.i(_tag, 'Theme is now initialized');
    }

    // Check authentication status
    Logger.i(_tag, 'Checking authentication status');
    _updateStatus('Checking authentication...');

    bool isLoggedIn = await _authService.isLoggedIn();
    Logger.i(_tag, 'Current auth status: $isLoggedIn');

    // If not logged in, try auto-login with saved credentials
    if (!isLoggedIn) {
      Logger.i(_tag, 'Not logged in, checking for saved credentials');
      _updateStatus('Checking saved credentials...');

      try {
        final savedCredentials = await _secureStorage.getSavedCredentials();

        if (savedCredentials != null) {
          Logger.i(_tag, 'Found saved credentials, attempting auto-login');
          _updateStatus('Signing in automatically...');

          final result = await _authService.signIn(
            savedCredentials.email,
            savedCredentials.password,
          );

          if (result['success']) {
            Logger.i(_tag, 'Auto-login successful');
            isLoggedIn = true;
            _updateStatus('Login successful!');
          } else {
            Logger.w(_tag, 'Auto-login failed: ${result['message']}');
            _updateStatus('Auto-login failed, please sign in manually');
            await _secureStorage.clearCredentials();
            await Future.delayed(const Duration(seconds: 1));
          }
        } else {
          Logger.i(_tag, 'No saved credentials found');
        }
      } catch (e) {
        Logger.e(_tag, 'Error during auto-login attempt', error: e);
        _updateStatus('Auto-login failed');
        await _secureStorage.clearCredentials();
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    if (isLoggedIn) {
      Logger.i(_tag, 'User is authenticated, preloading courses');
      _updateStatus('Loading courses...');
      _coursesFuture = _apiService.getCourseList();

      try {
        final courses = await _coursesFuture;
        Logger.i(_tag, 'Preloaded ${courses.length} courses successfully');
        _updateStatus('Ready!');
      } catch (e) {
        Logger.e(_tag, 'Error preloading courses', error: e);
        _coursesFuture = Future.value([]);
        _updateStatus('Ready!');
      }
    }

    if (!mounted) return;

    Logger.i(_tag, 'App initialization complete');
    setState(() {
      _initialized = true;
    });
  }

  void _updateStatus(String message) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
      });
    }
  }

  void _navigateToNextScreen() async {
    if (!mounted) return;

    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);

    final isLoggedIn = await _authService.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      Logger.i(_tag, 'Navigating to HomeScreen (authenticated)');
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              HomeScreen(preloadedCourses: _coursesFuture),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } else {
      Logger.i(_tag, 'Navigating to LoginScreen (not authenticated)');
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDarkMode = themeManager.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    // Navigate based on authentication status once initialization is complete
    if (_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            _navigateToNextScreen();
          }
        });
      });
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    AppConstants.paletteNeutral900,
                    AppConstants.paletteNeutral800,
                    Color.alphaBlend(
                      AppConstants.palettePrimary.withOpacity(0.1),
                      AppConstants.paletteNeutral800,
                    ),
                  ]
                : [
                    AppConstants.paletteNeutral000,
                    Color.alphaBlend(
                      AppConstants.palettePrimary.withOpacity(0.08),
                      AppConstants.paletteNeutral000,
                    ),
                    Color.alphaBlend(
                      AppConstants.palettePrimary.withOpacity(0.15),
                      AppConstants.paletteNeutral100,
                    ),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Animated particles background
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(
                    particles: _particles,
                    progress: _particleController.value,
                    color: colorScheme.primary.withOpacity(0.3),
                  ),
                  size: Size.infinite,
                );
              },
            ),

            // Rotating decorative elements
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Positioned.fill(
                  child: Stack(
                    children: [
                      // Top-left decoration
                      Positioned(
                        top: -50,
                        left: -50,
                        child: Transform.rotate(
                          angle: _rotationAnimation.value,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.secondary.withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Bottom-right decoration
                      Positioned(
                        bottom: -75,
                        right: -75,
                        child: Transform.rotate(
                          angle: -_rotationAnimation.value,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.tertiary.withOpacity(0.15),
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo section - clean and simple
                  Container(
                    width: MediaQuery.of(context).size.width * 0.75, 
                    //height: 220,
                    child: Image.asset(
                      'lib/assets/full_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                //  const SizedBox(height: 40),

                  // // Tagline
                  // Text(
                  //   'Your Personalized Learning Companion',
                  //   style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  //     color: isDarkMode
                  //         ? Colors.white.withOpacity(0.8)
                  //         : Colors.black.withOpacity(0.7),
                  //     fontWeight: FontWeight.w500,
                  //     letterSpacing: 0.5,
                  //   ),
                  //   textAlign: TextAlign.center,
                  // )
                  //     .animate()
                  //     .fadeIn(delay: 400.ms, duration: 800.ms)
                  //     .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 80),

                  // Loading animation
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer ring
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                        ),
                        // Inner ring with animation
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .rotate(duration: 2000.ms)
                      .fadeIn(delay: 600.ms, duration: 400.ms),

                  const SizedBox(height: 32),

                  // Status message with typewriter effect
                  Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _statusMessage,
                        key: ValueKey(_statusMessage),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 800.ms, duration: 400.ms),
                ],
              ),
            ),

            // Bottom decorative elements
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary.withOpacity(0.6),
                    ),
                  )
                      .animate(
                        onPlay: (controller) => controller.repeat(),
                      )
                      .fade(
                        duration: 1000.ms,
                        delay: (index * 200).ms,
                      );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Particle class for floating animation
class Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

// Custom painter for particle effects
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final Color color;

  ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final particle in particles) {
      // Update particle position
      particle.y -= particle.speed * progress * 0.01;
      if (particle.y < -0.1) {
        particle.y = 1.1;
        particle.x = math.Random().nextDouble();
      }

      // Draw particle
      canvas.drawCircle(
        Offset(
          particle.x * size.width,
          particle.y * size.height,
        ),
        particle.size,
        paint..color = color.withOpacity(particle.opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
