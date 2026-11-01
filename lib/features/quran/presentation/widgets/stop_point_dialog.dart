import 'package:flutter/material.dart';

class StopPointDialog {
  static Future<bool?> show({
    required BuildContext context,
    required bool isDark,
    required String surahName,
    required int previousAyah,
    required int newAyah,
    required int newResumeAyah,
    bool isJuz = false,
    int? juzNumber,
    String? resumeTargetDescription,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF212121) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: Color(0xFFF59E0B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Replace Stop Point?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            isJuz
                ? 'A stop point is already marked at Ayah $previousAyah in Juz $juzNumber ($surahName).\n\nSetting Ayah $newAyah as the new stop point will delete the previous one and start resuming from ${resumeTargetDescription ?? 'Ayah $newResumeAyah'}.\n\nDo you want to continue?'
                : 'A stop point is already marked at Ayah $previousAyah in $surahName.\n\nSetting Ayah $newAyah as the new stop point will delete the previous one and start resuming from ${resumeTargetDescription ?? 'Ayah $newResumeAyah'}.\n\nDo you want to continue?',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A531D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Set New Stop Point',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
