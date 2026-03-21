import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';

import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_shell.dart';
import '../dashboard/siswa/siswa_main_layout.dart';
import '../dashboard/admin/admin_main_layout.dart';
import '../dashboard/guru/guru_main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  late final AnimationController _blob1Controller;
  late final AnimationController _blob2Controller;

  @override
  void initState() {
    super.initState();
    _blob1Controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _blob2Controller = AnimationController(vsync: this, duration: const Duration(seconds: 11))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blob1Controller.dispose();
    _blob2Controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;
        final String token = data['token'];
        final String role = data['user']['role'];
        final Map<String, dynamic> userData = data['user'];
        await AuthService.saveSession(token, userData);
        if (!mounted) return;

        if (role == 'Admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminMainLayout(token: token)));
        } else if (role == 'Guru') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GuruMainLayout(userData: userData, token: token)));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SiswaMainLayout(userData: userData, token: token)));
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Login gagal'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // ── Animated Background ──────────────────────────────────
          _AnimatedBackground(isDark: isDark, blob1: _blob1Controller, blob2: _blob2Controller),

          // ── Centered Login Card ──────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _LoginCard(
                    emailController: _emailController,
                    passwordController: _passwordController,
                    formKey: _formKey,
                    isLoading: _isLoading,
                    isPasswordVisible: _isPasswordVisible,
                    onTogglePassword: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    onLogin: _login,
                    isDark: isDark,
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

// ── Animated Background Blobs ─────────────────────────────────────────────
class _AnimatedBackground extends StatelessWidget {
  final bool isDark;
  final AnimationController blob1, blob2;
  const _AnimatedBackground({required this.isDark, required this.blob1, required this.blob2});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF0F172A), const Color(0xFF020617)]
                  : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
            ),
          ),
        ),
        // Blob 1 (Blue)
        AnimatedBuilder(
          animation: blob1,
          builder: (_, __) => Positioned(
            top: -100 + 60 * blob1.value,
            left: -100 + 40 * blob1.value,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withAlpha(isDark ? 40 : 25),
              ),
            ),
          ),
        ),
        // Blob 2 (Purple)
        AnimatedBuilder(
          animation: blob2,
          builder: (_, __) => Positioned(
            bottom: -80 + 50 * blob2.value,
            right: -80 + 30 * blob2.value,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withAlpha(isDark ? 35 : 20),
              ),
            ),
          ),
        ),
        // Blur overlay
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: const SizedBox.expand(),
        ),
      ],
    );
  }
}

// ── Login Card ────────────────────────────────────────────────────────────
class _LoginCard extends StatelessWidget {
  final TextEditingController emailController, passwordController;
  final GlobalKey<FormState> formKey;
  final bool isLoading, isPasswordVisible, isDark;
  final VoidCallback onTogglePassword, onLogin;

  const _LoginCard({
    required this.emailController,
    required this.passwordController,
    required this.formKey,
    required this.isLoading,
    required this.isPasswordVisible,
    required this.isDark,
    required this.onTogglePassword,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      radius: 32,
      blurSigma: 20,
      padding: const EdgeInsets.all(32),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo/Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withAlpha(80), blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 36),
            )
                .animate()
                .scale(delay: 100.ms, curve: Curves.easeOutBack)
                .fadeIn(),
            const SizedBox(height: 28),

            // Title
            const Text('EduAdmin',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1))
                .animate().fadeIn(delay: 200.ms).slideY(begin: -0.1),
            const SizedBox(height: 6),
            Text('Masuk ke akun kamu',
                style: TextStyle(
                  fontSize: 15,
                  color: theme.colorScheme.onSurface.withAlpha(150),
                  fontWeight: FontWeight.w500,
                ))
                .animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 36),

            // Email Field
            AntigravityTextField(
              controller: emailController,
              hintText: 'Email address',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email tidak boleh kosong';
                if (!v.contains('@')) return 'Email tidak valid';
                return null;
              },
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
            const SizedBox(height: 16),

            // Password Field
            AntigravityTextField(
              controller: passwordController,
              hintText: 'Password',
              prefixIcon: Icons.lock_outlined,
              obscureText: !isPasswordVisible,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onLogin(),
              suffix: IconButton(
                icon: Icon(isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: onTogglePassword,
                color: theme.colorScheme.onSurface.withAlpha(120),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password tidak boleh kosong';
                return null;
              },
            ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
            const SizedBox(height: 28),

            // Login Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Masuk', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: 20),
            Text('EduAdmin — Platform Manajemen Sekolah',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(100)))
                .animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.08, curve: Curves.easeOutQuart);
  }
}