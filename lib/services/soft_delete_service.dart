import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/constants/db_constants.dart';
import 'package:zad_aldaia/core/supabase_client.dart';
import 'package:zad_aldaia/services/image_management_service.dart';

/// Retention period for deleted items in the recycle bin
const Duration recycleBinRetention = Duration(days: 30);

/// Exception thrown when parent is deleted
class ParentDeletedException implements Exception {
  final String message;
  ParentDeletedException(this.message);
  
  @override
  String toString() => message;
}

/// Exception thrown when content has references
class ContentHasReferencesException implements Exception {
  final String message;
  final int referenceCount;
  final List<Map<String, dynamic>> references;
  
  ContentHasReferencesException({
    required this.message,
    required this.referenceCount,
    required this.references,
  });
  
  @override
  String toString() => message;
}

/// Service to manage soft deletes (moves to recycle bin)
/// 
/// Supports cascade soft delete for hierarchical content and
/// handles content references properly.
class SoftDeleteService {
  SupabaseClient get _supabase => Supa.client;
  final ImageManagementService? _imageService;

  SoftDeleteService({ImageManagementService? imageService})
      : _imageService = imageService;

  // Note: Mapping methods now use DbSchemaMapper from db_constants.dart

  /// Check if content has references
  Future<List<Map<String, dynamic>>> _getReferences(String contentId) async {
    try {
      final refs = await _supabase
          .from('content_references')
          .select('id, parent_id, parent_table')
          .eq('original_id', contentId)
          .eq('is_deleted', false);
      return List<Map<String, dynamic>>.from(refs);
    } catch (e) {
      // Table might not exist yet
      debugPrint('[SoftDelete] Error checking references: $e');
      return [];
    }
  }

  /// Soft delete item with cascade to children
  /// Moves to recycle bin, can be restored
  Future<int> softDelete({
    required String id,
    required String tableName,
    String? userId,
    bool cascade = true,
    bool checkReferences = true,
  }) async {
    try {
      debugPrint('[SoftDelete] Soft deleting $id from $tableName');

      final userId_ = userId ?? Supa.currentUser?.id;
      int deletedCount = 0;

      // Check for references if enabled
      if (checkReferences) {
        final refs = await _getReferences(id);
        if (refs.isNotEmpty) {
          throw ContentHasReferencesException(
            message: 'Cannot delete: This content is referenced in ${refs.length} location(s). Remove references first.',
            referenceCount: refs.length,
            references: refs,
          );
        }
      }

      // Mark this item as deleted
      await _supabase.from(tableName).update({
        DbColumns.isDeleted: true,
        DbColumns.deletedAt: DateTime.now().toIso8601String(),
        DbColumns.deletedBy: userId_,
      }).eq(DbColumns.id, id);
      deletedCount++;

      // Cascade delete children if enabled
      if (cascade) {
        final contentType = DbSchemaMapper.getContentType(tableName);
        final childTable = contentType != null ? DbSchemaMapper.getChildTableName(contentType) : null;
        final parentField = contentType != null ? DbSchemaMapper.getParentFieldName(contentType) : null;
        
        if (childTable != null && parentField != null) {
          final children = await _supabase
              .from(childTable)
              .select(DbColumns.id)
              .eq(parentField, id)
              .neq(DbColumns.isDeleted, true);

          for (final child in children) {
            final childDeleted = await softDelete(
              id: child[DbColumns.id],
              tableName: childTable,
              userId: userId_,
              cascade: true,
              checkReferences: false, // Don't check references for children
            );
            deletedCount += childDeleted;
          }
        }
      }

      // Mark any references to this content as orphaned
      try {
        await _supabase.from(DbTables.contentReferences).update({
          'is_orphaned': true,
          'orphaned_at': DateTime.now().toIso8601String(),
        }).eq(DbColumns.originalId, id);
      } catch (e) {
        // Ignore if table doesn't exist
      }

      debugPrint('[SoftDelete] Successfully soft deleted $deletedCount items');
      return deletedCount;
    } catch (e) {
      debugPrint('[SoftDelete] Error: $e');
      rethrow;
    }
  }

