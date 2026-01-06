import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/supabase_client.dart';

class StorageService {
  static const String _bucketName = 'content-images';
  Future<String> uploadImage(Uint8List bytes, String path) async {
    try {
      await Supa.client.storage.from(_bucketName).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              upsert: true, // Overwrite if exists
            ),
          );
      return getPublicUrl(path);
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
  String getPublicUrl(String path) {
    try {
      return Supa.client.storage.from(_bucketName).getPublicUrl(path);
    } catch (e) {
      throw Exception('Failed to get public URL: $e');
    }
  }
  Future<void> deleteImage(String path) async {
    try {
      await Supa.client.storage.from(_bucketName).remove([path]);
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  Future<List<FileObject>> listFiles(String path) async {
    try {
      final files =
          await Supa.client.storage.from(_bucketName).list(path: path);

      return files;
    } catch (e) {
      throw Exception('Failed to list files: $e');
    }
  }

  /// Move/rename a file
  ///
  /// [fromPath] - Current file path
  /// [toPath] - New file path
  Future<void> moveFile(String fromPath, String toPath) async {
    try {
      await Supa.client.storage.from(_bucketName).move(fromPath, toPath);
    } catch (e) {
      throw Exception('Failed to move file: $e');
    }
  }

  /// Copy a file
  ///
  /// [fromPath] - Source file path
  /// [toPath] - Destination file path
  Future<void> copyFile(String fromPath, String toPath) async {
    try {
      await Supa.client.storage.from(_bucketName).copy(fromPath, toPath);
    } catch (e) {
      throw Exception('Failed to copy file: $e');
    }
  }
}
