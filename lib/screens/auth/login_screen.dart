import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/language/translations.dart';
import '../../core/language/language_controller.dart';
import '../../core/supabase/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'email_required'.tr(context);
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'valid_email'.tr(context);
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'password_required'.tr(context);
    }
    if (value.length < 6) {
      return 'password_length'.tr(context);
    }
    return null;
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.signInWithGoogle();
      if (mounted) {
        final user = AuthService.currentUser;
        if (user != null) {
          final isActive = await AuthService.checkIsActive(user.id);
          if (mounted) {
            if (isActive == true) {
              Navigator.pushReplacementNamed(context, '/main');
            } else {
              await AuthService.signOut();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isActive == false
                          ? 'account_deactivated'.tr(context)
                          : 'account_not_found'.tr(context),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'google_sign_in_failed'.tr(context)}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFacebookSignIn() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.signInWithFacebook();
      if (mounted) {
        final user = AuthService.currentUser;
        if (user != null) {
          final isActive = await AuthService.checkIsActive(user.id);
          if (mounted) {
            if (isActive == true) {
              Navigator.pushReplacementNamed(context, '/main');
            } else {
              await AuthService.signOut();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isActive == false
                          ? 'account_deactivated'.tr(context)
                          : 'account_not_found'.tr(context),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Facebook Sign In failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await AuthService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) {
          final user = AuthService.currentUser;
          if (user != null) {
            final isActive = await AuthService.checkIsActive(user.id);
            if (mounted) {
              if (isActive == true) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/main',
                  (route) => false,
                );
              } else {
                await AuthService.signOut();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        (isActive == false)
                            ? 'account_deactivated'.tr(context)
                            : 'account_not_found'.tr(context),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e is AuthException ? e.message : 'login_failed'.tr(context),
                style: GoogleFonts.inter(fontSize: 13),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'please_fix_errors'.tr(context),
            style: GoogleFonts.inter(fontSize: 13),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Back Button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).inputDecorationTheme.fillColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      // Language Picker Button
                      TextButton.icon(
                        onPressed: _showLanguagePicker,
                        icon: Icon(
                          Icons.language_rounded,
                          size: 18,
                          color: Theme.of(context).primaryColor,
                        ),
                        label: Text(
                          LanguageController.instance.currentLanguage,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          backgroundColor: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Heading
                Text(
                  'welcome_back'.tr(context),
                  style: GoogleFonts.nunito(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).textTheme.displayLarge?.color,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'signin_continue'.tr(context),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 40),
                // Email Field
                Text(
                  'email_address'.tr(context),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  decoration: InputDecoration(
                    hintText: 'enter_email'.tr(context),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Password Field
                Text(
                  'password'.tr(context),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: _validatePassword,
                  decoration: InputDecoration(
                    hintText: 'enter_password'.tr(context),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.textLight,
                    ),
                    suffixIcon: GestureDetector(
                      onTap: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/forgot-password');
                    },
                    child: Text(
                      'forgot_password'.tr(context),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('login'.tr(context)),
                ),
                const SizedBox(height: 24),
                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.divider)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'continue_with'.tr(context),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.divider)),
                  ],
                ),
                const SizedBox(height: 24),
                // Social Login Buttons
                Row(
                  children: [
                    Expanded(
                      child: _socialButton(
                        Icons.g_mobiledata_rounded,
                        'google'.tr(context),
                        onTap: _isLoading ? null : _handleGoogleSignIn,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _socialButton(
                        Icons.facebook_rounded,
                        'facebook'.tr(context),
                        color: const Color(0xFF1877F2),
                        onTap: _isLoading ? null : _handleFacebookSignIn,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Sign Up Link
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/signup');
                    },
                    child: RichText(
                      text: TextSpan(
                        text: 'dont_have_account'.tr(context),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        children: [
                          TextSpan(
                            text: 'signup'.tr(context),
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton(
    IconData icon,
    String label, {
    Color? color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Theme.of(context).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
