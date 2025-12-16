import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Utility class for handling local image storage
class ImageStorage {
  /// Saves an image file to the app's local storage and returns the file path
  /// Returns the local file path that can be stored in the database
  static Future<String?> saveImageLocally(File imageFile, int userId) async {
    try {
      // Get the app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      
      // Create a 'profile_images' subdirectory if it doesn't exist
      final imageDir = Directory(path.join(directory.path, 'profile_images'));
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }
      
      // Create a unique filename using user ID and timestamp
      final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final savedImagePath = path.join(imageDir.path, fileName);
      
      // Copy the image to the permanent location
      final savedFile = await imageFile.copy(savedImagePath);
      
      // Return the path that can be stored in database
      // We'll use a file:// prefix or just the path
      return savedFile.path;
    } catch (e) {
      debugPrint('Error saving image locally: $e');
      return null;
    }
  }
  
  /// Checks if a path is a local file path (not a URL)
  static bool isLocalPath(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return false;
    // Check if it's a local file path (starts with /, file://, or doesn't start with http/https)
    return !imagePath.startsWith('http://') && 
           !imagePath.startsWith('https://') &&
           (imagePath.startsWith('/') || imagePath.startsWith('file://'));
  }
  
  /// Gets a File object from a local path stored in database
  static File? getLocalFile(String? imagePath) {
    if (imagePath == null || !isLocalPath(imagePath)) return null;
    
    // Remove file:// prefix if present
    final cleanPath = imagePath.replaceFirst('file://', '');
    final file = File(cleanPath);
    
    // Return file if it exists
    return file.existsSync() ? file : null;
  }
  
  /// Deletes an old profile image file when updating
  static Future<void> deleteOldImage(String? oldImagePath) async {
    if (oldImagePath == null || !isLocalPath(oldImagePath)) return;
    
    try {
      final file = getLocalFile(oldImagePath);
      if (file != null && await file.exists()) {
        await file.delete();
        debugPrint('Deleted old profile image: $oldImagePath');
      }
    } catch (e) {
      debugPrint('Error deleting old image: $e');
      // Don't throw - image deletion failure shouldn't block profile update
    }
  }
}

