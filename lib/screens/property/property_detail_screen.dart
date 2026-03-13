import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/language/translations.dart';
import '../../models/property.dart';
import '../../data/favorites_manager.dart';
import '../chat/chat_detail_screen.dart';
import '../../core/supabase/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Property property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen>
    with SingleTickerProviderStateMixin {
  final _favManager = FavoritesManager();
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heartScale =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
        );
    _favManager.addListener(_onFavChanged);
  }

  @override
  void dispose() {
    _heartController.dispose();
    _favManager.removeListener(_onFavChanged);
    super.dispose();
  }

  void _onFavChanged() {
    if (mounted) setState(() {});
  }

  void _toggleFavorite() {
    _favManager.toggle(widget.property.id);
    _heartController.forward(from: 0);
  }

  Future<void> _makeCall() async {
    final Uri url = Uri(scheme: 'tel', path: widget.property.phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('dialer_error'.tr(context))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final isFav = _favManager.isFavorite(property.id);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Hero Image App Bar
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: theme.appBarTheme.backgroundColor,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: _toggleFavorite,
                  child: ScaleTransition(
                    scale: _heartScale,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFav ? AppColors.favorite : Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'property_${property.id}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    property.imageUrl.isEmpty
                        ? _buildImageError(theme)
                        : property.imageUrl.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: property.imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) =>
                                _buildImageError(theme),
                          )
                        : Image.file(
                            File(property.imageUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildImageError(theme),
                          ),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.cardGradient,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          property.name,
                          style: GoogleFonts.nunito(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: theme.textTheme.displayLarge?.color,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'ETB ${property.price.toInt()}/mo',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? theme.scaffoldBackgroundColor
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        property.location,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Rating + Verified
                  Row(
                    children: [
                      const SizedBox(width: 10),
                      if (property.isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.verified.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                size: 16,
                                color: AppColors.verified,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'verified'.tr(context),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.verified,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Stats
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.inputDecorationTheme.fillColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (property.type != 'Single Room') ...[
                          _statItem(
                            Icons.bed_rounded,
                            property.bedrooms == 0
                                ? 'NA'
                                : '${property.bedrooms}',
                            'beds'.tr(context),
                            context,
                          ),
                          _verticalDivider(context),
                          _statItem(
                            Icons.bathtub_rounded,
                            property.bathrooms == 0
                                ? 'NA'
                                : '${property.bathrooms}',
                            'baths'.tr(context),
                            context,
                          ),
                          _verticalDivider(context),
                        ],
                        _statItem(
                          Icons.square_foot_rounded,
                          property.area == 0 ? 'NA' : '${property.area}',
                          'sqm'.tr(context),
                          context,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Description
                  Text(
                    'description'.tr(context),
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    property.description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.7,
                      ),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Amenities
                  Text(
                    'amenities'.tr(context),
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: property.amenities.map((amenity) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.inputDecorationTheme.fillColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _amenityIcon(amenity),
                              size: 16,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatAmenityName(amenity),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom CTA
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (property.user_id != AuthService.currentUser?.id) ...[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        theme.dividerTheme.color?.withValues(alpha: 0.5) ??
                        AppColors.divider,
                  ),
                ),
                child: IconButton(
                  onPressed: () {
                    final chat = {
                      'name': 'property_owner'.tr(context),
                      'avatar':
                          'https://ui-avatars.com/api/?name=Owner&background=random',
                      'isOnline': true,
                      'phone': property.phoneNumber,
                      'propertyId': property.id,
                      'receiverId': property.user_id,
                    };
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(chat: chat),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _makeCall,
                child: Text('contact_landlord'.tr(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(
    IconData icon,
    String value,
    String label,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 24, color: theme.primaryColor),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: Theme.of(context).dividerTheme.color,
    );
  }

  Widget _buildImageError(ThemeData theme) {
    return Container(
      color: theme.inputDecorationTheme.fillColor,
      child: const Icon(
        Icons.home_rounded,
        size: 60,
        color: AppColors.textLight,
      ),
    );
  }

  IconData _amenityIcon(String amenity) {
    final lower = amenity.toLowerCase();
    if (lower.contains('wifi') || lower.contains('internet')) {
      return Icons.wifi_rounded;
    }
    if (lower.contains('parking')) return Icons.local_parking_rounded;
    if (lower.contains('pool') || lower.contains('swim')) {
      return Icons.pool_rounded;
    }
    if (lower.contains('gym') || lower.contains('fitness')) {
      return Icons.fitness_center_rounded;
    }
    if (lower.contains('garden') || lower.contains('balcony')) {
      return Icons.yard_rounded;
    }
    if (lower.contains('ac') || lower.contains('air')) {
      return Icons.ac_unit_rounded;
    }
    if (lower.contains('security') || lower.contains('guard')) {
      return Icons.security_rounded;
    }
    if (lower.contains('laundry') || lower.contains('wash')) {
      return Icons.local_laundry_service_rounded;
    }
    if (lower.contains('power') ||
        lower.contains('generator') ||
        lower.contains('solar')) {
      return Icons.bolt_rounded;
    }
    if (lower.contains('water')) return Icons.water_drop_rounded;
    return Icons.check_circle_outline_rounded;
  }

  String _formatAmenityName(String name) {
    // Remove 'amenity_' prefix if it exists
    String formatted = name.replaceFirst('amenity_', '');

    // Custom common mappings
    if (formatted.toLowerCase() == 'wifi') return 'Wi-Fi';
    if (formatted.toLowerCase() == 'ac') return 'Air Conditioning';

    // Capitalize first letter and replace underscores with spaces
    formatted = formatted.replaceAll('_', ' ');
    if (formatted.isEmpty) return '';

    return formatted
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
