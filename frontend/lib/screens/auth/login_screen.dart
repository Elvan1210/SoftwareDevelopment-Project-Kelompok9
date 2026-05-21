import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';

import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../dashboard/siswa/siswa_main_layout.dart';
import '../dashboard/admin/admin_main_layout.dart';
import '../dashboard/guru/guru_main_layout.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();
  bool _isLoading        = false;
  bool _isPasswordVisible = false;
  late final AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailCtrl.text.trim(), 'password': _passwordCtrl.text}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (!mounted) return;
        final String token                     = data['token'];
        final String role                      = data['user']['role'];
        final Map<String, dynamic> userData    = data['user'];
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
        _showError(data['message'] ?? 'Login gagal');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: Theme.of(context).textTheme.bodyLarge)),
      ]),
      backgroundColor: AppTheme.rose,
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size   = MediaQuery.of(context).size;
    final isWide = size.width > 860;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: Stack(
        children: [
          _buildBackground(isDark),
          isWide ? _buildWide(isDark) : _buildNarrow(isDark),
        ],
      ),
    );
  }

  Widget _buildBackground(bool isDark) {
    return Stack(children: [
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0D0D1A), const Color(0xFF0F0F23), const Color(0xFF0D0D1A)]
                : [const Color(0xFFF0EEFF), const Color(0xFFF8F7FF), const Color(0xFFEEF2FF)],
          ),
        ),
      ),
      Positioned(top: -160, left: -120,
        child: AnimatedBuilder(animation: _floatCtrl, builder: (_, __) =>
          Transform.translate(offset: Offset(0, 15 * _floatCtrl.value),
            child: Container(width: 520, height: 520, decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppTheme.indigoPrimary.withAlpha(isDark ? 60 : 35), Colors.transparent,
              ]),
            )),
          ),
        ),
      ),
      Positioned(bottom: -200, right: -80,
        child: AnimatedBuilder(animation: _floatCtrl, builder: (_, __) =>
          Transform.translate(offset: Offset(0, -12 * _floatCtrl.value),
            child: Container(width: 600, height: 600, decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppTheme.primary.withAlpha(isDark ? 45 : 25), Colors.transparent,
              ]),
            )),
          ),
        ),
      ),
      Positioned.fill(child: CustomPaint(painter: _DotGrid(isDark))),
    ]);
  }

  Widget _buildWide(bool isDark) {
    return Row(children: [
      // Left panel — branding
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(64),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _logo(),
            const Spacer(),
            _illustrationCard(isDark),
            const SizedBox(height: 48),
            Text('Selamat Datang\nKembali!', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.5, height: 1.1,
              color: isDark ? AppTheme.textDark : AppTheme.textLight)),
            const SizedBox(height: 16),
            Text('Masuk untuk mengakses platform akademik\ndan pantau perkembangan belajarmu.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt, height: 1.7)),
            const SizedBox(height: 32),
            Wrap(spacing: 10, runSpacing: 10, children: [
              _badge(Icons.auto_graph_rounded, 'Nilai & Progres'),
              _badge(Icons.calendar_month_rounded, 'Jadwal Kelas'),
              _badge(Icons.assignment_rounded, 'Tugas & Ujian'),
            ]),
            const Spacer(),
            Text('© 2025 MyPSKD. All rights reserved.',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt)),
          ]),
        ).animate().fadeIn(duration: 700.ms),
      ),
      // Right panel — form
      Container(
        width: 480, height: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          border: Border(left: BorderSide(
            color: isDark ? AppTheme.indigoPrimary.withAlpha(30) : AppTheme.lightBorder)),
          boxShadow: [BoxShadow(
            color: isDark ? Colors.black.withAlpha(160) : AppTheme.indigoPrimary.withAlpha(20),
            blurRadius: 0, offset: const Offset(-10, 0),
          )],
        ),
        child: Center(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
          child: _form(isDark),
        )),
      ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.04),
    ]);
  }

  Widget _buildNarrow(bool isDark) {
    return SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(children: [_logo(), const SizedBox(height: 40), _form(isDark)]),
      ),
    ))).animate().fadeIn(duration: 600.ms);
  }

  Widget _logo() {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.indigoPrimary, AppTheme.primary],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.zero,
          boxShadow: [BoxShadow(color: AppTheme.indigoPrimary.withAlpha(100), blurRadius: 0, offset: const Offset(0, 5))],
        ),
        child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
      ),
      const SizedBox(width: 12),
      ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [AppTheme.indigoPrimary, AppTheme.primary],
        ).createShader(bounds),
        child: Text('MyPSKD', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Colors.white)),
      ),
    ]);
  }

  Widget _illustrationCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: isDark ? AppTheme.indigoPrimary.withAlpha(40) : AppTheme.lightBorder),
        boxShadow: [BoxShadow(
          color: isDark ? AppTheme.indigoPrimary.withAlpha(30) : AppTheme.indigoPrimary.withAlpha(15),
          blurRadius: 0, offset: const Offset(0, 12),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppTheme.indigoPrimary.withAlpha(isDark ? 60 : 35),
                AppTheme.primary.withAlpha(isDark ? 40 : 20),
              ]),
              borderRadius: BorderRadius.zero,
            ),
            child: const Icon(Icons.trending_up_rounded, color: AppTheme.indigoPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Nilai Rata-Rata', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textMutedDk, fontWeight: FontWeight.w500)),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(colors: [AppTheme.indigoLight, AppTheme.primaryDark]).createShader(b),
              child: Text('89.2', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.emerald.withAlpha(30),
              borderRadius: BorderRadius.zero,
              border: Border.all(color: AppTheme.emerald.withAlpha(60)),
            ),
            child: Text('+4.3%', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.emerald, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [0.5, 0.7, 0.6, 0.85, 0.92].asMap().entries.map((e) =>
            _miniBar(e.value, ['Agu','Sep','Okt','Nov','Des'][e.key], highlight: e.key == 4)
          ).toList(),
        ),
      ]),
    );
  }

  Widget _miniBar(double h, String label, {bool highlight = false}) {
    return Expanded(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          height: 60 * h,
          decoration: BoxDecoration(
            gradient: highlight
                ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [AppTheme.indigoLight, AppTheme.indigoPrimary])
                : LinearGradient(colors: [
                    AppTheme.indigoPrimary.withAlpha(60), AppTheme.indigoPrimary.withAlpha(30)]),
            borderRadius: BorderRadius.zero,
            boxShadow: highlight ? [BoxShadow(color: AppTheme.indigoPrimary.withAlpha(80), blurRadius: 8)] : [],
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.textMutedDk, fontWeight: FontWeight.w500)),
      ]),
    ));
  }

  Widget _badge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.indigoPrimary.withAlpha(15),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppTheme.indigoPrimary.withAlpha(40)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppTheme.indigoPrimary),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.indigoPrimary, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _form(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(colors: [AppTheme.indigoPrimary, AppTheme.primary]).createShader(b),
          child: Text('Masuk ke Akun', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8, color: Colors.white)),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: -0.1),
        const SizedBox(height: 6),
        Text('Masukkan email dan kata sandi kamu',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt)),
        const SizedBox(height: 36),

        // Email
        _label('Nama Pengguna atau Email'),
        const SizedBox(height: 8),
        _textField(
          controller: _emailCtrl,
          hint: 'contoh@email.com',
          icon: Icons.person_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          isDark: isDark,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Email tidak boleh kosong';
            if (!v.contains('@')) return 'Email tidak valid';
            return null;
          },
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
        const SizedBox(height: 20),

        // Password
        _label('Kata Sandi'),
        const SizedBox(height: 8),
        _textField(
          controller: _passwordCtrl,
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.done,
          isDark: isDark,
          onSubmitted: (_) => _login(),
          suffix: IconButton(
            icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18, color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password tidak boleh kosong';
            return null;
          },
        ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),
        const SizedBox(height: 8),

        // Lupa password
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              minimumSize: const Size(44, 44),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: ShaderMask(
              shaderCallback: (b) => const LinearGradient(colors: [AppTheme.indigoPrimary, AppTheme.primary]).createShader(b),
              child: Text('Lupa Kata Sandi?', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ).animate().fadeIn(delay: 480.ms),
        const SizedBox(height: 28),

        // Login button
        SizedBox(
          width: double.infinity, height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: _isLoading ? LinearGradient(colors: [AppTheme.indigoPrimary.withAlpha(120), AppTheme.primary.withAlpha(120)])
                  : const LinearGradient(colors: [AppTheme.indigoPrimary, AppTheme.primary]),
              borderRadius: BorderRadius.zero,
              boxShadow: _isLoading ? [] : [BoxShadow(color: AppTheme.indigoPrimary.withAlpha(100), blurRadius: 0, offset: const Offset(0, 8))],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                foregroundColor: Colors.white, elevation: 0,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                disabledBackgroundColor: Colors.transparent,
              ),
              child: _isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text('Masuk', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
        const SizedBox(height: 32),

        Center(child: Text('EduAdmin — Platform Manajemen Sekolah',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt))),
      ]),
    );
  }

  Widget _label(String text) => Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600,
    color: AppTheme.indigoPrimary));

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    Widget? suffix,
    void Function(String)? onSubmitted,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500,
        color: isDark ? AppTheme.textDark : AppTheme.textLight),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: isDark ? AppTheme.textMutedDk.withAlpha(150) : AppTheme.textMutedLt.withAlpha(150)),
        prefixIcon: Icon(icon, size: 18,
          color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
        suffixIcon: suffix,
        filled: true,
        fillColor: isDark ? AppTheme.darkCard : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppTheme.indigoPrimary, width: 1.8)),
        errorBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppTheme.rose)),
        focusedErrorBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppTheme.rose, width: 1.8)),
        errorStyle: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}

class _DotGrid extends CustomPainter {
  final bool isDark;
  _DotGrid(this.isDark);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = AppTheme.indigoPrimary.withAlpha(isDark ? 18 : 10)..strokeCap = StrokeCap.round;
    for (double x = 0; x < size.width; x += 30) {
      for (double y = 0; y < size.height; y += 30) {
        canvas.drawCircle(Offset(x, y), 1.0, p);
      }
    }
  }
  @override bool shouldRepaint(_DotGrid o) => false;
}