  /// Restore item from recycle bin with parent validation
  Future<void> restore({
    required String id,
    required String tableName,
  }) async {
    try {
      debugPrint('[SoftDelete] Restoring $id from $tableName');

      // Check if parent exists and is not deleted
      final contentType = DbSchemaMapper.getContentType(tableName);
      final parentField = contentType != null ? DbSchemaMapper.getParentFieldName(contentType) : null;
      // Get parent table by removing the last level from content hierarchy
      String? parentTable;
      if (contentType != null) {
        final hierarchyIndex = DbSchemaMapper.hierarchyOrder.indexOf(contentType);
        if (hierarchyIndex > 0) {
          final parentType = DbSchemaMapper.hierarchyOrder[hierarchyIndex - 1];
          parentTable = DbSchemaMapper.getTableName(parentType);
        }
      }

      if (parentField != null && parentTable != null) {
        // Get the item to find its parent
        final item = await _supabase
            .from(tableName)
            .select(parentField)
            .eq(DbColumns.id, id)
            .maybeSingle();

        if (item != null && item[parentField] != null) {
          final parent = await _supabase
              .from(parentTable)
              .select('${DbColumns.id}, ${DbColumns.isDeleted}')
              .eq(DbColumns.id, item[parentField])
              .maybeSingle();

          if (parent == null) {
            throw ParentDeletedException(
              'Cannot restore: Parent does not exist.',
            );
          }

          if (parent['is_deleted'] == true) {
            throw ParentDeletedException(
              'Cannot restore: Parent is deleted. Restore parent first.',
            );
          }
        }
      }

      // Restore the item
      await _supabase.from(tableName).update({
        DbColumns.isDeleted: false,
        DbColumns.deletedAt: null,
        DbColumns.deletedBy: null,
      }).eq(DbColumns.id, id);

      // Un-orphan any references to this content
      try {
        await _supabase.from(DbTables.contentReferences).update({
          'is_orphaned': false,
          'orphaned_at': null,
        }).eq(DbColumns.originalId, id);
      } catch (e) {
        // Ignore if table doesn't exist
      }

      debugPrint('[SoftDelete] Successfully restored: $id');
    } catch (e) {
      debugPrint('[SoftDelete] Restore error: $e');
      rethrow;
    }
  }

  /// Permanently delete item (cannot be recovered)
  /// Optionally deletes associated image from storage
  Future<void> permanentlyDelete({
    required String id,
    required String tableName,
    String? imageIdentifier,
  }) async {
    try {
      debugPrint('[SoftDelete] Permanently deleting $id from $tableName');

      // Delete image from storage if exists
      if (imageIdentifier != null &&
          imageIdentifier.isNotEmpty &&
          _imageService != null) {
        await _imageService.deleteImage(imageIdentifier);
      }

      // Delete any references to this content
      try {
        await _supabase
            .from(DbTables.contentReferences)
            .delete()
            .eq(DbColumns.originalId, id);
      } catch (e) {
        // Ignore if table doesn't exist
      }

      // Permanently delete record
      await _supabase.from(tableName).delete().eq(DbColumns.id, id);

      debugPrint('[SoftDelete] Successfully permanently deleted: $id');
    } catch (e) {
      debugPrint('[SoftDelete] Permanent delete error: $e');
      rethrow;
    }
  }

