import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class ImageStore {
  // Folder name where product images will be stored
  static const String _imagesFolderName = 'product_images';

  // Get the directory where images will be stored
  static Future<Directory> _getImagesDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDocDir.path}/$_imagesFolderName');
    
    // Create the directory if it doesn't exist
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    
    return imagesDir;
  }

  // Generate a safe filename from the key
  static String _sanitizeKey(String key) {
    // Remove or replace characters that are not safe for filenames
    return key.replaceAll(RegExp(r'[^\w\s-]'), '_').replaceAll(' ', '_');
  }

  // Save image bytes to a file in the product_images folder
  static Future<bool> saveImage(String key, Uint8List bytes) async {
    try {
      final imagesDir = await _getImagesDirectory();
      final sanitizedKey = _sanitizeKey(key);
      final file = File('${imagesDir.path}/$sanitizedKey.jpg');
      
      await file.writeAsBytes(bytes);
      return true;
    } catch (e) {
      print('Error saving image: $e');
      return false;
    }
  }

  // Load image bytes from a file
  static Future<Uint8List?> loadImage(String key) async {
    try {
      final imagesDir = await _getImagesDirectory();
      final sanitizedKey = _sanitizeKey(key);
      final file = File('${imagesDir.path}/$sanitizedKey.jpg');
      
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      print('Error loading image: $e');
      return null;
    }
  }

  // Remove an image file
  static Future<bool> removeImage(String key) async {
    try {
      final imagesDir = await _getImagesDirectory();
      final sanitizedKey = _sanitizeKey(key);
      final file = File('${imagesDir.path}/$sanitizedKey.jpg');
      
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error removing image: $e');
      return false;
    }
  }

  // Get the file path for an image (useful for debugging or direct file access)
  static Future<String?> getImagePath(String key) async {
    try {
      final imagesDir = await _getImagesDirectory();
      final sanitizedKey = _sanitizeKey(key);
      final file = File('${imagesDir.path}/$sanitizedKey.jpg');
      
      if (await file.exists()) {
        return file.path;
      }
      return null;
    } catch (e) {
      print('Error getting image path: $e');
      return null;
    }
  }

  // Clear all stored images (useful for cleanup or logout)
  static Future<bool> clearAllImages() async {
    try {
      final imagesDir = await _getImagesDirectory();
      
      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
        // Recreate the empty directory
        await imagesDir.create(recursive: true);
        return true;
      }
      return false;
    } catch (e) {
      print('Error clearing images: $e');
      return false;
    }
  }
}
