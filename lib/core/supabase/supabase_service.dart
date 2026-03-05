import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/auth_service.dart';
import '../../models/property.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<List<Property>> fetchProperties() async {
    try {
      final response = await _client
          .from('properties')
          .select()
          .order('created_at', ascending: false);

      return (response as List).map((data) => _mapToProperty(data)).toList();
    } catch (e) {
      print('Error fetching properties: $e');
      return [];
    }
  }

  static Stream<List<Property>> getPropertiesStream() {
    return _client
        .from('properties')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((item) => _mapToProperty(item)).toList());
  }

  static Property _mapToProperty(Map<String, dynamic> data) {
    return Property(
      id: data['id'].toString(),
      user_id: data['user_id']?.toString(),
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      city: data['city'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['image_url'] ?? '',
      type: data['type'] ?? '',
      isVerified: data['is_verified'] ?? false,
      verificationStatus: data['verification_status'] ?? 'unverified',
      description: data['description'] ?? '',
      bedrooms: data['bedrooms'] ?? 1,
      bathrooms: data['bathrooms'] ?? 1,
      area: data['area'] ?? 0,
      amenities: List<String>.from(data['amenities'] ?? []),
      images: List<String>.from(data['images'] ?? []),
      phoneNumber: data['phone_number'] ?? '+251911223344',
    );
  }

  static Future<void> deleteProperty(String id) async {
    try {
      await _client.from('properties').delete().eq('id', id);
    } catch (e) {
      print('Error deleting property: $e');
      rethrow;
    }
  }

  static Future<void> addProperty(Property property) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      String imageUrl = property.imageUrl;

      // Handle local image upload if necessary
      if (imageUrl.startsWith('/') ||
          imageUrl.contains('cache') ||
          imageUrl.contains('Picker')) {
        final file = File(imageUrl);
        if (await file.exists()) {
          final fileExtension = file.path.split('.').last;
          final fileName =
              '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

          await _client.storage
              .from('properties')
              .upload(
                fileName,
                file,
                fileOptions: const FileOptions(upsert: true),
              );

          imageUrl = _client.storage.from('properties').getPublicUrl(fileName);
        }
      }

      await _client.from('properties').insert({
        'user_id': user.id,
        'name': property.name,
        'location': property.location,
        'city': property.city,
        'price': property.price,
        'image_url': imageUrl,
        'type': property.type,
        'is_verified': property.isVerified,
        'description': property.description,
        'bedrooms': property.bedrooms,
        'bathrooms': property.bathrooms,
        'area': property.area,
        'amenities': property.amenities,
        'images': [
          imageUrl,
        ], // Use the uploaded image as the first gallery image
        'phone_number': property.phoneNumber,
      });
    } catch (e) {
      print('Error adding property: $e');
      rethrow;
    }
  }

  static Future<void> updateProperty(Property property) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      String imageUrl = property.imageUrl;

      // Handle local image upload if necessary
      if (imageUrl.startsWith('/') ||
          imageUrl.contains('cache') ||
          imageUrl.contains('Picker')) {
        final file = File(imageUrl);
        if (await file.exists()) {
          final fileExtension = file.path.split('.').last;
          final fileName =
              '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

          await _client.storage
              .from('properties')
              .upload(
                fileName,
                file,
                fileOptions: const FileOptions(upsert: true),
              );

          imageUrl = _client.storage.from('properties').getPublicUrl(fileName);
        }
      }

      await _client
          .from('properties')
          .update({
            'name': property.name,
            'location': property.location,
            'city': property.city,
            'price': property.price,
            'image_url': imageUrl,
            'type': property.type,
            'description': property.description,
            'bedrooms': property.bedrooms,
            'bathrooms': property.bathrooms,
            'area': property.area,
            'amenities': property.amenities,
            'phone_number': property.phoneNumber,
          })
          .eq('id', property.id);
    } catch (e) {
      print('Error updating property: $e');
      rethrow;
    }
  }

  Future<void> submitVerification({
    required String propertyId,
    required String idImageUrl,
  }) async {
    try {
      await _client
          .from('properties')
          .update({
            'verification_status': 'pending',
            'verification_document_url': idImageUrl,
          })
          .eq('id', propertyId);
    } catch (e) {
      print('Error submitting verification: $e');
      rethrow;
    }
  }

  static Future<String?> uploadVerificationDocument({
    required String fileName,
    required Uint8List bytes,
  }) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return null;

      final path =
          'verifications/${user.id}_${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await Supabase.instance.client.storage
          .from('verification_docs')
          .uploadBinary(path, bytes);

      return Supabase.instance.client.storage
          .from('verification_docs')
          .getPublicUrl(path);
    } catch (e) {
      print('Error uploading verification doc: $e');
      return null;
    }
  }
}
