import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/language/translations.dart';
import '../../core/theme/app_colors.dart';
import '../../models/property.dart';
import '../property/property_detail_screen.dart';
import '../home/widgets/property_card.dart';
import '../../core/property/property_controller.dart';

class LocationsScreen extends StatelessWidget {
  const LocationsScreen({super.key});

  static const List<Map<String, dynamic>> _locations = [
    {'name': 'Addis Ketema', 'properties': 15},
    {'name': 'Bajaj Tera(Quufto)', 'properties': 8},
    {'name': 'Stadium', 'properties': 12},
    {'name': 'Project(Quufto)', 'properties': 10},
    {'name': 'Garbi', 'properties': 6},
    {'name': 'Kella(Doloollo Hoola)', 'properties': 9},
    {'name': 'Gabaya Guddo', 'properties': 14},
    {'name': 'Gabaya Diqo', 'properties': 7},
    {'name': 'Gidicho', 'properties': 5},
    {'name': 'Kideste mariam school sefer', 'properties': 4},
  ];

  void _showLocationProperties(
    BuildContext context,
    String locationName,
    List<Property> allProperties,
  ) {
    final filtered = allProperties
        .where(
          (p) =>
              p.isVerified &&
              (p.city.toLowerCase() == locationName.toLowerCase() ||
                  p.location.toLowerCase().contains(
                    locationName.toLowerCase(),
                  )),
        )
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationPropertiesSheet(
        locationName: locationName,
        properties: filtered,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'explore_locations'.tr(context),
                style: GoogleFonts.nunito(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: theme.textTheme.displayLarge?.color,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'popular_locations'.tr(context),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Locations List
            Expanded(
              child: ValueListenableBuilder<List<Property>>(
                valueListenable: PropertyController.instance,
                builder: (context, properties, _) {
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    itemCount: _locations.length,
                    separatorBuilder: (a1, a2) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final locData = _locations[index];
                      final loc = Map<String, dynamic>.from(locData);

                      // Count real properties for this location
                      final count = properties
                          .where(
                            (p) =>
                                p.isVerified &&
                                (p.city.toLowerCase() ==
                                        loc['name'].toString().toLowerCase() ||
                                    p.location.toLowerCase().contains(
                                      loc['name'].toString().toLowerCase(),
                                    )),
                          )
                          .length;
                      loc['properties'] = count;

                      return GestureDetector(
                        onTap: () => _showLocationProperties(
                          context,
                          loc['name'],
                          properties,
                        ),
                        child: _locationCard(loc, theme, context),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationCard(
    Map<String, dynamic> loc,
    ThemeData theme,
    BuildContext context,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Styled Placeholder with Icon
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.primaryColor.withValues(alpha: 0.1),
                  theme.primaryColor.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.location_city_rounded,
                  size: 32,
                  color: theme.primaryColor.withValues(alpha: 0.4),
                ),
                // Subtle overlay pattern or consistent image could go here
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc['name'],
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.textTheme.displayLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${loc['properties']} ${'properties'.tr(context)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Arrow
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: theme.inputDecorationTheme.fillColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: theme.textTheme.displayLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationPropertiesSheet extends StatelessWidget {
  final String locationName;
  final List<Property> properties;

  const _LocationPropertiesSheet({
    required this.locationName,
    required this.properties,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerTheme.color ?? AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${'properties_in'.tr(context)} $locationName',
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: theme.textTheme.displayLarge?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${properties.length}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.inputDecorationTheme.fillColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: theme.textTheme.displayLarge?.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: properties.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_off_outlined,
                          size: 56,
                          color: AppColors.textLight.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No properties in this area yet',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textLight,
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
                    itemCount: properties.length,
                    itemBuilder: (context, index) {
                      final property = properties[index];
                      return PropertyCard(
                        property: property,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PropertyDetailScreen(property: property),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
