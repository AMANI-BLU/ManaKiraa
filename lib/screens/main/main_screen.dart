import 'package:flutter/material.dart';
import '../../core/language/translations.dart';
import '../home/home_screen.dart';
import '../locations/locations_screen.dart';
import '../favorites/favorites_screen.dart';
import '../chat/chat_screen.dart';
import '../settings/settings_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/chat/chat_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    LocationsScreen(),
    FavoritesScreen(),
    ChatScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    ChatService.updatePresence(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.bottomNavigationBarTheme.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(
                  Icons.home_rounded,
                  Icons.home_outlined,
                  'home'.tr(context),
                  0,
                  theme,
                ),
                _navItem(
                  Icons.location_on_rounded,
                  Icons.location_on_outlined,
                  'locations'.tr(context),
                  1,
                  theme,
                ),
                _navItem(
                  Icons.favorite_rounded,
                  Icons.favorite_border_rounded,
                  'favorites'.tr(context),
                  2,
                  theme,
                ),
                StreamBuilder<int>(
                  stream: ChatService.getTotalUnreadCountStream(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _navItem(
                      Icons.chat_bubble_rounded,
                      Icons.chat_bubble_outline_rounded,
                      'chat'.tr(context),
                      3,
                      theme,
                      badgeCount: count,
                    );
                  },
                ),
                _navItem(
                  Icons.settings_rounded,
                  Icons.settings_outlined,
                  'settings'.tr(context),
                  4,
                  theme,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    int index,
    ThemeData theme, {
    int badgeCount = 0,
  }) {
    final isActive = _currentIndex == index;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? theme.primaryColor.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: isActive ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isActive ? activeIcon : inactiveIcon,
                    size: 24,
                    color: isActive ? theme.primaryColor : AppColors.textLight,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF1A1A1A)
                              : Colors.white,
                          width: 1.5,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          badgeCount > 9 ? '9+' : badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isActive ? 11 : 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? theme.primaryColor : AppColors.textLight,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
