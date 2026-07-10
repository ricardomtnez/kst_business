// lib/features/auth/presentation/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kst_business/core/theme/app_theme.dart';
import 'package:kst_business/core/constants/app_constants.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  Future<void> _startTimer() async {
    // Exact aesthetic delay for loading orbits and shimmering branding text
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null) {
      try {
        // Fetch the user's role from public.user_profiles
        final res = await supabase
            .from('user_profiles')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();

        if (res != null && mounted) {
          final role = res['role'] as String?;
          if (role == AppConstants.roleAdmin) {
            context.goNamed('admin-dashboard');
            return;
          } else if (role == AppConstants.roleVendedor) {
            context.goNamed('sales-dashboard');
            return;
          }
        }
      } catch (_) {}
      // Fallback
      if (mounted) {
        context.goNamed('sales-dashboard');
      }
    } else {
      if (mounted) {
        context.goNamed('login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient with subtle animation
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.brandGradient,
            ),
          ),
          
          // Ambient decorative blue light glows in the background
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.15),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.15, 1.15), duration: 4.seconds, curve: Curves.easeInOut),
          ),
          Positioned(
            bottom: -120,
            right: -120,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondaryVariant.withValues(alpha: 0.25),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.2, 1.2), duration: 3.seconds, curve: Curves.easeInOut),
          ),

          // Center loading contents
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Sonar ripple effect, Rotating Tech Orbits and logo container in Stack
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Sonar Ring 1 - Royal Blue
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.5),
                          width: 2.0,
                        ),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .scale(begin: const Offset(0.85, 0.85), end: const Offset(2.2, 2.2), duration: 2500.ms, curve: Curves.easeOutCubic)
                    .fadeOut(duration: 2500.ms),

                    // Rotating Tech Orbit 1 (Clockwise)
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CustomPaint(
                        painter: _DashCirclePainter(
                          color: AppColors.accent.withValues(alpha: 0.5),
                          dashCount: 16,
                          drawNodes: true,
                        ),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .rotate(begin: 0, end: 1, duration: 10.seconds),

                    // Rotating Tech Orbit 2 (Counter-Clockwise)
                    SizedBox(
                      width: 210,
                      height: 210,
                      child: CustomPaint(
                        painter: _DashCirclePainter(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                          dashCount: 24,
                          drawNodes: false,
                        ),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .rotate(begin: 1, end: 0, duration: 15.seconds),

                    // Logo Card with Blue Highlights
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.35),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.4),
                            blurRadius: 35,
                            spreadRadius: 3,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Image.asset(
                          'assets/images/logo_completo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Text(
                                'KST',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.secondary,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(begin: const Offset(0.96, 0.96), end: const Offset(1.04, 1.04), duration: 1800.ms, curve: Curves.easeInOutSine)
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .shimmer(duration: 2.seconds, delay: 1.seconds, color: Colors.white38),
                  ],
                ),

                const SizedBox(height: 48),

                // App Brand Name with metal sweep shimmer
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                )
                .animate()
                .fadeIn(delay: 200.ms, duration: 600.ms)
                .slideY(begin: 0.15, curve: Curves.easeOutQuad)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .shimmer(duration: 2500.ms, color: Colors.white60),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  AppConstants.companyName.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                )
                .animate()
                .fadeIn(delay: 400.ms, duration: 600.ms)
                .slideY(begin: 0.15, curve: Curves.easeOutQuad),

                const SizedBox(height: 56),

                // Sleek loading line indicator in corporate blue/white
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 140,
                    height: 4,
                    color: Colors.white10,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 60,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.secondary, Colors.white],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .align(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        duration: 1500.ms,
                        curve: Curves.easeInOutSine,
                      ),
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: 600.ms, duration: 500.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashCirclePainter extends CustomPainter {
  final Color color;
  final int dashCount;
  final bool drawNodes;

  _DashCirclePainter({
    required this.color,
    this.dashCount = 12,
    this.drawNodes = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final nodePaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final double radius = size.width / 2;
    final double center = size.width / 2;

    final double dashAngle = (2 * 3.1415926535) / dashCount;
    for (int i = 0; i < dashCount; i++) {
      if (i % 2 == 0) {
        canvas.drawArc(
          Rect.fromCircle(center: Offset(center, center), radius: radius),
          i * dashAngle,
          dashAngle * 0.8,
          false,
          paint,
        );

        // Draw small tech node dots along the orbit
        if (drawNodes && i % 4 == 0) {
          final double angle = i * dashAngle;
          final double x = center + radius * double.parse(MathHelper.cos(angle));
          final double y = center + radius * double.parse(MathHelper.sin(angle));
          canvas.drawCircle(Offset(x, y), 3.0, nodePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MathHelper {
  // Simple helper to calculate trigonometric coordinates without importing dart:math explicitly
  static String cos(double x) {
    return _cos(x).toStringAsFixed(5);
  }

  static String sin(double x) {
    return _sin(x).toStringAsFixed(5);
  }

  static double _cos(double x) {
    x = x % (2 * 3.1415926535);
    double term = 1.0;
    double sum = 1.0;
    for (int i = 1; i <= 6; i++) {
      term = -term * x * x / ((2 * i - 1) * (2 * i));
      sum += term;
    }
    return sum;
  }

  static double _sin(double x) {
    x = x % (2 * 3.1415926535);
    double term = x;
    double sum = x;
    for (int i = 1; i <= 6; i++) {
      term = -term * x * x / ((2 * i) * (2 * i + 1));
      sum += term;
    }
    return sum;
  }
}
