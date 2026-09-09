import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/providers/user_profile_provider.dart';
import '../../../widgets/app_header_bar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  void _showEditNameDialog(String currentName) {
    final controller = TextEditingController(text: currentName);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryGreen = Color(0xFF2A531D); 

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1B2821) : Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_outlined, color: primaryGreen, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Update Name',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.lexend(
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Enter your full name',
              hintStyle: GoogleFonts.lexend(fontSize: 13, color: Colors.grey),
              filled: true,
              fillColor: isDark ? const Color(0xFF23352B) : const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryGreen, width: 1.5),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.only(right: 16, bottom: 16, left: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.lexend(
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  await ref
                      .read(userProfileProvider.notifier)
                      .updateName(newName);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Name updated successfully!',
                          style: GoogleFonts.lexend(fontSize: 13),
                        ),
                        backgroundColor: primaryGreen,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Save Name',
                style: GoogleFonts.lexend(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final initial = profile.name.isNotEmpty
        ? profile.name[0].toUpperCase()
        : (profile.email.isNotEmpty ? profile.email[0].toUpperCase() : 'U');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF121B16) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E2D24) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF2B3F33) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    const primaryGreen = Color(0xFF2A531D);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: const AppHeaderBar(
        title: 'MY PROFILE',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: [
              // 1. Profile Avatar Card Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B3D14), Color(0xFF2A531D), Color(0xFF3B6B2B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Circle Avatar
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: GoogleFonts.outfit(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Name Display & Edit Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            profile.name.isNotEmpty ? profile.name : 'Guest User',
                            style: GoogleFonts.outfit(
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _showEditNameDialog(profile.name),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Registered badge
                    if (profile.isRegistered)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              size: 13,
                              color: Color(0xFFA3E635),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Registered Member',
                              style: GoogleFonts.lexend(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Profile Details Info Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cardBorder, width: 1),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Account Details',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showEditNameDialog(profile.name),
                          icon: const Icon(Icons.edit_outlined, size: 14, color: primaryGreen),
                          label: Text(
                            'Edit Name',
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    _buildInfoTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Full Name',
                      subtitle: profile.name.isNotEmpty ? profile.name : 'Not set',
                      textColor: textColor,
                      subTextColor: subTextColor,
                      isDark: isDark,
                    ),
                    const Divider(height: 18, color: Color(0xFFF0F4F0)),

                    _buildInfoTile(
                      icon: Icons.email_outlined,
                      title: 'Email Address',
                      subtitle: profile.email.isNotEmpty ? profile.email : 'Not set',
                      textColor: textColor,
                      subTextColor: subTextColor,
                      isDark: isDark,
                    ),
                    const Divider(height: 18, color: Color(0xFFF0F4F0)),

                    _buildInfoTile(
                      icon: Icons.phone_outlined,
                      title: 'Phone Number',
                      subtitle: profile.phone.isNotEmpty ? profile.phone : 'Not set',
                      textColor: textColor,
                      subTextColor: subTextColor,
                      isDark: isDark,
                    ),
                    const Divider(height: 18, color: Color(0xFFF0F4F0)),

                    _buildInfoTile(
                      icon: Icons.location_on_outlined,
                      title: 'Location',
                      subtitle: profile.location.isNotEmpty ? profile.location : 'Not set',
                      textColor: textColor,
                      subTextColor: subTextColor,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subTextColor,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF23352B)
                : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF2A531D), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.lexend(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: subTextColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
