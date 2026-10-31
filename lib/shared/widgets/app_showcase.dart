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
    this.targetBorderRadius,
    this.targetPadding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // ignore: deprecated_member_use
    final activeKey = ShowCaseWidget.activeTargetWidget(context);
    final isCurrentShowcased = activeKey == globalKey;

    final isCircle = targetShapeBorder is CircleBorder;
    final effectiveRadius = isCircle
        ? null
        : (targetBorderRadius ?? const BorderRadius.all(Radius.circular(20)));

    Widget effectiveChild = child;
    if (isDark && isCurrentShowcased) {
      effectiveChild = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          child,
          Positioned(
            top: -targetPadding.top,
            left: -targetPadding.left,
            right: -targetPadding.right,
            bottom: -targetPadding.bottom,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: isCircle ? null : effectiveRadius,
                  border: Border.all(color: const Color(0xFF18A74C), width: 2),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Showcase.withWidget(
      key: globalKey,
      targetShapeBorder: targetShapeBorder,
      targetBorderRadius: isCircle ? null : effectiveRadius,
      targetPadding: targetPadding,
      overlayColor: const Color(0xFF0f0f12),
      overlayOpacity: 0.75,
      disposeOnTap: false,
      movingAnimationDuration: Duration.zero,
      disableMovingAnimation: true,
      onTargetClick: () {},
      container: _ShowcaseTooltipCard(
        title: title,
        description: description,
        stepIndex: stepIndex,
        totalSteps: totalSteps,
        isDark: isDark,
      ),
      child: effectiveChild,
    );
  }
}

class _ShowcaseTooltipCard extends StatelessWidget {
  final String title;
  final String description;
  final int stepIndex;
  final int totalSteps;
  final bool isDark;

  const _ShowcaseTooltipCard({
    required this.title,
    required this.description,
    required this.stepIndex,
    required this.totalSteps,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (stepIndex / totalSteps).clamp(0.0, 1.0);
    final primaryGreen = isDark
        ? const Color(0xFF18A74C)
        : const Color(0xFF2A531D);

    return Container(
      width: MediaQuery.of(context).size.width * 0.86,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? const Color(0xFF27272A)
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
                // Header Row: Title + Step Counter Badge
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
                            ? const Color(0xFF27272A)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF86EFAC).withValues(alpha: 0.3)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '$stepIndex of $totalSteps',
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFD97724),
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
                          ? const Color(0xFF27272A)
                          : const Color(0xFFE8F4E5),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? const Color(0xFF18A74C) : primaryGreen,
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
                                ? const Color(0xFF27272A)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF3F3F46)
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
                      label: Text(stepIndex == totalSteps ? 'Got It!' : 'Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF18A74C)
                            : primaryGreen,
                        foregroundColor: isDark
                            ? const Color(0xFF0F0F12)
                            : Colors.white,
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
  }
}
