import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/property.dart';
import '../supabase/supabase_service.dart';

class PropertyController extends ValueNotifier<List<Property>> {
  StreamSubscription<List<Property>>? _subscription;

  PropertyController._() : super([]) {
    _initRealtime();
    _updateMyProperties();
  }

  static final PropertyController instance = PropertyController._();

  void _initRealtime() {
    _subscription?.cancel();
    _subscription = SupabaseService.getPropertiesStream().listen((properties) {
      value = properties;
      _updateMyProperties();
    });
  }

  final ValueNotifier<List<Property>> myProperties = ValueNotifier([]);

  void _updateMyProperties() {
    final user = Supabase.instance.client.auth.currentUser;
    myProperties.value = value.where((p) => p.user_id == user?.id).toList();
  }

  static Stream<List<Property>> getMyPropertiesStream() {
    final user = Supabase.instance.client.auth.currentUser;
    return SupabaseService.getPropertiesStream().map(
      (list) => list.where((p) => p.user_id == user?.id).toList(),
    );
  }

  Future<void> addProperty(Property property) async {
    await SupabaseService.addProperty(property);
    // Real-time listener will update the list automatically
  }

  Future<void> updateProperty(Property property) async {
    await SupabaseService.updateProperty(property);
  }

  Future<void> submitVerification(String propertyId, String idImageUrl) async {
    await _supabaseService.submitVerification(
      propertyId: propertyId,
      idImageUrl: idImageUrl,
    );
  }

  final _supabaseService = SupabaseService();

  Future<void> removeProperty(String id) async {
    await SupabaseService.deleteProperty(id);
  }

  Future<void> refresh() async {
    final properties = await SupabaseService.fetchProperties();
    value = properties;
    _updateMyProperties();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  List<Property> get properties => value;
}
