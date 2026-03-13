import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/language/translations.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  late List<AnimationController> _animControllers;
  late List<Animation<double>> _animations;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animControllers = List.generate(
      6,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );
    _animations = _animControllers.map((controller) {
      return CurvedAnimation(parent: controller, curve: Curves.elasticOut);
    }).toList();

    // Initial staggered entry animation
    for (var i = 0; i < 6; i++) {
      Future.delayed(Duration(milliseconds: 100 * i), () {
        if (mounted) _animControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var anim in _animControllers) {
      anim.dispose();
    }
    super.dispose();
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length != 6) return;

    setState(() => _isLoading = true);
    try {
      await AuthService.verifyResetOTP(email: widget.email, token: otp);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('otp_verified_success'.tr(context)),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushReplacementNamed(
          context,
          '/reset-password',
          arguments: widget.email,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AuthException ? e.message : 'invalid_otp'.tr(context),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onPaste(String pastedText) async {
    String cleanText = pastedText.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.length > 6) cleanText = cleanText.substring(0, 6);

    for (int i = 0; i < cleanText.length; i++) {
      // Staggered fill and animation
      await Future.delayed(const Duration(milliseconds: 60));
      if (mounted) {
        _controllers[i].text = cleanText[i];
        _animControllers[i].forward(from: 0.0);
      }
    }

    int nextFocus = cleanText.length < 6 ? cleanText.length : 5;
    _focusNodes[nextFocus].requestFocus();

    if (cleanText.length == 6) {
      _handleVerifyOtp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.textTheme.bodyLarge?.color,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'verify_otp'.tr(context),
                style: GoogleFonts.nunito(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: theme.textTheme.displayLarge?.color,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'enter_otp_hint'.tr(context),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (index) => ScaleTransition(
                    scale: _animations[index],
                    child: SizedBox(
                      width: 45,
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.displayLarge?.color,
                        ),
                        decoration: InputDecoration(
                          counterText: "",
                          contentPadding: EdgeInsets.zero,
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: AppColors.divider,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: theme.primaryColor,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.length > 1) {
                            _onPaste(value);
                            return;
                          }

                          if (value.isNotEmpty) {
                            _animControllers[index].forward(from: 0.5);
                            if (index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            }
                          } else if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }

                          if (index == 5 && value.isNotEmpty) {
                            _handleVerifyOtp();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'confirm'.tr(context),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () {
                    AuthService.resetPasswordForEmail(widget.email);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('password_reset_sent'.tr(context)),
                      ),
                    );
                  },
                  child: Text(
                    'resend_code'.tr(context),
                    style: GoogleFonts.inter(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
