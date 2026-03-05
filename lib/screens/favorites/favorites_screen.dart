import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/language/translations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/property/property_controller.dart';
import '../../data/favorites_manager.dart';
import '../../models/property.dart';
import '../property/property_detail_screen.dart';
import '../home/widgets/property_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _favManager = FavoritesManager();

  @override
  void initState() {
    super.initState();
    _favManager.addListener(_onFavChanged);
  }

  @override
  void dispose() {
    _favManager.removeListener(_onFavChanged);
    super.dispose();
  }

  void _onFavChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ValueListenableBuilder<List<Property>>(
          valueListenable: PropertyController.instance,
          builder: (context, properties, _) {
            final favorites = _favManager.getFavorites(properties);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Text(
                    'favorites'.tr(context),
                    style: GoogleFonts.nunito(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: theme.textTheme.displayLarge?.color,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '${favorites.length} saved properties',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: favorites.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.favorite_border_rounded,
                                size: 72,
                                color: AppColors.textLight.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'no_favorites'.tr(context),
                                style: GoogleFonts.nunito(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textLight,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'tap_heart_to_save'.tr(context),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textLight,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 14,
                                childAspectRatio: 0.82,
                              ),
                          itemCount: favorites.length,
                          itemBuilder: (context, index) {
                            final property = favorites[index];
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
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
