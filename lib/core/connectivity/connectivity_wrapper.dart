import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../connectivity/connectivity_service.dart';
import '../supabase/auth_service.dart';
import '../notifications/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper>
    with SingleTickerProviderStateMixin {
  bool _isOnline = true;
  bool _showBanner = false;
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  StreamSubscription<bool>? _sub;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _isOnline = ConnectivityService.instance.isOnline;
    bool _hasInitialized = false;

    _sub = ConnectivityService.instance.onConnectivityChanged.listen((online) {
      if (!mounted) return;

      // Skip the first emission — it's just the initial state, not a real change
      if (!_hasInitialized) {
        _hasInitialized = true;
        if (mounted) setState(() => _isOnline = online);
        return;
      }

      setState(() {
        _isOnline = online;
        _showBanner = true;
      });

      if (online) {
        _animController.forward();
        // Hide "Back online" banner after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _animController.reverse().then((_) {
              if (mounted) setState(() => _showBanner = false);
            });
          }
        });
      } else {}
    });

    // Listen to Auth state changes to manage account status subscription
    _authSub = AuthService.authStateChanges.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        _startAccountStatusListener(user.id, user.email);
      } else {
        _stopAccountStatusListener();
      }
    });

    // Initial check if already logged in
    final user = AuthService.currentUser;
    if (user != null) {
      _startAccountStatusListener(user.id, user.email);
    }
  }

  StreamSubscription<bool>? _accountSub;

  void _startAccountStatusListener(String userId, String? email) {
    _stopAccountStatusListener();

    debugPrint('📱 Starting Realtime Account Listener for: $userId ($email)');
    _accountSub = AuthService.getAccountStatusStream(userId, email).listen((
      isActive,
    ) async {
      if (!isActive && mounted) {
        debugPrint('🚫 Account deactivated/deleted! Forcing instant logout...');

        // 1. Force Logout in Supabase
        await AuthService.signOut();

        // 2. Clear UI and redirect
        final navigator = NotificationService.navigatorKey.currentState;
        if (navigator != null) {
          navigator.pushNamedAndRemoveUntil('/welcome', (route) => false);
        }

        // 3. Show Alert
        final context = NotificationService.navigatorKey.currentContext;
        if (context != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Your account has been deactivated by an administrator.',
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    });
  }

  void _stopAccountStatusListener() {
    if (_accountSub != null) {
      debugPrint('🛑 Stopping Realtime Account Listener');
      _accountSub!.cancel();
      _accountSub = null;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _authSub?.cancel();
    _stopAccountStatusListener();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showBanner)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: _ConnectivityBanner(isOnline: _isOnline),
            ),
          ),
        // Full-screen overlay when completely offline
        if (!_isOnline) const _OfflineOverlay(),
      ],
    );
  }
}

class _ConnectivityBanner extends StatelessWidget {
  final bool isOnline;
  const _ConnectivityBanner({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 10,
          left: 20,
          right: 20,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isOnline
                ? [const Color(0xFF27AE60), const Color(0xFF2ECC71)]
                : [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
          ),
          boxShadow: [
            BoxShadow(
              color:
                  (isOnline ? const Color(0xFF27AE60) : const Color(0xFFE74C3C))
                      .withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              isOnline ? '✓  Back online!' : 'No internet connection',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineOverlay extends StatelessWidget {
  const _OfflineOverlay();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Positioned.fill(
      child: Material(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated wifi icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF5F5F5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      size: 56,
                      color: Color(0xFFE74C3C),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'No Internet Connection',
                    style: GoogleFonts.nunito(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: theme.textTheme.displayLarge?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Looks like you're offline. Please check your Wi-Fi or mobile data and try again.",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.6,
                      ),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Waiting for connection...',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
