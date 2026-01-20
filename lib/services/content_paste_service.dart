import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/constants/db_constants.dart';
import 'package:zad_aldaia/core/supabase_client.dart';
import 'package:zad_aldaia/services/content_clipboard_service.dart';

/// Paste operation mode
enum PasteMode {
  /// Create an independent copy with new IDs
  clone,

  /// Create a reference to the original content
  reference,

  /// Move content from source to destination
  move,
}

/// Result of a paste operation
class PasteResult {
  final String newId;
  final PasteMode mode;
  final int itemsCreated;

  PasteResult({
    required this.newId,
    required this.mode,
    this.itemsCreated = 1,
  });
}

/// Service for pasting and cloning content
class ContentPasteService {
  SupabaseClient get _supabase => Supa.client;
  final ContentClipboardService _clipboard;

  ContentPasteService(this._clipboard);

  /// Paste content into a new parent location
  ///
  /// [targetParentId] - The ID of the parent container
  /// [targetTableName] - The table to paste into
  /// [mode] - How to paste: clone, reference, or move
  /// [customTitle] - Optional custom title for the pasted content
  Future<PasteResult> paste({
    required String targetParentId,
    required String targetTableName,
    PasteMode mode = PasteMode.clone,
    String? customTitle,
  }) async {
    final content = _clipboard.getCopiedContent();
    if (content == null) {
      throw Exception('Nothing in clipboard to paste');
    }

    try {
      debugPrint(
          '[Paste] Pasting ${content.sourceType} to $targetTableName (mode: $mode)');

      switch (mode) {
        case PasteMode.clone:
          return await _pasteAsClone(
            content: content,
            targetParentId: targetParentId,
            targetTableName: targetTableName,
            customTitle: customTitle,
          );

        case PasteMode.reference:
          return await _pasteAsReference(
            content: content,
            targetParentId: targetParentId,
            targetTableName: targetTableName,
            customTitle: customTitle,
          );

        case PasteMode.move:
          return await _pasteAsMove(
            content: content,
            targetParentId: targetParentId,
            targetTableName: targetTableName,
          );
      }
    } catch (e) {
      debugPrint('[Paste] Error: $e');
      rethrow;
    }
  }

  /// Paste as a clone (independent copy)
  Future<PasteResult> _pasteAsClone({
    required ClipboardContent content,
    required String targetParentId,
    required String targetTableName,
    String? customTitle,
  }) async {
    // Create new data map from clipboard
    final newData = Map<String, dynamic>.from(content.data);

    // Remove old ID so new one is generated
    newData.remove(DbColumns.id);
    
    // Remove metadata fields that are not database columns
    newData.remove('table');

    // Update parent reference
    final parentField = DbSchemaMapper.getParentFieldName(content.sourceType);
    newData[parentField] = targetParentId;

    // Update title if custom title provided, otherwise add "(Copy)" suffix
    final currentTitle = newData[DbColumns.title] ?? newData[DbColumns.name] ?? 'Unnamed';
    newData[DbColumns.title] = customTitle ?? '$currentTitle (Copy)';
    if (newData.containsKey(DbColumns.name)) {
      newData[DbColumns.name] = customTitle ?? '${newData[DbColumns.name]} (Copy)';
    }

    // Reset metadata
    newData[DbColumns.createdAt] = DateTime.now().toIso8601String();
    newData[DbColumns.updatedAt] = DateTime.now().toIso8601String();
    newData[DbColumns.isActive] = true;
    newData[DbColumns.isDeleted] = false;

    // Get next display order
    final orderColumn = DbSchemaMapper.getOrderColumn(targetTableName);
    newData[orderColumn] = await _getNextDisplayOrder(
      targetTableName,
      parentField,
      targetParentId,
    );

    // Insert new record
    final response =
        await _supabase.from(targetTableName).insert(newData).select();

    if (response.isEmpty) {
      throw Exception('Failed to insert pasted content');
    }

    final newId = response.first['id'];
    debugPrint('[Paste] Created clone: $newId');

    int totalItems = 1;

    // Recursively copy children if this is a hierarchical item
    if (DbSchemaMapper.hasChildren(content.sourceType)) {
      totalItems += await _deepCopyChildren(
        sourceId: content.sourceId,
        newParentId: newId,
        sourceType: content.sourceType,
      );
    }

    return PasteResult(
      newId: newId,
      mode: PasteMode.clone,
      itemsCreated: totalItems,
    );
  }

