import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../core/services/showcase_service.dart';

class AppShowcase extends StatelessWidget {
  final GlobalKey globalKey;
  final String title;
  final String description;
  final Widget child;
  final int stepIndex;
  final int totalSteps;
  final ShapeBorder targetShapeBorder;
  final BorderRadius? targetBorderRadius;
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
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
    this.targetBorderRadius = const BorderRadius.all(Radius.circular(20)),
    this.targetPadding = const EdgeInsets.all(8), 
  });

  @override
  Widget build(BuildContext context) {
    return Showcase.withWidget(
      key: globalKey,
      targetShapeBorder: targetShapeBorder,
      targetBorderRadius: targetBorderRadius,
      targetPadding: targetPadding,
      overlayColor: const Color(0xFF0F172A),
      overlayOpacity: 0.75,
      disposeOnTap: false,
      onTargetClick: () {},
      container: Builder(
        builder: (context) {
          final progress = (stepIndex / totalSteps).clamp(0.0, 1.0);
          final isDark = Theme.of(context).brightness == Brightness.dark;
          const primaryGreen = Color(0xFF2A531D);

          return Container(
            width: MediaQuery.of(context).size.width * 0.86,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2D24) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2B3F33)
                    : primaryGreen.withValues(alpha: 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: App Logo + Title + Step Counter Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : primaryGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF332A15)
                                  : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '$stepIndex of $totalSteps',
                              style: GoogleFonts.lexend(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFD97724),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Description Text
                      Text(
                        description,
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          height: 1.45,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Step Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          height: 6,
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: isDark
                                ? const Color(0xFF23352B)
                                : const Color(0xFFE8F4E5),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              primaryGreen,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Bottom Action Buttons
                      Row(
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => ShowcaseService.stopShowcase(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 6,
                              ),
                              child: Text(
                                'Skip Tour',
                                style: GoogleFonts.lexend(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white54
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (stepIndex > 1) ...[
                            InkWell(
                              onTap: () => ShowcaseView.get().previous(),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF23352B)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white12
                                        : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.arrow_back_rounded,
                                      size: 14,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF334155),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Back',
                                      style: GoogleFonts.lexend(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF334155),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          ElevatedButton.icon(
                            onPressed: () {
                              if (stepIndex >= totalSteps) {
                                ShowcaseService.stopShowcase(context);
                              } else {
                                ShowcaseView.get().next();
                              }
                            },
                            icon: Icon(
                              stepIndex == totalSteps
                                  ? Icons.check_circle_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 15,
                            ),
                            label: Text(
                              stepIndex == totalSteps ? 'Got It!' : 'Next',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 9,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              textStyle: GoogleFonts.lexend(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
