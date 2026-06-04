import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import '../../services/forgot_password_service.dart';
import '../../config/theme.dart';

// --- Color Palette from Neo-Brutalist Theme ---
const Color _bgColor = Color(0xFFF4FAFF);
const Color _onSurface = Color(0xFF001E2B);
const Color _onSurfaceVariant = Color(0xFF414944);
const Color _surfaceContainerLow = Color(0xFFE8F6FF);
const Color _primaryColor = Color(0xFF3D6754);
const Color _primaryFixedDim = Color(0xFFA3D1B9);

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otpCode;
  const ResetPasswordScreen(
      {super.key, required this.email, required this.otpCode});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;

  @override
  void dispose() {
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
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text('Kata sandi berhasil diperbarui! Silakan masuk.', style: GoogleFonts.inter(color: Colors.white)),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'], style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: AppTheme.rose,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 900;
          
          final formContent = Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildBentoCard(),
                  ],
                ),
              ),
            ),
          );

          if (!isDesktop) return formContent;

          return Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  color: _primaryColor,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: _onSurface, width: 2),
                              boxShadow: const [BoxShadow(color: _onSurface, offset: Offset(6, 6))],
                            ),
                            child: const Icon(Icons.school_rounded, size: 80, color: _primaryColor),
                          ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8)),
                          const SizedBox(height: 48),
                          Text(
                            'MyPSKD',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1.5,
                            ),
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                          const SizedBox(height: 16),
                          Text(
                            'Sekolah yang hebat,\ngenerasi yang kuat.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: _surfaceContainerLow,
                              height: 1.3,
                            ),
                          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  color: _bgColor,
                  child: formContent,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _surfaceContainerLow,
                  border: Border.all(color: _onSurface, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 20, color: _onSurface),
              ),
            ),
            const Spacer(),
            Text(
              'Reset Password',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: _onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const Spacer(),
            const SizedBox(width: 36), // To balance the back button
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Buat kata sandi baru untuk akunmu.',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: _onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1);
  }

  Widget _buildBentoCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _onSurface, width: 1.5),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
          topRight: Radius.circular(8),
          bottomLeft: Radius.circular(8),
        ),
        boxShadow: const [
          BoxShadow(
            color: _onSurface,
            offset: Offset(4, 4),
          )
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email (Read Only)
            Text('EMAIL ADDRESS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _onSurfaceVariant, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: _surfaceContainerLow,
                border: Border.all(color: _onSurface, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mail_outline_rounded, color: _onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.email, 
                      style: GoogleFonts.inter(color: _onSurface, fontSize: 16, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Password Baru
            Text('NEW PASSWORD', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _onSurfaceVariant, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _passwordController,
              hint: 'Minimal 6 karakter',
              icon: _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              obscureText: !_isPasswordVisible,
              onIconTap: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Kata sandi tidak boleh kosong';
                if (v.length < 6) return 'Kata sandi minimal 6 karakter';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Konfirmasi Password Baru
            Text('CONFIRM PASSWORD', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _onSurfaceVariant, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _confirmController,
              hint: 'Ulangi kata sandi',
              icon: _isConfirmVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              obscureText: !_isConfirmVisible,
              onIconTap: () => setState(() => _isConfirmVisible = !_isConfirmVisible),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Konfirmasi kata sandi tidak boleh kosong';
                if (v != _passwordController.text) return 'Kata sandi tidak cocok';
                return null;
              },
            ),
            const SizedBox(height: 32),
            
            // Submit Action
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: _primaryColor,
                border: Border.all(color: _onSurface, width: 1.5),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: _onSurface, offset: Offset(2, 2))
                ]
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading ? null : _resetPassword,
                  borderRadius: BorderRadius.circular(8),
                  child: Center(
                    child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Simpan Password Baru', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                            const SizedBox(width: 8),
                            const Icon(Icons.check_circle_outline_rounded, size: 24, color: Colors.white),
                          ],
                        ),
                  ),
                ),
              ),
            ),
            
            // Decorative status indicator
            const SizedBox(height: 24),
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _surfaceContainerLow,
                border: Border.all(color: _onSurface, width: 1),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 1.0,
                child: Container(color: _primaryFixedDim),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
    VoidCallback? onIconTap,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.inter(color: _onSurface, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: _onSurfaceVariant.withAlpha(150), fontSize: 16),
        suffixIcon: IconButton(
          icon: Icon(icon, color: _onSurfaceVariant),
          onPressed: onIconTap ?? () {},
        ),
        filled: true,
        fillColor: _surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _onSurface, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _onSurface, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
        ),
        errorStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
      ),
    );
  }
}
