import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingSlide {
  final String title;
  final String description;
  final String imagePath;

  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = const [
    OnboardingSlide(
      title: 'Strengthen Your Connection With Allah',
      description:
          'All the tools you need to grow in faith, stay consistent, and lead a better life.',
      imagePath: 'assets/images/onboarding_mosque_moon.png',
    ),
    OnboardingSlide(
      title: 'Accurate Prayer Times & Qibla Finder',
      description:
          'Never miss a Salah with location-based Adhan notifications and compass direction.',
      imagePath: 'assets/images/onboarding_qibla_prayer.png',
    ),
    OnboardingSlide(
      title: 'Daily Adhkar, Quran & Digital Tasbeeh',
      description:
          'Recite morning & evening Adhkar, read the Holy Quran, and track your daily dhikr effortlessly.',
      imagePath: 'assets/images/onboarding_quran_tasbeeh.png',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Brightness.light, // Light status bar icons for Android
        statusBarBrightness:
            Brightness.dark, // Light status bar text/icons for iOS
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // 1. Synchronized Top Artwork PageView
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size.height * 0.58,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Container(
                    color: const Color(0xFF1B3D14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          slide.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF2A531D),
                                    Color(0xFF1B3D14),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.mosque_rounded,
                                  size: 100,
                                  color: Colors.white24,
                                ),
                              ),
                            );
                          },
                        ),

                        // Smooth gradient overlay blending pure artwork into white bottom sheet
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 100,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withValues(alpha: 0.6),
                                  Colors.white,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Top Skip Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 20,
              child: TextButton(
                onPressed: () => context.go('/auth'),
                child: Text(
                  'Skip',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ),

            // 2. Bottom Sheet Container with Logo, Subtitle, Headline & Action
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: size.height * 0.46,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 22,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF2A531D).withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // App Brand Header with stars on both sides (no background) and centered description
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: Color(0xFF2A531D),
                              size: 22,
                            ),
                            const SizedBox(width: 13),
                            Text(
                              'Adhkar',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1F2937),
                                letterSpacing: -0.3,
                              ),
                            ),
                            // const SizedBox(width: 6),
                            // Container(
                            //   padding: const EdgeInsets.symmetric(
                            //     horizontal: 7,
                            //     vertical: 2,
                            //   ),
                            //   decoration: BoxDecoration(
                            //     color: const Color(
                            //       0xFF2A531D,
                            //     ).withValues(alpha: 0.12),
                            //     borderRadius: BorderRadius.circular(8),
                            //   ),
                            //   child: Text(
                            //     'ISLAMIC',
                            //     style: GoogleFonts.outfit(
                            //       fontSize: 10.5,
                            //       fontWeight: FontWeight.w800,
                            //       color: const Color(0xFF2A531D),
                            //       letterSpacing: 0.8,
                            //     ),
                            //   ),
                            // ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: Color(0xFF2A531D),
                              size: 22,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your Daily Spiritual Companion',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7280),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Headline & Description
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                                _slides[_currentPage].title,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1F2937),
                                  height: 1.35,
                                ),
                              )
                              .animate(key: ValueKey(_currentPage))
                              .fade(duration: 300.ms)
                              .slideY(begin: 0.08, end: 0, duration: 300.ms),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child:
                                Text(
                                      _slides[_currentPage].description,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(
                                        fontSize: 15.5,
                                        color: const Color(0xFF6B7280),
                                        height: 1.45,
                                      ),
                                    )
                                    .animate(key: ValueKey(_currentPage))
                                    .fade(delay: 80.ms, duration: 300.ms),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 3-Dot Page Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? const Color(0xFF2A531D)
                                : const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Action Button ("Next" / "Get Started")
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _onNextPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A531D),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: const Color(
                            0xFF2A531D,
                          ).withValues(alpha: 0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          _currentPage == _slides.length - 1
                              ? 'Get Started'
                              : 'Next',
                          style: GoogleFonts.outfit(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
