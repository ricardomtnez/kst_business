// lib/presentation/screens/auth/login_screen.dart

import 'dart:ui'; // Required for ImageFilter backdrop blur
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kst_business/core/theme/app_theme.dart';
import 'package:kst_business/core/constants/app_constants.dart';
import 'package:kst_business/features/auth/providers/auth_provider.dart';
import 'package:kst_business/core/widgets/kst_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('remembered_email') ?? '';
      final remember = prefs.getBool('remember_me') ?? false;
      if (remember && email.isNotEmpty) {
        setState(() {
          _emailCtrl.text = email;
          _rememberMe = true;
        });
      }
    } catch (e) {
      debugPrint("Error loading remembered email: $e");
    }
  }

  Future<void> _saveRememberedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('remembered_email', _emailCtrl.text.trim());
        await prefs.setBool('remember_me', true);
      } else {
        await prefs.remove('remembered_email');
        await prefs.setBool('remember_me', false);
      }
    } catch (e) {
      debugPrint("Error saving remembered data: $e");
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    
    // Save email local state before signing in
    await _saveRememberedData();

    try {
      await ref.read(authNotifierProvider.notifier).signIn(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
          );
    } catch (e) {
      // Errors handled via ref.listen
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to authentication state for error popups
    ref.listen<AsyncValue<User?>>(authNotifierProvider, (previous, next) {
      next.maybeWhen(
        error: (err, _) {
          String displayError = err.toString();
          if (displayError.contains('Invalid login credentials')) {
            displayError = 'Credenciales de acceso incorrectas. Intenta de nuevo.';
          } else if (displayError.contains('Email not confirmed')) {
            displayError = 'El correo electrónico no ha sido verificado.';
          } else {
            displayError = displayError
                .replaceAll('Exception: ', '')
                .replaceAll('AuthException: ', '');
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      displayError,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
        orElse: () {},
      );
    });

    return Scaffold(
      body: Stack(
        children: [
          // 1. Deep institutional navy/blue background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF002447), // Very deep navy
                  Color(0xFF001224), // Almost black-blue
                  Color(0xFF00386C), // Rich corporate blue
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 2. Ambient light glows in background to give color to the glassmorphic blur
          Positioned(
            top: 100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0056A4).withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00C0FF).withValues(alpha: 0.08),
              ),
            ),
          ),

          // 3. Main Login Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Large, High-impact Brand Header
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1.5,
                            ),
                          ),
                          child: const KstLogo(size: 100) // Bigger logo
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .scale(begin: const Offset(0.9, 0.9)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      Center(
                        child: Text(
                          AppConstants.appName,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ).animate().fadeIn(delay: 150.ms),

                      Center(
                        child: Text(
                          AppConstants.companyTagline.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF88A8C8),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3.5,
                          ),
                        ),
                      ).animate().fadeIn(delay: 250.ms),

                      const SizedBox(height: 36),

                      // 4. Glassmorphic Login Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 40,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Iniciar Sesión',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      color: Colors.white,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Ingresa a tu cuenta corporativa KST',
                                    style: TextStyle(
                                      color: Color(0xFFBDD2E6),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  // Email input field (Frosted visual)
                                  TextFormField(
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600),
                                    decoration: InputDecoration(
                                      labelText: 'Correo electrónico',
                                      filled: true,
                                      fillColor: Colors.white.withValues(alpha: 0.05),
                                      labelStyle: const TextStyle(color: Color(0xFF90ADC6), fontSize: 13, fontWeight: FontWeight.w500),
                                      prefixIcon: const Icon(Icons.email_outlined, size: 20, color: Color(0xFF90ADC6)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.2),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: Colors.white, width: 1.8),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.5), width: 1.2),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: AppColors.error, width: 1.8),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Ingresa tu correo';
                                      if (!v.contains('@')) return 'Correo inválido';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Password input field (Frosted visual)
                                  TextFormField(
                                    controller: _passCtrl,
                                    obscureText: _obscure,
                                    style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600),
                                    decoration: InputDecoration(
                                      labelText: 'Contraseña',
                                      filled: true,
                                      fillColor: Colors.white.withValues(alpha: 0.05),
                                      labelStyle: const TextStyle(color: Color(0xFF90ADC6), fontSize: 13, fontWeight: FontWeight.w500),
                                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF90ADC6)),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                          size: 20,
                                          color: const Color(0xFF90ADC6),
                                        ),
                                        onPressed: () => setState(() => _obscure = !_obscure),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.2),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: Colors.white, width: 1.8),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.5), width: 1.2),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: AppColors.error, width: 1.8),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                                      if (v.length < 6) return 'Mínimo 6 caracteres';
                                      return null;
                                    },
                                    onFieldSubmitted: (_) => _login(),
                                  ),
                                  const SizedBox(height: 18),

                                  // Remember Me checkbox row
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: Theme(
                                          data: ThemeData(
                                            unselectedWidgetColor: const Color(0xFF90ADC6),
                                          ),
                                          child: Checkbox(
                                            value: _rememberMe,
                                            activeColor: Colors.white,
                                            checkColor: const Color(0xFF002447),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                            side: BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                                            onChanged: (val) {
                                              if (val != null) {
                                                setState(() => _rememberMe = val);
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: () => setState(() => _rememberMe = !_rememberMe),
                                        child: const Text(
                                          'Recordar datos',
                                          style: TextStyle(
                                            color: Color(0xFFD0E1F0),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),

                                  // Solid White Button with Navy Text for high-contrast premium feel
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: _loading ? Colors.white60 : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 15,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _loading ? null : _login,
                                        borderRadius: BorderRadius.circular(14),
                                        child: Center(
                                          child: _loading
                                              ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF002447)),
                                                  ),
                                                )
                                              : const Text(
                                                  'Ingresar',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w900,
                                                    color: Color(0xFF002447),
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.05, curve: Curves.easeOutQuad),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
