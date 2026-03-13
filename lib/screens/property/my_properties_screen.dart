import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/property.dart';
import '../../core/property/property_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/language/translations.dart';
import '../../core/utils/ui_utils.dart';
import 'add_property_screen.dart';
import '../property/property_detail_screen.dart';

class MyPropertiesScreen extends StatefulWidget {
  const MyPropertiesScreen({super.key});

  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen> {
  final PropertyController _controller = PropertyController.instance;

  @override
  void initState() {
    super.initState();
    _controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'my_properties'.tr(context),
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => _controller.refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<Property>>(
        valueListenable: _controller.myProperties,
        builder: (context, properties, _) {
          if (properties.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.home_work_outlined,
                    size: 80,
                    color: AppColors.textLight.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'no_properties_posted'.tr(context),
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final property = properties[index];
              return _buildPropertyCard(property, context);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
          );
          _controller.refresh();
        },
        label: Text('post_property'.tr(context)),
        icon: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildPropertyCard(Property property, BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                property.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image_rounded),
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    property.name,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (property.isVerified)
                  const Icon(
                    Icons.verified_rounded,
                    color: AppColors.verified,
                    size: 16,
                  )
                else if (property.verificationStatus == 'pending')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'pending_approval'.tr(context),
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      property.location,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'ETB ${property.price}/mo',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PropertyDetailScreen(property: property),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                if (property.verificationStatus == 'pending')
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'pending'.tr(context),
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (property.isVerified)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.verified.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'verified'.tr(context),
                      style: const TextStyle(
                        color: AppColors.verified,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                // Edit
                IconButton(
                  tooltip: 'edit'.tr(context),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddPropertyScreen(property: property),
                      ),
                    );
                    _controller.refresh();
                  },
                  icon: Icon(Icons.edit_outlined, color: theme.primaryColor),
                ),
                // Delete
                IconButton(
                  tooltip: 'delete'.tr(context),
                  onPressed: () => _confirmDelete(property),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Property property) async {
    final confirmed = await UIUtils.showConfirmationSheet(
      context,
      title: 'delete_property_confirm_title'.tr(context),
      message: 'delete_property_confirm_message'.tr(context),
      confirmLabel: 'delete'.tr(context),
      cancelLabel: 'cancel'.tr(context),
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed == true && mounted) {
      await _controller.removeProperty(property.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('property_removed'.tr(context)),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }
}
