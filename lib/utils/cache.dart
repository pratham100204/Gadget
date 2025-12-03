import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gadget/models/item.dart';
import 'package:gadget/models/user.dart';
import 'package:gadget/services/crud.dart';

// Singleton class to cache item data for faster access
class StartupCache {
  static StartupCache? _startupCache;
  static Map<String, List<String>>? _itemMap;
  bool reload = false;
  UserData? userData;

  StartupCache._createInstance();

  factory StartupCache({bool reload = false, UserData? userData}) {
    // Initialize singleton instance
    _startupCache ??= StartupCache._createInstance();
    _startupCache!.reload = reload;
    // Update userData if provided (crucial for context switches/logins)
    if (userData != null) {
      _startupCache!.userData = userData;
    }
    return _startupCache!;
  }

  // Getter for itemMap, initializes if null or reload is true
  Future<Map<String, List<String>>> get itemMap async {
    // Reload logic: If map is empty or forced reload is requested
    if (_itemMap == null || reload) {
      debugPrint('Cache: Reloading item map...');
      _itemMap = await initializeItemMap();
      reload = false; // Reset reload flag after fetching
    }
    return _itemMap!;
  }

  // Initializes the item map from Firestore
  Future<Map<String, List<String>>> initializeItemMap() async {
    final Map<String, List<String>> itemMap = {};

    // Ensure we have userData to fetch the correct database
    if (userData == null) {
      debugPrint("Cache Warning: UserData is null, cannot fetch items.");
      return itemMap;
    }

    final CrudHelper crudHelper = CrudHelper(userData: userData);
    final List<Item> items = await crudHelper.getItems();

    if (items.isEmpty) {
      return itemMap;
    }

    // Map format: ID -> [Name, Nickname]
    for (final Item item in items) {
      itemMap[item.id!] = [item.name ?? '', item.nickName ?? ''];
    }

    debugPrint("Cache: Item map initialized with ${itemMap.length} items.");
    return itemMap;
  }
}
