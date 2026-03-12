import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/property.dart';
import '../../../data/favorites_manager.dart';

class PropertyCard extends StatefulWidget {
  final Property property;
  final VoidCallback? onTap;

  const PropertyCard({super.key, required this.property, this.onTap});

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard>
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
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
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

  @override
  Widget build(BuildContext context) {
    final isFav = _favManager.isFavorite(widget.property.id);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Property Image with Hero
              Hero(
                tag: 'property_${widget.property.id}',
                child: SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: widget.property.imageUrl.isEmpty
                      ? _buildImageError(theme)
                      : widget.property.imageUrl.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: widget.property.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: theme.inputDecorationTheme.fillColor,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              _buildImageError(theme),
                        )
                      : Image.file(
                          File(widget.property.imageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildImageError(theme),
                        ),
                ),
              ),

              // Top Badges
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Category Badge (Glassmorphism)
                    _buildGlassBadge(
                      child: Text(
                        widget.property.type.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    // Favorite Button
                    GestureDetector(
                      onTap: _toggleFavorite,
                      child: ScaleTransition(
                        scale: _heartScale,
                        child: _buildGlassBadge(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 18,
                            color: isFav ? AppColors.favorite : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Glass Info Panel
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.property.name,
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.property.isVerified) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 18,
                                  color: AppColors.verified,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.property.location,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'ETB ${_formatPrice(widget.property.price)}',
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                flex: 4,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  alignment: WrapAlignment.end,
                                  children: [
                                    _miniStat(
                                      Icons.bed_rounded,
                                      widget.property.bedrooms.toString(),
                                    ),
                                    _miniStat(
                                      Icons.bathtub_rounded,
                                      widget.property.bathrooms.toString(),
                                    ),
                                    _miniStat(
                                      Icons.square_foot_rounded,
                                      widget.property.area.toString(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildImageError(ThemeData theme) {
    return Container(
      color: theme.inputDecorationTheme.fillColor,
      child: const Icon(
        Icons.home_rounded,
        size: 40,
        color: AppColors.textLight,
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      final formatted = price.toInt().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
      return formatted;
    }
    return price.toInt().toString();
  }

  Widget _miniStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 10, color: Colors.white60),
        const SizedBox(width: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassBadge({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
