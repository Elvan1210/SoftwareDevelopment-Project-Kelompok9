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

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -150, left: -100,
            child: Container(
              width: 500, height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.indigoPrimary.withAlpha(isDark ? 60 : 35),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -200, right: -80,
            child: Container(
              width: 600, height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.primary.withAlpha(isDark ? 45 : 25),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with pulse glow
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.indigoPrimary, AppTheme.primary],
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.indigoPrimary.withAlpha(
                            (80 + 60 * _pulseCtrl.value).round(),
                          ),
                          blurRadius: 30 + 20 * _pulseCtrl.value,
                          spreadRadius: 4 * _pulseCtrl.value,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 52,
                      color: Colors.white,
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
                  style: GoogleFonts.poppins(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [AppTheme.indigoLight, AppTheme.primaryDark],
                      ).createShader(const Rect.fromLTWH(0, 0, 200, 50)),
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.2),

                const SizedBox(height: 8),

                Text(
                  'Academic Management Platform',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppTheme.textMutedDk : AppTheme.textMutedLt,
                    letterSpacing: 1.5,
                  ),
                ).animate().fadeIn(delay: 450.ms),

                const SizedBox(height: 60),

                // Loading dots
                _LoadingDots().animate().fadeIn(delay: 600.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(3, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
      return ctrl;
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrls[i],
          builder: (_, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8 + 8 * _ctrls[i].value,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.indigoPrimary.withAlpha((150 + 105 * _ctrls[i].value).round()),
                  AppTheme.primary.withAlpha((100 + 80 * _ctrls[i].value).round()),
                ],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
