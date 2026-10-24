import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../quiet_hours/services/quiet_hours_permission_service.dart';

class QuietHoursPermissionsRequiredModal extends StatelessWidget {
  final List<QuietHoursMissingPermission> missingPermissions;
  final VoidCallback? onConfigure;

  const QuietHoursPermissionsRequiredModal({
    super.key,
    required this.missingPermissions,
    this.onConfigure,
  });

  static Future<void> show(
    BuildContext context, {
    List<QuietHoursMissingPermission>? missingPermissions,
    VoidCallback? onConfigure,
  }) async {
    final list = missingPermissions ??
        await QuietHoursPermissionService.getMissingPermissions();
    if (list.isEmpty) return;

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuietHoursPermissionsRequiredModal(
        missingPermissions: list,
        onConfigure: onConfigure,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E2D24) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF2B3F33) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    const primaryGreen = Color(0xFF2A531D);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Drag Handle Indicator
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header Icon & Title
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF9333EA).withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF9333EA).withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.do_not_disturb_on_rounded,
                color: Color(0xFF9333EA),
                size: 28,
              ),
            ),
            const SizedBox(height: 12),

            Text(
              'Permissions Required',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),

            Text(
              'Please enable Do Not Disturb access before using Quiet Hours so Adhkar can automatically silence incoming calls, notifications, and alerts during your scheduled prayer and focus times:',
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                fontSize: 12.5,
                color: subTextColor,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),

            // Scrollable List of Specific Missing Permissions
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: missingPermissions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = missingPermissions[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon in colored circular container
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: item.iconColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.icon,
                            color: item.iconColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title & Explanation
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: GoogleFonts.lexend(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: item.isCritical
                                          ? const Color(0xFFDC2626).withValues(alpha: 0.12)
                                          : const Color(0xFF059669).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.isCritical ? 'Required' : 'Optional',
                                      style: GoogleFonts.lexend(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: item.isCritical
                                            ? const Color(0xFFDC2626)
                                            : const Color(0xFF059669),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.description,
                                style: GoogleFonts.lexend(
                                  fontSize: 11.5,
                                  color: subTextColor,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 18),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onConfigure?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Enable Permissions Below',
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
