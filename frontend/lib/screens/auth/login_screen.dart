import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../dashboard/siswa/siswa_main_layout.dart';
import '../dashboard/admin/admin_main_layout.dart';
import '../dashboard/guru/guru_main_layout.dart';
import 'forgot_password_screen.dart';

// --- Color Palette from HTML ---
const Color _bgColor = Color(0xFFF4FAFF);
const Color _onSurface = Color(0xFF001E2B);
const Color _onSurfaceVariant = Color(0xFF414944);
const Color _surfaceContainerLow = Color(0xFFE8F6FF);
const Color _primaryColor = Color(0xFF3D6754);
const Color _primaryFixedDim = Color(0xFFA3D1B9);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
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
    return Scaffold(
      backgroundColor: _bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildBentoCard(),
                const SizedBox(height: 32),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Masuk ke Akun',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: _onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Masukkan email dan kata sandi kamu',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: _onSurfaceVariant,
          ),
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
            // Email Field
            Text('EMAIL ADDRESS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _onSurfaceVariant, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _emailCtrl,
              hint: 'nama@pskd.sch.id',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || v.isEmpty) ? 'Email tidak boleh kosong' : null,
            ),
            const SizedBox(height: 24),
            
            // Password Field
            Text('PASSWORD', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _onSurfaceVariant, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _passwordCtrl,
              hint: '••••••••',
              icon: _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              obscureText: !_isPasswordVisible,
              onIconTap: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              validator: (v) => (v == null || v.isEmpty) ? 'Password tidak boleh kosong' : null,
            ),
            
            // Lupa Password (dipindah ke bawah kolom password)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Lupa Password?', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: _primaryColor)),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Primary Action
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
                  onTap: _isLoading ? null : _login,
                  borderRadius: BorderRadius.circular(8),
                  child: Center(
                    child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Masuk', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 24, color: Colors.white),
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
                widthFactor: 0.33,
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
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    VoidCallback? onIconTap,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
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
      ),
    );
  }

  Widget _buildFooter() {
    return Text(
      'MyPSKD\nSekolah yang hebat, generasi yang kuat',
      style: GoogleFonts.inter(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
      textAlign: TextAlign.center,
    ).animate().fadeIn(delay: 400.ms);
  }
}