  /// Get all deleted items from a table
  /// Useful for recycle bin UI
  Future<List<Map<String, dynamic>>> getDeletedItems(
    String tableName, {
    int limit = 100,
  }) async {
    try {
      debugPrint('[SoftDelete] Fetching deleted items from $tableName');

      final response = await _supabase
          .from(tableName)
          .select()
          .eq('is_deleted', true)
          .order('deleted_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('[SoftDelete] Fetch error: $e');
      rethrow;
    }
  }

  /// Get deleted items with days until permanent deletion
  Future<List<Map<String, dynamic>>> getDeletedItemsWithRetention(
    String tableName, {
    int limit = 100,
  }) async {
    final items = await getDeletedItems(tableName, limit: limit);
    
    return items.map((item) {
      final deletedAt = DateTime.tryParse(item['deleted_at'] ?? '');
      int daysRemaining = 30;
      
      if (deletedAt != null) {
        final expiresAt = deletedAt.add(recycleBinRetention);
        daysRemaining = expiresAt.difference(DateTime.now()).inDays;
        if (daysRemaining < 0) daysRemaining = 0;
      }
      
      return {
        ...item,
        'days_until_purge': daysRemaining,
      };
    }).toList();
  }

  /// Get deleted items with user who deleted them
  Future<List<Map<String, dynamic>>> getDeletedItemsWithUser(
    String tableName, {
    int limit = 100,
  }) async {
    try {
      debugPrint(
          '[SoftDelete] Fetching deleted items with user from $tableName');

      // Note: This assumes you have a profiles table with user info
      // Adjust the join query based on your actual schema
      final response = await _supabase
          .from(tableName)
          .select(
            '*, deleted_by_profile:deleted_by(id, email, full_name)',
          )
          .eq('is_deleted', true)
          .order('deleted_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('[SoftDelete] Fetch with user error: $e');
      // Fall back to simple query without user info
      return getDeletedItems(tableName, limit: limit);
    }
  }

  /// Empty recycle bin - permanently delete all soft-deleted items
  /// WARNING: This is irreversible
  Future<int> emptyRecycleBin(String tableName) async {
    try {
      debugPrint('[SoftDelete] Emptying recycle bin for $tableName');

      // Get all deleted items first to check for images
      final deletedItems = await getDeletedItems(tableName, limit: 1000);

      // Delete images for each item
      for (final item in deletedItems) {
        final imageId = item['image_identifier'] ?? item['imageIdentifier'];
        if (imageId != null && _imageService != null) {
          await _imageService.deleteImage(imageId);
        }
      }

      // Permanently delete all soft-deleted records
      await _supabase.from(tableName).delete().eq('is_deleted', true);

      debugPrint('[SoftDelete] Recycle bin emptied for $tableName');
      return deletedItems.length;
    } catch (e) {
      debugPrint('[SoftDelete] Empty recycle bin error: $e');
      rethrow;
    }
  }

  /// Purge items older than retention period
  Future<int> purgeExpiredItems(String tableName) async {
    try {
      final cutoffDate = DateTime.now().subtract(recycleBinRetention);
      
      // Get expired items
      final expiredItems = await _supabase
          .from(tableName)
          .select('id, image_identifier')
          .eq('is_deleted', true)
          .lt('deleted_at', cutoffDate.toIso8601String());

      int deletedCount = 0;
      
      // Delete each expired item
      for (final item in expiredItems) {
        await permanentlyDelete(
          id: item['id'],
          tableName: tableName,
          imageIdentifier: item['image_identifier'],
        );
        deletedCount++;
      }

      debugPrint('[SoftDelete] Purged $deletedCount expired items from $tableName');
      return deletedCount;
    } catch (e) {
      debugPrint('[SoftDelete] Purge error: $e');
      return 0;
    }
  }

  /// Bulk restore multiple items
  Future<void> bulkRestore({
    required List<String> ids,
    required String tableName,
  }) async {
    try {
      for (final id in ids) {
        await restore(id: id, tableName: tableName);
      }
    } catch (e) {
      debugPrint('[SoftDelete] Bulk restore error: $e');
      rethrow;
    }
  }

  /// Bulk permanently delete multiple items
  Future<void> bulkPermanentlyDelete({
    required List<String> ids,
    required String tableName,
  }) async {
    try {
      for (final id in ids) {
        await permanentlyDelete(id: id, tableName: tableName);
      }
    } catch (e) {
      debugPrint('[SoftDelete] Bulk delete error: $e');
      rethrow;
    }
  }
}
