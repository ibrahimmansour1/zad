import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/supabase_client.dart';

/// Represents an uploaded image with metadata
class ImageFile {
  final String url;
  final String identifier; // Storage path for deletion
  final DateTime uploadedAt;

  ImageFile({
    required this.url,
    required this.identifier,
    required this.uploadedAt,
  });

  factory ImageFile.fromJson(Map<String, dynamic> json) {
    return ImageFile(
      url: json['url'] ?? '',
      identifier: json['identifier'] ?? '',
      uploadedAt: DateTime.parse(
          json['uploadedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'identifier': identifier,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}

/// Service to manage image uploads, replacements, and deletions
class ImageManagementService {
  final SupabaseClient _supabase = Supa.client;

  // Supabase storage configuration
  static const String bucketName = 'images';
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
  static const List<String> validExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp'
  ];

  /// Upload a new image to storage
  /// Returns ImageFile with public URL and storage identifier
  Future<ImageFile> uploadImage({
    required File imageFile,
    required String folder, // 'languages', 'paths', 'categories', etc
  }) async {
    try {
      // Validate file before upload
      _validateImageFile(imageFile);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = imageFile.path.split('/').last;
      final fileNameWithTimestamp = '${timestamp}_$fileName';
      final filePath = '$folder/$fileNameWithTimestamp';

      debugPrint('[ImageService] Uploading to: $filePath');

      // Upload to Supabase Storage
      await _supabase.storage.from(bucketName).upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(upsert: false),
          );

      // Get public URL
      final publicUrl =
          _supabase.storage.from(bucketName).getPublicUrl(filePath);

      debugPrint('[ImageService] Upload successful: $publicUrl');

      return ImageFile(
        url: publicUrl,
        identifier: filePath,
        uploadedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[ImageService] Upload error: $e');
      throw Exception('Image upload failed: $e');
    }
  }

  /// Replace an existing image
  /// Deletes old image and uploads new one
  Future<ImageFile> replaceImage({
    required File newImageFile,
    required String folder,
    String? oldImageIdentifier,
  }) async {
    try {
      // Delete old image first if it exists
      if (oldImageIdentifier != null && oldImageIdentifier.isNotEmpty) {
        await deleteImage(oldImageIdentifier);
      }

      // Upload new image
      return await uploadImage(imageFile: newImageFile, folder: folder);
    } catch (e) {
      debugPrint('[ImageService] Replace error: $e');
      throw Exception('Image replacement failed: $e');
    }
  }

  /// Delete an image from storage
  /// Does not throw if deletion fails (continues gracefully)
  Future<void> deleteImage(String imageIdentifier) async {
    try {
      if (imageIdentifier.isEmpty) return;

      debugPrint('[ImageService] Deleting: $imageIdentifier');

      await _supabase.storage.from(bucketName).remove([imageIdentifier]);

      debugPrint('[ImageService] Deleted successfully: $imageIdentifier');
    } catch (e) {
      debugPrint('[ImageService] Delete warning (non-fatal): $e');
      // Don't throw - continue even if delete fails
      // This prevents UI errors when old images can't be deleted
    }
  }

  /// Validate image file before upload
  /// Throws exception if invalid
  void _validateImageFile(File file) {
    // Check file exists
    if (!file.existsSync()) {
      throw Exception('File does not exist');
    }

    // Check file size
    final fileSizeBytes = file.lengthSync();
    if (fileSizeBytes > maxFileSizeBytes) {
      throw Exception('File size exceeds 5MB limit');
    }

    // Check file extension
    final extension = file.path.split('.').last.toLowerCase();
    if (!validExtensions.contains(extension)) {
      throw Exception('Invalid image format. Allowed: $validExtensions');
    }
  }

  /// Check if a URL is a valid public image URL
  bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http');
  }
}
