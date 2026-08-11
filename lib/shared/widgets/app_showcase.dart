import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:showcaseview/showcaseview.dart';

class AppShowcase extends StatelessWidget {
  final GlobalKey globalKey;
  final String title;
  final String description;
  final Widget child;
  final int stepIndex;
  final int totalSteps;
  final ShapeBorder targetShapeBorder;
  final EdgeInsets targetPadding;

  const AppShowcase({
    super.key,
    required this.globalKey,
    required this.title,
    required this.description,
    required this.child,
    required this.stepIndex,
    required this.totalSteps,
    this.targetShapeBorder = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    this.targetPadding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    return Showcase.withWidget(
      key: globalKey,
      targetShapeBorder: targetShapeBorder,
      targetPadding: targetPadding,
      overlayColor: const Color(0xFF0F172A),
      overlayOpacity: 0.70,
      disposeOnTap: false, // Prevent tooltip card taps from automatically advancing
      onTargetClick: () {}, // Required whenever disposeOnTap is specified
      container: Builder(
        builder: (context) {
          final progress = (stepIndex / totalSteps).clamp(0.0, 1.0);
          return Container(
            width: MediaQuery.of(context).size.width * 0.84,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white, // Light themed background card
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color( 
                  0xFF2A531D,
                ).withValues(alpha: 0.2), // Light green border
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Title
                Text(
                  title,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 20,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2A531D), // Rich Islamic Green
                  ),
                ),

                const SizedBox(height: 12),

                // Description Text
                Text(
                  description,
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    height: 1.45,
                    color: const Color(0xFF4A5568),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                // 1/6 step text right above the ending of progress bar
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$stepIndex/$totalSteps',
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFD97724), // Gold accent
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Beautiful Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 6,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: const Color(
                        0xFFE8F4E5,
                      ), // Soft green track
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFD97724), // Gold fill
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Footer Actions: Skip & [Previous Arrow + Next/Got It]
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        ShowcaseView.get().dismiss();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        child: Text(
                          'Skip Tour',
                          style: GoogleFonts.lexend(
                            fontSize: 12.5,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF718096),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (stepIndex > 1) ...[
                          InkWell(
                            onTap: () {
                              ShowcaseView.get().previous();
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F4E5),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(
                                    0xFF2A531D,
                                  ).withValues(alpha: 0.25),
                                  width: 1.2,
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                size: 18,
                                color: Color(0xFF2A531D),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        ElevatedButton(
                          onPressed: () {
                            ShowcaseView.get().next();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A531D),
                            foregroundColor: Colors.white,
                            elevation: 1,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 9,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                stepIndex == totalSteps ? 'Got it!' : 'Next',
                                style: GoogleFonts.lexend(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                stepIndex == totalSteps
                                    ? Icons.check_circle_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 15,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      child: child,
    );

  }
}
