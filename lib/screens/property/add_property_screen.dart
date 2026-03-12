import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/language/translations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/property/property_controller.dart';
import '../../core/supabase/supabase_service.dart';
import '../../data/mock_data.dart';
import '../../models/property.dart';

class AddPropertyScreen extends StatefulWidget {
  /// Pass a property to edit an existing one; null means add new.
  final Property? property;
  const AddPropertyScreen({super.key, this.property});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  XFile? _idFile;

  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _locationController;
  late final TextEditingController _cityController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _bedsController;
  late final TextEditingController _bathsController;
  late final TextEditingController _sqmController;
  late final TextEditingController _phoneController;

  late String _selectedType;
  late List<String> _selectedAmenities;
  bool _isLoading = false;

  bool get _isEditing => widget.property != null;

  final List<String> _types = [
    'Single Room',
    'Organization',
    'Commercial',
    'Family House',
    'Store',
  ];

  final List<String> _availableAmenities = [
    'amenity_kitchen',
    'amenity_water',
    'amenity_toilet',
    'amenity_shower',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    _selectedType = p?.type ?? 'Family House';
    _selectedAmenities = p != null ? List<String>.from(p.amenities) : [];

    _nameController = TextEditingController(text: p?.name ?? '');
    _priceController = TextEditingController(
      text: p != null ? p.price.toStringAsFixed(0) : '',
    );
    _locationController = TextEditingController(text: p?.location ?? '');
    _cityController = TextEditingController(text: p?.city ?? 'Yabello');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _bedsController = TextEditingController(
      text: p != null ? p.bedrooms.toString() : '',
    );
    _bathsController = TextEditingController(
      text: p != null ? p.bathrooms.toString() : '',
    );
    _sqmController = TextEditingController(
      text: p != null ? p.area.toString() : '',
    );
    _phoneController = TextEditingController(text: p?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    _bedsController.dispose();
    _bathsController.dispose();
    _sqmController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, {bool isId = false}) async {
    try {
      final XFile? selected = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (selected != null) {
        setState(() {
          if (isId) {
            _idFile = selected;
          } else {
            _imageFile = selected;
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImageSourceSheet({bool isId = false}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerTheme.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text('gallery'.tr(context)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, isId: isId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: Text('camera'.tr(context)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, isId: isId);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        String idUrl = widget.property?.verificationDocumentUrl ?? '';

        if (_idFile != null) {
          final bytes = await File(_idFile!.path).readAsBytes();
          final uploadedUrl = await SupabaseService.uploadVerificationDocument(
            fileName: 'national_id.jpg',
            bytes: bytes,
          );
          if (uploadedUrl != null) {
            idUrl = uploadedUrl;
          }
        }

        final property = Property(
          id: widget.property?.id ?? '',
          user_id: widget.property?.user_id,
          name: _nameController.text,
          location: _locationController.text,
          city: _cityController.text,
          price: double.tryParse(_priceController.text) ?? 0.0,
          imageUrl:
              _imageFile?.path ??
              widget.property?.imageUrl ??
              'https://images.unsplash.com/photo-1518780664697-55e3ad937233?w=600',
          type: _selectedType,
          phoneNumber: _phoneController.text,
          isVerified: widget.property?.isVerified ?? false,
          verificationStatus: idUrl.isNotEmpty ? 'pending' : 'unverified',
          verificationDocumentUrl: idUrl,
          description: _descriptionController.text,
          bedrooms: _selectedType == 'Family House'
              ? int.tryParse(_bedsController.text) ?? 0
              : 0,
          bathrooms: _selectedType == 'Family House'
              ? int.tryParse(_bathsController.text) ?? 0
              : 0,
          area: int.tryParse(_sqmController.text) ?? 0,
          amenities: _selectedAmenities,
        );

        if (_isEditing) {
          await PropertyController.instance.updateProperty(property);
        } else {
          await PropertyController.instance.addProperty(property);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? 'property_updated_success'.tr(context)
                    : 'property_added_success'.tr(context),
              ),
              backgroundColor: AppColors.verified,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.textTheme.displayLarge?.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'edit_property'.tr(context) : 'add_property'.tr(context),
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            color: theme.textTheme.displayLarge?.color,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image picker
              _buildFieldLabel('upload_images'.tr(context)),
              GestureDetector(
                onTap: _showImageSourceSheet,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          theme.dividerTheme.color ??
                          Colors.grey.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: _buildImagePreview(theme),
                ),
              ),
              const SizedBox(height: 24),

              // National ID picker
              _buildFieldLabel('National ID (Verification)'),
              GestureDetector(
                onTap: () => _showImageSourceSheet(isId: true),
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          theme.dividerTheme.color ??
                          Colors.grey.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: _idFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(
                            File(_idFile!.path),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.badge_outlined,
                              size: 32,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Upload National ID',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textLight.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Property Title
              _buildFieldLabel('property_title'.tr(context)),
              _buildTextField(
                controller: _nameController,
                hintText: 'property_title_hint'.tr(context),
                validator: (v) =>
                    v!.isEmpty ? 'property_name_required'.tr(context) : null,
              ),
              const SizedBox(height: 20),

              // Price & Area row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('price_per_month'.tr(context)),
                        _buildTextField(
                          controller: _priceController,
                          hintText: '0.00',
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('sqm_label'.tr(context)),
                        _buildTextField(
                          controller: _sqmController,
                          hintText: '0',
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // City
              _buildFieldLabel('location_city'.tr(context)),
              _buildTextField(
                controller: _cityController,
                hintText: 'e.g. Yabello',
              ),
              const SizedBox(height: 20),

              _buildFieldLabel('address'.tr(context)),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final List<String> existingLocations = MockData.locations;
                  if (textEditingValue.text.isEmpty) {
                    return existingLocations;
                  }
                  return existingLocations.where((String option) {
                    return option.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    );
                  });
                },
                onSelected: (String selection) {
                  _locationController.text = selection;
                },
                fieldViewBuilder:
                    (
                      context,
                      textEditingController,
                      focusNode,
                      onFieldSubmitted,
                    ) {
                      // Sync with our controller
                      if (textEditingController.text !=
                          _locationController.text) {
                        textEditingController.text = _locationController.text;
                      }
                      textEditingController.addListener(() {
                        _locationController.text = textEditingController.text;
                      });

                      return _buildTextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        hintText: 'e.g. Kebele 01',
                        validator: (v) => v!.isEmpty ? 'required' : null,
                      );
                    },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width - 40,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return ListTile(
                              title: Text(
                                option,
                                style: GoogleFonts.inter(fontSize: 14),
                              ),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Phone
              _buildFieldLabel('Phone Number'),
              _buildTextField(
                controller: _phoneController,
                hintText: 'e.g. +251911223344',
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'required' : null,
              ),
              const SizedBox(height: 20),

              // Category
              _buildFieldLabel('category'.tr(context)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        theme.dividerTheme.color ??
                        Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: _types
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedType = v!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const SizedBox(height: 20),

              // Bedroom & Bathroom – only for Family House
              if (_selectedType == 'Family House') ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('beds'.tr(context)),
                          _buildTextField(
                            controller: _bedsController,
                            hintText: '0',
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('baths'.tr(context)),
                          _buildTextField(
                            controller: _bathsController,
                            hintText: '0',
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Amenities - only for Single Room and Family House
              if (_selectedType == 'Single Room' ||
                  _selectedType == 'Family House') ...[
                _buildFieldLabel('select_amenities'.tr(context)),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableAmenities.map((amenity) {
                    final isSelected = _selectedAmenities.contains(amenity);
                    return FilterChip(
                      label: Text(
                        amenity.tr(context),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isSelected
                              ? Colors.white
                              : theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedAmenities.add(amenity);
                          } else {
                            _selectedAmenities.remove(amenity);
                          }
                        });
                      },
                      selectedColor: theme.primaryColor,
                      checkmarkColor: Colors.white,
                      backgroundColor: theme.colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? theme.primaryColor
                              : (theme.dividerTheme.color ??
                                    Colors.grey.withValues(alpha: 0.2)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Description
              _buildFieldLabel('description'.tr(context)),
              _buildTextField(
                controller: _descriptionController,
                hintText: 'description_hint'.tr(context),
                maxLines: 4,
              ),
              const SizedBox(height: 32),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing
                              ? 'save_changes'.tr(context)
                              : 'submit_property'.tr(context),
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(ThemeData theme) {
    if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.file(File(_imageFile!.path), fit: BoxFit.cover),
      );
    }
    if (widget.property != null &&
        widget.property!.imageUrl.isNotEmpty &&
        widget.property!.imageUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              widget.property!.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _imagePlaceholder(theme),
            ),
            Container(
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                  ],
                ),
              ),
              child: Text(
                'Tap to change image',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
    return _imagePlaceholder(theme);
  }

  Widget _imagePlaceholder(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 42,
          color: theme.primaryColor,
        ),
        const SizedBox(height: 12),
        Text(
          'add_image_hint'.tr(context),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textLight.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Theme.of(
            context,
          ).textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    FocusNode? focusNode,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      focusNode: focusNode,
      style: GoogleFonts.inter(fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          color: AppColors.textLight.withValues(alpha: 0.5),
          fontSize: 14,
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color:
                theme.dividerTheme.color ?? Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color:
                theme.dividerTheme.color ?? Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}
