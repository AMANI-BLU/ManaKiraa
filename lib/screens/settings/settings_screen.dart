import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/language/language_controller.dart';
import '../../core/language/translations.dart';
import '../property/my_properties_screen.dart';
import '../chat/chat_detail_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ThemeController _themeController = ThemeController.instance;
  final LanguageController _languageController = LanguageController.instance;
  bool _notificationsEnabled = true;

  String get _language => _languageController.currentLanguage;

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
                'Select Language',
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
                    await _languageController.setLanguage(lang['code']!);
                    if (mounted) Navigator.pop(context);
                  },
                  leading: Icon(
                    _languageController.value.languageCode == lang['code']
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color:
                        _languageController.value.languageCode == lang['code']
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
                          _languageController.value.languageCode == lang['code']
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

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
                color: Theme.of(context).dividerTheme.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select Theme',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            _themeOption(
              Icons.brightness_auto_rounded,
              'System Default',
              ThemeMode.system,
            ),
            _themeOption(
              Icons.light_mode_rounded,
              'Light Mode',
              ThemeMode.light,
            ),
            _themeOption(Icons.dark_mode_rounded, 'Dark Mode', ThemeMode.dark),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _themeOption(IconData icon, String title, ThemeMode mode) {
    final theme = Theme.of(context);
    final isSelected = _themeController.value == mode;
    return ListTile(
      onTap: () {
        _themeController.setThemeMode(mode);
        Navigator.pop(context);
      },
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? theme.primaryColor : AppColors.textLight,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected
              ? theme.primaryColor
              : theme.textTheme.bodyLarge?.color,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: theme.primaryColor, size: 20)
          : null,
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        content: Text(
          content,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Log Out',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await AuthService.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/welcome',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header
              Text(
                'Settings',
                style: GoogleFonts.nunito(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: theme.textTheme.displayLarge?.color,
                ),
              ),
              const SizedBox(height: 24),
              // Profile Card
              StreamBuilder<AuthState>(
                stream: AuthService.authStateChanges,
                builder: (context, snapshot) {
                  final user =
                      snapshot.data?.session?.user ?? AuthService.currentUser;
                  final metadata = user?.userMetadata;
                  final fullName = metadata?['full_name'] ?? 'User';
                  final email = user?.email ?? '';
                  final avatarUrl = metadata?['avatar_url'];

                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/edit-profile');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? AppColors.primaryGradientDark
                            : AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isDark ? AppColors.accent : AppColors.primary)
                                    .withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              image: avatarUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(avatarUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: avatarUrl == null
                                ? const Icon(
                                    Icons.person_rounded,
                                    size: 30,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName,
                                  style: GoogleFonts.nunito(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              // Preferences
              _sectionLabel('preferences'.tr(context), theme),
              const SizedBox(height: 12),
              _settingsCard([
                _toggleTile(
                  Icons.notifications_none_rounded,
                  'push_notifications'.tr(context),
                  _notificationsEnabled,
                  (v) => setState(() => _notificationsEnabled = v),
                  theme,
                ),
                _divider(theme),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: _themeController,
                  builder: (context, mode, _) {
                    String themeLabel = 'System Default';
                    if (mode == ThemeMode.light) themeLabel = 'Light Mode';
                    if (mode == ThemeMode.dark) themeLabel = 'Dark Mode';

                    return _navTile(
                      Icons.dark_mode_outlined,
                      'app_theme'.tr(context),
                      subtitle: themeLabel,
                      onTap: _showThemePicker,
                      theme: theme,
                    );
                  },
                ),
                _divider(theme),
                _navTile(
                  Icons.language_rounded,
                  'language'.tr(context),
                  subtitle: _language,
                  onTap: _showLanguagePicker,
                  theme: theme,
                ),
                _divider(theme),
                _navTile(
                  Icons.home_work_outlined,
                  'My Properties',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyPropertiesScreen(),
                      ),
                    );
                  },
                  theme: theme,
                ),
              ], theme),
              const SizedBox(height: 24),
              // General
              _sectionLabel('settings'.tr(context), theme),
              const SizedBox(height: 12),
              _settingsCard([
                _navTile(
                  Icons.shield_outlined,
                  'privacy_policy'.tr(context),
                  onTap: () => _showInfoDialog(
                    'privacy_policy'.tr(context),
                    'Your privacy is important to us. Mana Kiraa collects only the information necessary to provide you with the best rental experience.\n\nWe never share your personal data with third parties without your consent. Your data is securely stored and encrypted.',
                  ),
                  theme: theme,
                ),
                _divider(theme),
                _navTile(
                  Icons.description_outlined,
                  'terms_service'.tr(context),
                  onTap: () => _showInfoDialog(
                    'terms_service'.tr(context),
                    'By using Mana Kiraa, you agree to these terms of service.\n\n1. You must be 18 years or older to use this app.\n2. All property listings are subject to availability.',
                  ),
                  theme: theme,
                ),
                _divider(theme),
                _navTile(
                  Icons.help_outline_rounded,
                  'help_support'.tr(context),
                  onTap: () async {
                    try {
                      // Fetch admin user ID (assuming standard email admin@manakiraa.com)
                      final response = await Supabase.instance.client
                          .from('profiles')
                          .select('id, full_name, avatar_url')
                          .eq(
                            'email',
                            'admin@manakiraa.com',
                          ) // Note: email might be in auth.users, but we look in profiles
                          .maybeSingle();

                      String adminId =
                          '00000000-0000-0000-0000-000000000000'; // Default fallback
                      String adminName = 'Support Admin';
                      String adminAvatar = '';

                      if (response != null) {
                        adminId = response['id'];
                        adminName = response['full_name'] ?? 'Support Admin';
                        adminAvatar = response['avatar_url'] ?? '';
                      }

                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              chat: {
                                'name': adminName,
                                'avatar': adminAvatar,
                                'isOnline': true,
                                'receiverId': adminId,
                              },
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      _showInfoDialog(
                        'help_support'.tr(context),
                        'Need help? We\'re here for you!\n\n📧 Email: support@manakiraa.com\n📞 Phone: +251 9876 543 210',
                      );
                    }
                  },
                  theme: theme,
                ),
                _divider(theme),
                _navTile(
                  Icons.info_outline_rounded,
                  'about'.tr(context),
                  onTap: () => _showInfoDialog(
                    'about'.tr(context),
                    'Mana Kiraa v1.1.0\n\nYour trusted house rental companion in Ethiopia. Created by Amanuel Solomon.\n\nBuilt with ❤️ by the Mana Kiraa team.\n\n© 2026 Mana Kiraa. All rights reserved.',
                  ),
                  theme: theme,
                ),
              ], theme),
              const SizedBox(height: 32),
              // Logout Button
              GestureDetector(
                onTap: _showLogoutDialog,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        size: 20,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'logout'.tr(context),
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, ThemeData theme) {
    return Text(
      text,
      style: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: theme.textTheme.titleLarge?.color,
      ),
    );
  }

  Widget _settingsCard(List<Widget> children, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Divider(
        color: theme.dividerTheme.color?.withValues(alpha: 0.5),
        height: 1,
      ),
    );
  }

  Widget _toggleTile(
    IconData icon,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: theme.primaryColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: theme.primaryColor,
            activeTrackColor: theme.primaryColor.withValues(alpha: 0.3),
            inactiveTrackColor: theme.dividerTheme.color,
            inactiveThumbColor: theme.textTheme.bodyMedium?.color?.withValues(
              alpha: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navTile(
    IconData icon,
    String title, {
    String? subtitle,
    VoidCallback? onTap,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: theme.primaryColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
