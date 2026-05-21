import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'otp_verify_screen.dart';
import '../../services/forgot_password_service.dart';
import '../../config/theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    final result =
        await ForgotPasswordService.sendOtp(_emailController.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              OtpVerifyScreen(email: _emailController.text.trim()),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'], style: Theme.of(context).textTheme.bodyLarge),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      // Back button + Logo
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.indigoPrimary.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 16,
                                color: AppTheme.indigoPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildLogo(),
                        ],
                      ).animate().fadeIn(duration: 500.ms),
                      const SizedBox(height: 48),

                       // Icon ilustrasi
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.indigoPrimary, AppTheme.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.indigoPrimary.withAlpha(80),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 150.ms)
                          .scale(begin: const Offset(0.8, 0.8)),
                      const SizedBox(height: 28),

                      // Judul & deskripsi
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [AppTheme.indigoPrimary, AppTheme.primary],
                        ).createShader(b),
                        child: Text(
                          'Lupa Kata Sandi?',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w800,
                            letterSpacing: -0.8, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.1),
                      const SizedBox(height: 10),
                      Text(
                        'Masukkan email akunmu dan kami akan mengirimkan kode verifikasi 6 digit untuk mereset kata sandimu.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                          height: 1.6),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 250.ms),
                      const SizedBox(height: 40),

                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Alamat Email'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _sendOtp(),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500,
                                color: isDark ? AppTheme.textDark : AppTheme.textLight),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Email tidak boleh kosong';
                                if (!v.contains('@')) return 'Email tidak valid';
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: 'contoh@email.com',
                                hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: isDark ? AppTheme.textMutedDk.withAlpha(150) : AppTheme.textMutedLt.withAlpha(150)),
                                prefixIcon: Icon(Icons.email_outlined, size: 18,
                                  color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt),
                                filled: true,
                                fillColor: isDark ? AppTheme.darkCard : Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.indigoPrimary, width: 1.8)),
                                errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.rose)),
                                focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.rose, width: 1.8)),
                              ),
                            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                            const SizedBox(height: 32),

                            // Tombol kirim
                            SizedBox(
                              width: double.infinity, height: 52,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: _isLoading
                                      ? LinearGradient(colors: [AppTheme.indigoPrimary.withAlpha(120), AppTheme.primary.withAlpha(120)])
                                      : const LinearGradient(colors: [AppTheme.indigoPrimary, AppTheme.primary]),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: _isLoading ? [] : [BoxShadow(color: AppTheme.indigoPrimary.withAlpha(100), blurRadius: 20, offset: const Offset(0, 8))],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _sendOtp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                                    foregroundColor: Colors.white, elevation: 0,
                                    disabledBackgroundColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(width: 22, height: 22,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                          const Icon(Icons.send_rounded, size: 18),
                                          const SizedBox(width: 8),
                                          Text('Kirim Kode Verifikasi', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                        ]),
                                ),
                              ),
                            ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Info card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.indigoPrimary.withAlpha(isDark ? 20 : 12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.indigoPrimary.withAlpha(isDark ? 50 : 30)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.indigoPrimary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Kode verifikasi berlaku selama 10 menit. Periksa folder spam jika email tidak masuk.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.indigoPrimary, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms),
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

  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.indigoPrimary, AppTheme.primary],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(9),
            boxShadow: [BoxShadow(color: AppTheme.indigoPrimary.withAlpha(80), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: const Icon(Icons.school_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(colors: [AppTheme.indigoPrimary, AppTheme.primary]).createShader(b),
          child: Text('MyPSKD', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: AppTheme.indigoPrimary));
  }

  Widget _buildBackground() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned(top: -100, right: -60,
          child: AnimatedBuilder(animation: _floatController, builder: (_, __) =>
            Transform.translate(offset: Offset(0, 10 * _floatController.value),
              child: Container(width: 300, height: 300,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppTheme.indigoPrimary.withAlpha(isDark ? 55 : 30), Colors.transparent,
                  ]))))),
        ),
        Positioned(bottom: -80, left: -40,
          child: AnimatedBuilder(animation: _floatController, builder: (_, __) =>
            Transform.translate(offset: Offset(0, -8 * _floatController.value),
              child: Container(width: 250, height: 250,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppTheme.primary.withAlpha(isDark ? 40 : 20), Colors.transparent,
                  ]))))),
        ),
        Positioned.fill(child: CustomPaint(painter: _DotGridPainter(isDark))),
      ],
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final bool isDark;
  _DotGridPainter(this.isDark);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = AppTheme.indigoPrimary.withAlpha(isDark ? 18 : 10)..strokeCap = StrokeCap.round;
    for (double x = 0; x < size.width; x += 28) {
      for (double y = 0; y < size.height; y += 28) {
        canvas.drawCircle(Offset(x, y), 1.2, p);
      }
    }
  }
  @override bool shouldRepaint(_DotGridPainter o) => false;
}
