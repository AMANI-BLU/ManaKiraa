import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/mock_data.dart';
import '../../core/language/translations.dart';
import '../../models/property.dart';
import '../../core/property/property_controller.dart';
import 'widgets/category_chip.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/property_card.dart';
import '../property/property_detail_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../core/chat/chat_service.dart';
import '../../core/notifications/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';
  bool _showAll = false;
  bool _hasUnreadNotifications = false;

  static const int _newlyAddedLimit = 8;

  @override
  void initState() {
    super.initState();
    ChatService.updatePresence(true);
    _checkUnreadNotifications();
  }

  Future<void> _checkUnreadNotifications() async {
    final notifs = await NotificationService.getPersistedNotifications();
    if (mounted) {
      setState(() {
        _hasUnreadNotifications = notifs.any((n) => !(n['isRead'] as bool));
      });
    }
  }

  List<Property> _getFilteredProperties(List<Property> properties) {
    // Only show verified properties to the public
    List<Property> result = properties.where((p) => p.isVerified).toList();

    // Filter by category
    if (_selectedCategoryIndex > 0) {
      final category = MockData.categories[_selectedCategoryIndex];
      result = result.where((p) => p.type == category).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.location.toLowerCase().contains(query) ||
            p.city.toLowerCase().contains(query);
      }).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await PropertyController.instance.refresh();
            await _checkUnreadNotifications();
          },
          color: theme.primaryColor,
          backgroundColor: theme.colorScheme.surface,
          child: ValueListenableBuilder<List<Property>>(
            valueListenable: PropertyController.instance,
            builder: (context, properties, _) {
              final filteredProperties = _getFilteredProperties(properties);

              // Determine display list: cap at 8 unless "See All" is active
              final isSearchOrFilter =
                  _searchQuery.isNotEmpty || _selectedCategoryIndex > 0;
              final bool limitResults = !_showAll && !isSearchOrFilter;
              final displayProperties =
                  limitResults && filteredProperties.length > _newlyAddedLimit
                  ? filteredProperties.sublist(0, _newlyAddedLimit)
                  : filteredProperties;

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Top Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          // Location
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.2 : 0.05,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: theme.primaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  Supabase
                                          .instance
                                          .client
                                          .auth
                                          .currentUser
                                          ?.email
                                          ?.split('@')[0] ??
                                      'yabello_et'.tr(context),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: theme.textTheme.displayLarge?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Notification
                          GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsScreen(),
                                ),
                              );
                              // Recheck unread after returning from notifications
                              _checkUnreadNotifications();
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: isDark ? 0.2 : 0.05,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _hasUnreadNotifications
                                        ? Icons.notifications_rounded
                                        : Icons.notifications_none_rounded,
                                    size: 22,
                                    color: theme.textTheme.displayLarge?.color,
                                  ),
                                ),
                                // Unread dot \u2014 only shown when there are unread notifications
                                if (_hasUnreadNotifications)
                                  Positioned(
                                    top: 7,
                                    right: 9,
                                    child: Container(
                                      width: 9,
                                      height: 9,
                                      decoration: BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: theme.colorScheme.surface,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Avatar
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/edit-profile'),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: theme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.2 : 0.08,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child:
                                  AuthService
                                          .currentUser
                                          ?.userMetadata?['avatar_url'] !=
                                      null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.network(
                                        AuthService
                                            .currentUser!
                                            .userMetadata!['avatar_url'],
                                        width: 42,
                                        height: 42,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        AuthService.currentUser?.email?[0]
                                                .toUpperCase() ??
                                            'U',
                                        style: GoogleFonts.nunito(
                                          fontWeight: FontWeight.w800,
                                          color: theme.primaryColor,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Text(
                        'discover_house'.tr(context),
                        style: GoogleFonts.nunito(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: theme.textTheme.displayLarge?.color,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),

                  // Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: SearchBarWidget(
                        onFilterTap: () {},
                        onChanged: (query) {
                          setState(() {
                            _searchQuery = query;
                            _showAll = false; // reset when searching
                          });
                        },
                      ),
                    ),
                  ),

                  // Categories
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: MockData.categories.length,
                          separatorBuilder: (a1, a2) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            return CategoryChip(
                              label: _getCategoryTranslation(
                                MockData.categories[index],
                                context,
                              ),
                              isSelected: _selectedCategoryIndex == index,
                              onTap: () {
                                setState(() {
                                  _selectedCategoryIndex = index;
                                  _showAll = false; // reset when filtering
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Section Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // "Newly Added" label with subtle badge
                          Row(
                            children: [
                              Text(
                                isSearchOrFilter
                                    ? 'results'.tr(context)
                                    : 'newly_added'.tr(context),
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textTheme.displayLarge?.color,
                                ),
                              ),
                              if (!isSearchOrFilter &&
                                  filteredProperties.length >
                                      _newlyAddedLimit) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _showAll
                                        ? '${filteredProperties.length}'
                                        : '$_newlyAddedLimit+',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          // "See All" / "Show Less" button
                          if (!isSearchOrFilter &&
                              filteredProperties.length > _newlyAddedLimit)
                            GestureDetector(
                              onTap: () => setState(() => _showAll = !_showAll),
                              child: Text(
                                _showAll
                                    ? 'show_less'.tr(context)
                                    : 'see_all'.tr(context),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.verified,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Property Grid or empty state
                  filteredProperties.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 60),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 56,
                                    color: AppColors.textLight.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'no_properties_found'.tr(context),
                                    style: GoogleFonts.nunito(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 14,
                                  childAspectRatio: 0.82,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final property = displayProperties[index];
                              return PropertyCard(
                                property: property,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PropertyDetailScreen(
                                        property: property,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }, childCount: displayProperties.length),
                          ),
                        ),

                  // Bottom Padding
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _getCategoryTranslation(String category, BuildContext context) {
    switch (category) {
      case 'All':
        return 'cat_all'.tr(context);
      case 'Single Room':
        return 'cat_single_room'.tr(context);
      case 'Organization':
        return 'cat_organization'.tr(context);
      case 'Commercial':
        return 'cat_commercial'.tr(context);
      case 'Family House':
        return 'cat_family_house'.tr(context);
      case 'Store':
        return 'cat_store'.tr(context);
      default:
        return category;
    }
  }
}
