import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'reset_password_screen.dart';
import '../../services/forgot_password_service.dart';
// --- Color Palette from Neo-Brutalist Theme ---
const Color _bgColor = Color(0xFFF4FAFF);
const Color _onSurface = Color(0xFF001E2B);
const Color _onSurfaceVariant = Color(0xFF414944);
const Color _surfaceContainerLow = Color(0xFFE8F6FF);
const Color _primaryColor = Color(0xFF3D6754);
const Color _primaryFixedDim = Color(0xFFA3D1B9);

class OtpVerifyScreen extends StatefulWidget {
  final String email;
  const OtpVerifyScreen({super.key, required this.email});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  int _secondsRemaining = 600; // 10 menit
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 600);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining <= 0) {
        t.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  String get _timerText {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    final code = _otpCode;
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Masukkan 6 digit kode verifikasi', style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await ForgotPasswordService.verifyOtp(widget.email, code);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            email: widget.email,
            otpCode: code,
          ),
        ),
      );
    } else {
      // Shake effect: clear all fields
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'], style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);
    final result = await ForgotPasswordService.sendOtp(widget.email);
    if (!mounted) return;
    setState(() => _isResending = false);

    if (result['success'] == true) {
      _startTimer();
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kode baru telah dikirim ke email kamu', style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: _primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'], style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: Theme.of(context).colorScheme.error,
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
              'Cek Email Kamu',
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
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 16,
              color: _onSurfaceVariant,
            ),
            children: [
              const TextSpan(text: 'Kode 6 digit telah dikirim ke\n'),
              TextSpan(
                text: widget.email,
                style: GoogleFonts.inter(
                  color: _primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // OTP Input boxes
          Text('VERIFICATION CODE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _onSurfaceVariant, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) => _buildOtpBox(index)),
          ),
          const SizedBox(height: 24),

          // Timer
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _secondsRemaining > 0
                ? Container(
                    key: const ValueKey('timer'),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _surfaceContainerLow,
                      border: Border.all(color: _onSurface, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer_outlined, size: 18, color: _onSurface),
                        const SizedBox(width: 8),
                        Text(
                          'Kode kedaluwarsa dalam $_timerText',
                          style: GoogleFonts.inter(fontSize: 14, color: _onSurface, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                : Container(
                    key: const ValueKey('expired'),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error.withAlpha(20),
                      border: Border.all(color: Theme.of(context).colorScheme.error, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer_off_outlined, size: 18, color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 8),
                        Text(
                          'Kode sudah kedaluwarsa',
                          style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 32),

          // Verify button
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
                onTap: (_isLoading || _secondsRemaining <= 0) ? null : _verifyOtp,
                borderRadius: BorderRadius.circular(8),
                child: Center(
                  child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Verifikasi Kode', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                          const SizedBox(width: 8),
                          const Icon(Icons.verified_rounded, size: 24, color: Colors.white),
                        ],
                      ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Resend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Tidak menerima kode? ',
                style: GoogleFonts.inter(color: _onSurfaceVariant, fontSize: 14),
              ),
              GestureDetector(
                onTap: _isResending ? null : _resendOtp,
                child: _isResending
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: _primaryColor, strokeWidth: 2))
                    : Text(
                        'Kirim Ulang',
                        style: GoogleFonts.inter(color: _primaryColor, fontWeight: FontWeight.w700, fontSize: 14, decoration: TextDecoration.underline),
                      ),
              ),
            ],
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
              widthFactor: 0.66,
              child: Container(color: _primaryFixedDim),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 52,
      height: 64,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: _onSurface),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: _surfaceContainerLow,
          contentPadding: EdgeInsets.zero,
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
            borderSide: const BorderSide(color: _primaryColor, width: 2.5),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          // Auto-verify when all filled
          if (_otpCode.length == 6) {
            _verifyOtp();
          }
        },
      ),
    );
  }
}
