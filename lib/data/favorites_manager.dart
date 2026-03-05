import 'package:flutter/material.dart';
import '../models/property.dart';

class FavoritesManager extends ChangeNotifier {
  static final FavoritesManager _instance = FavoritesManager._internal();
  factory FavoritesManager() => _instance;
  FavoritesManager._internal();

  final Set<String> _favoriteIds = {};

  bool isFavorite(String propertyId) => _favoriteIds.contains(propertyId);

  void toggle(String propertyId) {
    if (_favoriteIds.contains(propertyId)) {
      _favoriteIds.remove(propertyId);
    } else {
      _favoriteIds.add(propertyId);
    }
    notifyListeners();
  }

  List<Property> getFavorites(List<Property> allProperties) {
    return allProperties.where((p) => _favoriteIds.contains(p.id)).toList();
  }

  int get count => _favoriteIds.length;
}
