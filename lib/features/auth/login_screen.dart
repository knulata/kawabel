import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/models/student.dart';
import '../../core/theme/kawabel_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    await context.read<StudentProvider>().loadSaved();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final account = await googleSignIn.signIn();

      if (account == null) {
        // User cancelled the sign-in
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Gagal mendapatkan token dari Google.';
          });
        }
        return;
      }

      if (!mounted) return;
      final error =
          await context.read<StudentProvider>().loginWithGoogle(idToken);

      if (error != null && mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = error;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Login gagal, coba lagi.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: KColors.greenGradient,
        ),
        child: Stack(
          children: [
            // Subtle floating circles
            const _FloatingCircles(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Kawi the Owl
                      FadeInDown(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(40),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '\u{1F989}',
                              style: TextStyle(fontSize: 52),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      FadeInDown(
                        delay: const Duration(milliseconds: 150),
                        child: const Text(
                          'kawabel',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FadeInDown(
                        delay: const Duration(milliseconds: 250),
                        child: Text(
                          'kawan belajar',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withAlpha(200),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInDown(
                        delay: const Duration(milliseconds: 350),
                        child: Text(
                          'Masuk untuk mulai belajar dengan Kawi',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withAlpha(180),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Error message
                      AnimatedOpacity(
                        opacity: _errorMessage != null ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(40),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.yellowAccent.withAlpha(120)),
                            ),
                            child: Text(
                              _errorMessage ?? '',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.yellowAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Loading indicator or Google Sign-In button
                      FadeInUp(
                        delay: const Duration(milliseconds: 400),
                        child: _isLoading
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                ),
                              )
                            : _buildGoogleSignInButton(),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        elevation: 4,
        shadowColor: Colors.black.withAlpha(60),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: _signInWithGoogle,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google "G" logo
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CustomPaint(painter: _GoogleLogoPainter()),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Masuk dengan Google',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3C4043),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the Google "G" logo using paths.
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Blue
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    // Red
    final redPaint = Paint()..color = const Color(0xFFEA4335);
    // Yellow
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    // Green
    final greenPaint = Paint()..color = const Color(0xFF34A853);

    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Draw arcs for each color segment
    // Blue (right side)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.4, // start angle
      1.2, // sweep (roughly bottom-right)
      true,
      bluePaint,
    );

    // Green (bottom)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.8,
      1.0,
      true,
      greenPaint,
    );

    // Yellow (left)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      1.8,
      1.0,
      true,
      yellowPaint,
    );

    // Red (top)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.8,
      1.1,
      true,
      redPaint,
    );

    // White inner circle to create "G" shape
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.55, whitePaint);

    // Blue bar extending right from center
    canvas.drawRect(
      Rect.fromLTWH(w * 0.48, h * 0.38, w * 0.52, h * 0.24),
      bluePaint,
    );

    // White bar to cut the top of the blue bar
    canvas.drawRect(
      Rect.fromLTWH(w * 0.48, h * 0.0, w * 0.52, h * 0.38),
      whitePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Subtle floating circles for visual polish on the login screen.
class _FloatingCircles extends StatefulWidget {
  const _FloatingCircles();

  @override
  State<_FloatingCircles> createState() => _FloatingCirclesState();
}

class _FloatingCirclesState extends State<_FloatingCircles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Circle> _circles;

  @override
  void initState() {
    super.initState();
    final rng = Random(42);
    _circles = List.generate(8, (_) => _Circle.random(rng));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _CirclePainter(_circles, _controller.value),
        );
      },
    );
  }
}

class _Circle {
  final double x; // 0..1
  final double y; // 0..1
  final double radius;
  final double speed;
  final double phase;

  _Circle(this.x, this.y, this.radius, this.speed, this.phase);

  factory _Circle.random(Random rng) {
    return _Circle(
      rng.nextDouble(),
      rng.nextDouble(),
      20 + rng.nextDouble() * 40,
      0.3 + rng.nextDouble() * 0.7,
      rng.nextDouble() * 2 * pi,
    );
  }
}

class _CirclePainter extends CustomPainter {
  final List<_Circle> circles;
  final double t;

  _CirclePainter(this.circles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withAlpha(18);
    for (final c in circles) {
      final dx = c.x * size.width + sin(t * 2 * pi * c.speed + c.phase) * 30;
      final dy = c.y * size.height + cos(t * 2 * pi * c.speed + c.phase) * 30;
      canvas.drawCircle(Offset(dx, dy), c.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_CirclePainter old) => true;
}
