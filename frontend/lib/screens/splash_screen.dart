import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../main.dart';

/// Animated splash / intro screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _slideUp;
  late final Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));

    _fadeIn  = CurvedAnimation(parent: _ctrl, curve: const Interval(0.2, 0.8));
    _slideUp = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.2, 0.8, curve: Curves.easeOut)),
    );
    _rotate  = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    _ctrl.forward().then((_) async {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pushReplacementNamed(context, '/simulator');
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rotating cube icon
              Transform.rotate(
                angle: _rotate.value,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.accent, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.accent.withOpacity(0.08),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.3),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.hub_rounded,
                    color: AppColors.accent, size: 36),
                ),
              ),
              const SizedBox(height: 40),
              // Title
              Opacity(
                opacity: _fadeIn.value,
                child: Transform.translate(
                  offset: Offset(0, _slideUp.value),
                  child: Column(
                    children: [
                      Text('3D LOGIC GATE',
                        style: Theme.of(context).textTheme.displayLarge),
                      const SizedBox(height: 4),
                      Text('SIMULATOR',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: AppColors.accentGreen,
                        )),
                      const SizedBox(height: 16),
                      Text('Εκπαιδευτικό εργαλείο  •  Λύκειο  •  Πληροφορική',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textDim, letterSpacing: 2,
                        )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 60),
              // Progress bar
              Opacity(
                opacity: _fadeIn.value,
                child: SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    value: _ctrl.value,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                    minHeight: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
