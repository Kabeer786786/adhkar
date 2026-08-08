import 'package:flutter/material.dart';
import '../../../widgets/app_header_bar.dart';

class ReminderScreen extends StatelessWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppHeaderBar(
        title: 'Reminders',
        showBackButton: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3FAF2),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/reminder.png',
                  width: 64,
                  height: 64,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.notifications_active_rounded,
                    size: 64,
                    color: Color(0xFF2A531D),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Prayer & Adhkar Reminders',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2A531D),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Custom notification reminders feature will be available here soon.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B533E),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
