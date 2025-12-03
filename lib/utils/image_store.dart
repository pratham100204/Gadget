import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

class ImageStore {
  // Save image bytes as base64 string in SharedPreferences
  static Future<bool> saveImage(String key, Uint8List bytes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = base64Encode(bytes);
      return await prefs.setString(_prefKey(key), encoded);
    } catch (e) {
      return false;
    }
  }

  static Future<Uint8List?> loadImage(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_prefKey(key));
    if (encoded == null) return null;
    try {
      return base64Decode(encoded);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> removeImage(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(_prefKey(key));
  }

  static String _prefKey(String key) => 'item_image_$key';
}