  /// Paste as a reference (pointer to original)
  Future<PasteResult> _pasteAsReference({
    required ClipboardContent content,
    required String targetParentId,
    required String targetTableName,
    String? customTitle,
  }) async {
    // Create reference entry
    final parentField = DbSchemaMapper.getParentFieldName(content.sourceType);
    final displayOrder =
        await _getNextReferenceOrder(targetParentId, targetTableName);

    final refData = {
      DbColumns.originalId: content.sourceId,
      DbColumns.originalTable: DbSchemaMapper.getTableName(content.sourceType),
      DbColumns.parentId: targetParentId,
      DbColumns.parentTable: targetTableName,
      DbColumns.parentField: parentField,
      DbColumns.displayOrder: displayOrder,
      DbColumns.customTitle: customTitle,
      DbColumns.createdBy: Supa.currentUser?.id,
      DbColumns.createdAt: DateTime.now().toIso8601String(),
    };

    final response =
        await _supabase.from(DbTables.contentReferences).insert(refData).select();

    if (response.isEmpty) {
      throw Exception('Failed to create reference');
    }

    final refId = response.first[DbColumns.id];
    debugPrint('[Paste] Created reference: $refId');

    return PasteResult(
      newId: refId,
      mode: PasteMode.reference,
      itemsCreated: 1,
    );
  }

  /// Paste as move (remove from source, add to destination)
  Future<PasteResult> _pasteAsMove({
    required ClipboardContent content,
    required String targetParentId,
    required String targetTableName,
  }) async {
    final parentField = DbSchemaMapper.getParentFieldName(content.sourceType);
    final tableName = DbSchemaMapper.getTableName(content.sourceType);
    final orderColumn = DbSchemaMapper.getOrderColumn(tableName);

    // Get next display order in target
    final newOrder = await _getNextDisplayOrder(
      tableName,
      parentField,
      targetParentId,
    );

    // Update the record to point to new parent
    await _supabase.from(tableName).update({
      parentField: targetParentId,
      orderColumn: newOrder,
      DbColumns.updatedAt: DateTime.now().toIso8601String(),
    }).eq(DbColumns.id, content.sourceId);

    debugPrint('[Paste] Moved ${content.sourceId} to new parent');

    // Clear clipboard since content was moved
    _clipboard.clear();

    return PasteResult(
      newId: content.sourceId,
      mode: PasteMode.move,
      itemsCreated: 0, // Not created, just moved
    );
  }

  /// Recursively copy all children of an item
  Future<int> _deepCopyChildren({
    required String sourceId,
    required String newParentId,
    required String sourceType,
  }) async {
    final childTableName = DbSchemaMapper.getChildTableName(sourceType);
    if (childTableName == null) return 0;

    debugPrint('[Paste] Deep copying children: $sourceType -> $childTableName');

    try {
      final parentField = DbSchemaMapper.getParentFieldName(sourceType);

      // Fetch all children of the source (excluding deleted)
      final children = await _supabase
          .from(childTableName)
          .select()
          .eq(parentField, sourceId)
          .eq(DbColumns.isDeleted, false);

      debugPrint('[Paste] Found ${children.length} children to copy');

      int totalCopied = 0;

      // Copy each child recursively
      for (int i = 0; i < children.length; i++) {
        final child = children[i];
        final childData = Map<String, dynamic>.from(child);
        childData.remove(DbColumns.id);
        childData[parentField] = newParentId;

        // Update metadata
        childData[DbColumns.createdAt] = DateTime.now().toIso8601String();
        childData[DbColumns.updatedAt] = DateTime.now().toIso8601String();
        childData[DbColumns.isDeleted] = false;

        // Set order based on position
        final orderColumn = DbSchemaMapper.getOrderColumn(childTableName);
        childData[orderColumn] = i;

        // Insert child
        final response =
            await _supabase.from(childTableName).insert(childData).select();

        if (response.isNotEmpty) {
          totalCopied++;
          final newChildId = response.first[DbColumns.id];

          // Determine child's source type for recursion
          final childSourceType = DbSchemaMapper.getContentType(childTableName);
          if (childSourceType != null) {
            totalCopied += await _deepCopyChildren(
              sourceId: child[DbColumns.id],
              newParentId: newChildId,
              sourceType: childSourceType,
            );
          }
        }
      }

      return totalCopied;
    } catch (e) {
      debugPrint('[Paste] Deep copy error: $e');
      return 0;
    }
  }

  // Note: All mapping methods have been moved to DbSchemaMapper in db_constants.dart
  // to maintain consistency and prevent typos across the codebase.

  /// Get next display order for a new item
  Future<int> _getNextDisplayOrder(
    String tableName,
    String parentField,
    String parentId,
  ) async {
    try {
      final orderColumn = DbSchemaMapper.getOrderColumn(tableName);
      final result = await _supabase
          .from(tableName)
          .select(orderColumn)
          .eq(parentField, parentId)
          .order(orderColumn, ascending: false)
          .limit(1);

      if (result.isEmpty) return 0;
      return (result.first[orderColumn] ?? -1) + 1;
    } catch (e) {
      return 0;
    }
  }

  /// Get next display order for a reference
  Future<int> _getNextReferenceOrder(
      String parentId, String parentTable) async {
    try {
      final result = await _supabase
          .from(DbTables.contentReferences)
          .select(DbColumns.displayOrder)
          .eq(DbColumns.parentId, parentId)
          .eq(DbColumns.parentTable, parentTable)
          .order(DbColumns.displayOrder, ascending: false)
          .limit(1);

      if (result.isEmpty) return 0;
      return (result.first[DbColumns.displayOrder] ?? -1) + 1;
    } catch (e) {
      return 0;
    }
  }
}
