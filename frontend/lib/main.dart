import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/siswa/siswa_main_layout.dart';
import 'screens/dashboard/guru/guru_main_layout.dart';
import 'screens/dashboard/admin/admin_main_layout.dart';
import 'services/auth_service.dart';
import 'services/theme_provider.dart';
import 'config/theme.dart';
import 'widgets/smooth_scroll.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';

import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // Kunci rotasi layar ke potret (Freeze Rotation)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  await initializeDateFormatting('id_ID', null);
  
  // Ubah bagian ini, tambahkan opsi default
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); 

  runApp(const MyPSKDApp()); 
}

class MyPSKDApp extends StatelessWidget {
  const MyPSKDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeProvider(),
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'MyPSKD',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeProvider().themeMode,
          scrollBehavior: AppScrollBehavior(),
          home: const SplashScreen(),
        );
      },
    );
  }
}

// ─── Splash Screen ────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _checkSession();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkSession() async {
    // Beri waktu splash muncul sebentar
    await Future.delayed(const Duration(milliseconds: 1800));

    final token    = await AuthService.getToken();
    final userData = await AuthService.getUserData();

    if (!mounted) return;

    if (token != null && userData != null) {
      final role = userData['role'] ?? '';
      if (role == 'Admin') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => AdminMainLayout(token: token)));
      } else if (role == 'Guru') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => GuruMainLayout(userData: userData, token: token)));
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => SiswaMainLayout(userData: userData, token: token)));
      }
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryBg = isDark ? const Color(0xFF0F1420) : const Color(0xFFF4FAFF);
    final gridColor = isDark ? const Color(0xFF414944) : const Color(0xFFC1C8C2);

    return Scaffold(
      backgroundColor: primaryBg,
      body: Stack(
        children: [
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Asymmetric Bento-style container for the icon
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF161B27) : const Color(0xFFB7E5CD),
                      border: Border.all(
                        color: isDark ? const Color(0xFF414944) : const Color(0xFF717974),
                        width: 1,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3D6754).withAlpha(
                            (40 + 20 * _pulseCtrl.value).round(),
                          ),
                          blurRadius: 15 + 10 * _pulseCtrl.value,
                          spreadRadius: 2 * _pulseCtrl.value,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.school_outlined,
                      size: 48,
                      color: isDark ? Colors.white : const Color(0xFF3D6754),
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms).scale(
                      begin: const Offset(0.7, 0.7),
                      curve: Curves.elasticOut,
                      duration: 1000.ms,
                    ),
                const SizedBox(height: 36),

                // App name
                Text(
                  'MyPSKD',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                    color: isDark ? Colors.white : const Color(0xFF3D6754),
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.2),

                const SizedBox(height: 8),

                Text(
                  'Belajar Pintar, Kapan saja,\nDimana Saja',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white70 : const Color(0xFF414944),
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 450.ms),

                const SizedBox(height: 80),

                // Loading Indicator
                Column(
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3D6754)),
                        backgroundColor: gridColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'MEMUAT SISTEM',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        color: isDark ? Colors.white70 : const Color(0xFF717974),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 600.ms),
              ],
            ),
          ),

          // Decorative Progress Blueprint Line at the very bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              color: isDark ? const Color(0xFF1C2230) : const Color(0xFFDBF1FF),
              alignment: Alignment.centerLeft,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1800),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return FractionallySizedBox(
                    widthFactor: value,
                    child: Container(color: const Color(0xFF3D6754)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
