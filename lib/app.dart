import 'package:flutter/material.dart';
import 'core/notifications/notification_service.dart';
import 'core/connectivity/connectivity_wrapper.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/language/language_controller.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/welcome/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/profile/edit_profile_screen.dart';

class ManaKiraaApp extends StatelessWidget {
  final ThemeController _themeController = ThemeController.instance;
  final LanguageController _languageController = LanguageController.instance;

  ManaKiraaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeController,
      builder: (context, mode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: _languageController,
          builder: (context, locale, _) {
            return MaterialApp(
              title: 'Mana Kiraa',
              navigatorKey: NotificationService.navigatorKey,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: mode,
              locale: locale,
              initialRoute: '/splash',
              builder: (context, child) => ConnectivityWrapper(child: child!),
              routes: {
                '/splash': (context) => const SplashScreen(),
                '/welcome': (context) => const WelcomeScreen(),
                '/login': (context) => const LoginScreen(),
                '/signup': (context) => const SignupScreen(),
                '/main': (context) => const MainScreen(),
                '/notifications': (context) => const NotificationsScreen(),
                '/edit-profile': (context) => const EditProfileScreen(),
              },
            );
          },
        );
      },
    );
  }
}
