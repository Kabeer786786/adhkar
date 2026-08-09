import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/providers/user_profile_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkNextScreen();
  }

  void _checkNextScreen() async {
    // Read SharedPreferences directly to ensure instant local state evaluation
    final prefs = await SharedPreferences.getInstance();
    final isRegCompletedPref = prefs.getBool('registration_completed') ?? false;

    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    final userProfile = ref.read(userProfileProvider);
    final isRegistered = isRegCompletedPref || userProfile.registrationCompleted;

    if (!isRegistered) {
      context.go('/onboarding');
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF3), // Light cream green background
      body: Stack(
        children: [
          // Subtle Decorative Islamic Pattern Background Tint
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.95,
                  colors: [
                    Colors.white,
                    Color(0xFFEBF5EA),
                    Color(0xFFF4FAF3),
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo cut into a round circle
                Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.auto_awesome_rounded,
                          size: 50,
                          color: Color(0xFF2A531D),
                        );
                      },
                    ),
                  ),
                )
                    .animate()
                    .fade(duration: 800.ms)
                    .scale(delay: 200.ms, duration: 800.ms, curve: Curves.easeOutBack),

                const SizedBox(height: 24),

                // App Title "Adhkar"
                Text(
                  'Adhkar',
                  style: GoogleFonts.outfit(
                    fontSize: 38,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2A531D),
                    letterSpacing: -0.5,
                  ),
                )
                    .animate()
                    .fade(delay: 400.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOutQuad),

                const SizedBox(height: 6),

                // Subtitle Animation "Your Daily Islamic Companion"
                Text(
                  'Your Daily Islamic\nCompanion',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF527947),
                    letterSpacing: 0.3,
                  ),
                )
                    .animate()
                    .fade(delay: 700.ms, duration: 700.ms)
                    .slideY(begin: 0.4, end: 0, curve: Curves.easeOutQuad),

                const SizedBox(height: 48),

                // Progress Indicator
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A531D)),
                  ),
                )
                    .animate()
                    .fade(delay: 1100.ms, duration: 500.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
