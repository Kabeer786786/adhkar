import 'package:flutter/material.dart';

class HijriDisclaimerChip extends StatelessWidget {
  final bool isAladhan;
  final EdgeInsetsGeometry? margin;
  final bool compact;

  const HijriDisclaimerChip({
    super.key,
    required this.isAladhan,
    this.margin,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isAladhan) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (compact) {
      return Container(
        margin: margin ?? const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF332B15).withValues(alpha: 0.8)
              : const Color(0xFFFFF8E7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFD97724).withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 13,
              color: Color(0xFFD97724),
            ),
            SizedBox(width: 5),
            Text(
              'Hijri dates may differ by ±1 day to your local sighting',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD97724),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF262014)
            : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD97724).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97724).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFFD97724),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hijri dates may differ by ±1 day to your local dates based on moon sighting in your area.',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB45309),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
