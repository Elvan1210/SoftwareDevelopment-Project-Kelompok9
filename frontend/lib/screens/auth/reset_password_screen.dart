import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'login_screen.dart';
import '../../services/forgot_password_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otpCode;
  const ResetPasswordScreen(
      {super.key, required this.email, required this.otpCode});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;

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
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    final result = await ForgotPasswordService.resetPassword(
      widget.email,
      widget.otpCode,
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // Navigasi ke login dengan pesan sukses
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      // Tampilkan SnackBar setelah build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('Kata sandi berhasil diperbarui! Silakan masuk.'),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
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
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0D0D1A) : const Color(0xFFF5F5FF),
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
                      // Back + Logo
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Color(0xFF6366F1)
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 16,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildLogo(),
                        ],
                      ).animate().fadeIn(duration: 500.ms),
                      const SizedBox(height: 48),

                      // Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF6366F1)
                                  .withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_person_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 150.ms)
                          .scale(begin: const Offset(0.8, 0.8)),
                      const SizedBox(height: 24),

                      // Title
                      const Text(
                        'Buat Kata Sandi Baru',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0A1628),
                          letterSpacing: -0.8,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 10),
                      Text(
                        'Kata sandi baru kamu harus berbeda dari kata sandi yang pernah digunakan sebelumnya.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black.withValues(alpha: 0.5),
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 250.ms),
                      const SizedBox(height: 40),

                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Email chip (read-only info)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Color(0xFF6366F1)
                                    .withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Color(0xFF6366F1)
                                      .withValues(alpha: 0.12),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.email_outlined,
                                      size: 14,
                                      color: Color(0xFF6366F1)
                                          .withValues(alpha: 0.7)),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.email,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6366F1),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: 280.ms),
                            const SizedBox(height: 24),

                            _buildLabel('Kata Sandi Baru'),
                            const SizedBox(height: 8),
                            _buildPasswordField(
                              controller: _passwordController,
                              hint: 'Minimal 6 karakter',
                              isVisible: _isPasswordVisible,
                              onToggle: () => setState(
                                  () => _isPasswordVisible = !_isPasswordVisible),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Kata sandi tidak boleh kosong';
                                }
                                if (v.length < 6) {
                                  return 'Kata sandi minimal 6 karakter';
                                }
                                return null;
                              },
                            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                            const SizedBox(height: 20),

                            _buildLabel('Konfirmasi Kata Sandi'),
                            const SizedBox(height: 8),
                            _buildPasswordField(
                              controller: _confirmController,
                              hint: 'Ulangi kata sandi baru',
                              isVisible: _isConfirmVisible,
                              onToggle: () => setState(() =>
                                  _isConfirmVisible = !_isConfirmVisible),
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _resetPassword(),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Konfirmasi kata sandi tidak boleh kosong';
                                }
                                if (v != _passwordController.text) {
                                  return 'Kata sandi tidak cocok';
                                }
                                return null;
                              },
                            ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),

                            // Password strength hints
                            const SizedBox(height: 16),
                            _buildPasswordHint(
                              icon: Icons.check_circle_outline_rounded,
                              text: 'Minimal 6 karakter',
                              satisfied: _passwordController.text.length >= 6,
                            ).animate().fadeIn(delay: 380.ms),
                            const SizedBox(height: 6),
                            _buildPasswordHint(
                              icon: Icons.check_circle_outline_rounded,
                              text: 'Kata sandi cocok',
                              satisfied: _passwordController.text.isNotEmpty &&
                                  _passwordController.text ==
                                      _confirmController.text,
                            ).animate().fadeIn(delay: 400.ms),
                            const SizedBox(height: 32),

                            // Submit button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading ? null : _resetPassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                  disabledBackgroundColor:
                                      Color(0xFF6366F1)
                                          .withValues(alpha: 0.5),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5))
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.lock_open_rounded,
                                              size: 18),
                                          SizedBox(width: 8),
                                          Text(
                                            'Simpan Kata Sandi Baru',
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.2),
                                          ),
                                        ],
                                      ),
                              ),
                            ).animate().fadeIn(delay: 420.ms).slideY(begin: 0.1),
                          ],
                        ),
                      ),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onSubmitted,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF0A1628),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14,
          color: Colors.black.withValues(alpha: 0.3),
        ),
        prefixIcon: Icon(Icons.lock_outline_rounded,
            size: 18, color: Colors.black.withValues(alpha: 0.35)),
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Icon(
              isVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),
        ),
        suffixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: const Color(0xFF1C1C2E),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        errorStyle: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildPasswordHint(
      {required IconData icon,
      required String text,
      required bool satisfied}) {
    final color = satisfied ? const Color(0xFF10B981) : const Color(0xFF9CA3AF);
    return Row(
      children: [
        Icon(
          satisfied ? Icons.check_circle_rounded : icon,
          size: 15,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6366F1),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child:
              const Icon(Icons.school_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        const Text(
          'MyPSKD',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF6366F1),
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -60,
          child: AnimatedBuilder(
            animation: _floatController,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, 10 * _floatController.value),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFF6366F1).withValues(alpha: 0.07),
                      Color(0xFF6366F1).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          left: -40,
          child: AnimatedBuilder(
            animation: _floatController,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, -8 * _floatController.value),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFF8B5CF6).withValues(alpha: 0.09),
                      Color(0xFF8B5CF6).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
      ],
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF6366F1).withValues(alpha: 0.04)
      ..strokeCap = StrokeCap.round;
    const spacing = 28.0;
    const dotRadius = 1.2;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) => false;
}
