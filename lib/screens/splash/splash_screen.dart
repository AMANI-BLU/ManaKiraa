import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    // Listen for password recovery deep link
    final authSub = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/reset-password',
            (route) => false,
          );
        }
      }
    });

    // Navigate based on auth session after animations
    Future.delayed(const Duration(milliseconds: 1000), () async {
      // If we are already navigating to reset-password, skip this
      if (!mounted) {
        authSub.cancel();
        return;
      }

      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final isActive = await AuthService.checkIsActive(session.user.id);
        if (mounted) {
          if (isActive == true) {
            // Check if we are already on reset-password (via deep link listener)
            // ModalRoute might be null during pushNamedAndRemoveUntil
            Navigator.pushReplacementNamed(context, '/main');
          } else {
            await AuthService.signOut();
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/welcome');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isActive == false
                        ? 'Your account has been deactivated.'
                        : 'Account not found. It may have been deleted.',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } else {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
      authSub.cancel();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/icons/app_icon.png',
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Mana Kiraa',
                      style: GoogleFonts.nunito(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: theme.primaryColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Find Your Dream Home',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.5,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
