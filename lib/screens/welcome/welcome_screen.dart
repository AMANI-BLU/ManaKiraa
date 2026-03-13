import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/language/translations.dart';
import '../../core/language/language_controller.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerTheme.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'select_language'.tr(context),
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
              for (final lang in [
                {'name': 'English', 'code': 'en'},
                {'name': 'Afan Oromo', 'code': 'om'},
                {'name': 'Amharic', 'code': 'am'},
              ])
                ListTile(
                  onTap: () async {
                    await LanguageController.instance.setLanguage(
                      lang['code']!,
                    );
                    if (mounted) {
                      setState(() {});
                      Navigator.pop(context);
                    }
                  },
                  leading: Icon(
                    LanguageController.instance.value.languageCode ==
                            lang['code']
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color:
                        LanguageController.instance.value.languageCode ==
                            lang['code']
                        ? theme.primaryColor
                        : theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.5,
                          ),
                  ),
                  title: Text(
                    lang['name']!,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight:
                          LanguageController.instance.value.languageCode ==
                              lang['code']
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Hero Image Section
          Expanded(
            flex: 6,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.home_work_rounded,
                          size: 80,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ),
                // Gradient overlay
                Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                    ),
                    gradient: AppColors.welcomeGradient,
                  ),
                ),
                // Language Picker (Top Right)
                Positioned(
                  top: 50,
                  right: 20,
                  child: TextButton.icon(
                    onPressed: _showLanguagePicker,
                    icon: const Icon(
                      Icons.language_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: Text(
                      LanguageController.instance.currentLanguage,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
                // Logo and text overlay
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 40,
                  child: Column(
                    children: [
                      // Logo Icon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.home_work_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // App Name
                      Text(
                        'MANA KIRAA',
                        style: GoogleFonts.nunito(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'dream_house'.tr(context),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Section
          Expanded(
            flex: 4,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        'welcome'.tr(context),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(
                            context,
                          ).textTheme.displayLarge?.color,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'welcome_primary_tagline'.tr(context),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'welcome_secondary_tagline'.tr(context),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Login Button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        child: Text('login'.tr(context)),
                      ),
                      const SizedBox(height: 14),
                      // Sign Up Button
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/signup');
                        },
                        child: Text('signup'.tr(context)),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
