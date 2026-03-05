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
    {
      'name': 'Addis Ketema',
      'properties': 15,
      'image':
          'https://images.unsplash.com/photo-1544085311-11a028465b0c?w=400',
    },
    {
      'name': 'Bajaj Tera(Quufto)',
      'properties': 8,
      'image':
          'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=400',
    },
    {
      'name': 'Stadium',
      'properties': 12,
      'image':
          'https://images.unsplash.com/photo-1472214103451-9374bd1c798e?w=400',
    },
    {
      'name': 'Project(Quufto)',
      'properties': 10,
      'image':
          'https://images.unsplash.com/photo-1534067783941-51c9c23ecefd?w=400',
    },
    {
      'name': 'Garbi',
      'properties': 6,
      'image':
          'https://images.unsplash.com/photo-1510414842594-a61c69b5ae57?w=400',
    },
    {
      'name': 'Kella(Doloollo Hoola)',
      'properties': 9,
      'image':
          'https://images.unsplash.com/photo-1526772662000-3f88f10405ff?w=400',
    },
    {
      'name': 'Gabaya Guddo',
      'properties': 14,
      'image':
          'https://images.unsplash.com/photo-1449844908441-8829872d2607?w=400',
    },
    {
      'name': 'Gabaya Diqo',
      'properties': 7,
      'image':
          'https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?w=400',
    },
    {
      'name': 'Gidicho',
      'properties': 5,
      'image':
          'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=400',
    },
    {
      'name': 'Kideste mariam school sefer',
      'properties': 4,
      'image':
          'https://images.unsplash.com/photo-1478131143081-80f7f84ca84d?w=400',
    },
  ];

  void _showLocationProperties(
    BuildContext context,
    String locationName,
    List<Property> allProperties,
  ) {
    final filtered = allProperties
        .where(
          (p) =>
              p.city.toLowerCase() == locationName.toLowerCase() ||
              p.location.toLowerCase().contains(locationName.toLowerCase()),
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
                                p.city.toLowerCase() ==
                                    loc['name'].toString().toLowerCase() ||
                                p.location.toLowerCase().contains(
                                  loc['name'].toString().toLowerCase(),
                                ),
                          )
                          .length;
                      loc['properties'] = count;

                      return GestureDetector(
                        onTap: () => _showLocationProperties(
                          context,
                          loc['name'],
                          properties,
                        ),
                        child: _locationCard(loc, theme),
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

  Widget _locationCard(Map<String, dynamic> loc, ThemeData theme) {
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
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              bottomLeft: Radius.circular(18),
            ),
            child: Image.network(
              loc['image'],
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 90,
                height: 90,
                color: theme.inputDecorationTheme.fillColor,
                child: const Icon(
                  Icons.location_city,
                  color: AppColors.textLight,
                ),
              ),
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
                  '${loc['properties']} Properties',
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
