import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/simulator_screen.dart';
import 'screens/splash_screen.dart';
import 'services/websocket_service.dart';

// ─────────────────────────────────────────────
//  App colours  (neon-on-dark theme)
// ─────────────────────────────────────────────
class AppColors {
  static const background   = Color(0xFF050A14);   // deep space blue-black
  static const surface      = Color(0xFF0D1A2D);   // dark navy panel
  static const surfaceLight = Color(0xFF122033);
  static const accent       = Color(0xFF00E5FF);   // cyan
  static const accentGreen  = Color(0xFF69FF47);   // signal-high green
  static const accentRed    = Color(0xFFFF4081);   // signal-low red
  static const accentAmber  = Color(0xFFFFD740);   // XOR yellow
  static const onSurface    = Color(0xFFE0F7FA);
  static const textDim      = Color(0xFF4A7A9B);

  // Gate colour map – mirrors the Go backend gateColor()
  static const gateColors = <String, Color>{
    'AND':  Color(0xFF00E5FF),
    'OR':   Color(0xFF69FF47),
    'NOT':  Color(0xFFFF4081),
    'NAND': Color(0xFFFF6D00),
    'NOR':  Color(0xFFAA00FF),
    'XOR':  Color(0xFFFFD740),
  };
}

// ─────────────────────────────────────────────
//  Entry point
// ─────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force landscape on tablets / web; portrait also works fine.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: AppColors.background,
  ));

  runApp(
    const ProviderScope(
      child: LogicGateApp(),
    ),
  );
}

// ─────────────────────────────────────────────
//  Root widget
// ─────────────────────────────────────────────
class LogicGateApp extends StatelessWidget {
  const LogicGateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '3D Logic Gate Simulator',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/simulator': (_) => const SimulatorScreen(),
      },
    );
  }

  ThemeData _buildTheme() {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary:   AppColors.accent,
        secondary: AppColors.accentGreen,
        surface:   AppColors.surface,
        error:     AppColors.accentRed,
      ),
      textTheme: GoogleFonts.spaceMonoTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.spaceMono(
          fontSize: 32, fontWeight: FontWeight.bold,
          color: AppColors.accent, letterSpacing: 2,
        ),
        titleMedium: GoogleFonts.spaceMono(
          fontSize: 14, color: AppColors.onSurface, letterSpacing: 1.2,
        ),
        bodySmall: GoogleFonts.spaceMono(
          fontSize: 11, color: AppColors.textDim,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.accent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.spaceMono(
          fontSize: 16, fontWeight: FontWeight.bold,
          color: AppColors.accent, letterSpacing: 3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent.withOpacity(0.15),
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent, width: 1),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          textStyle: GoogleFonts.spaceMono(
            fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2,
          ),
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          side: BorderSide(color: AppColors.surfaceLight, width: 1),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.accent, size: 20),
      dividerColor: AppColors.surfaceLight,
    );
  }
}
