import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/supabase_client.dart';

/// Represents a content reference (a pointer to original content)
class ContentReference {
  final String id;
  final String originalId;
  final String originalTable;
  final String parentId;
  final String parentTable;
  final String parentField;
  final int displayOrder;
  final String? customTitle;
  final DateTime createdAt;
  final String? createdBy;
  final bool isDeleted;
  final bool isOrphaned;
  
  // Resolved at runtime - not stored in DB
  Map<String, dynamic>? resolvedContent;
  String? originalPath;

  ContentReference({
    required this.id,
    required this.originalId,
    required this.originalTable,
    required this.parentId,
    required this.parentTable,
    required this.parentField,
    this.displayOrder = 0,
    this.customTitle,
    required this.createdAt,
    this.createdBy,
    this.isDeleted = false,
    this.isOrphaned = false,
    this.resolvedContent,
    this.originalPath,
  });

  factory ContentReference.fromJson(Map<String, dynamic> json) {
    return ContentReference(
      id: json['id'] ?? '',
      originalId: json['original_id'] ?? '',
      originalTable: json['original_table'] ?? '',
      parentId: json['parent_id'] ?? '',
      parentTable: json['parent_table'] ?? '',
      parentField: json['parent_field'] ?? '',
      displayOrder: json['display_order'] ?? 0,
      customTitle: json['custom_title'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      createdBy: json['created_by'],
      isDeleted: json['is_deleted'] ?? false,
      isOrphaned: json['is_orphaned'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'original_id': originalId,
      'original_table': originalTable,
      'parent_id': parentId,
      'parent_table': parentTable,
      'parent_field': parentField,
      'display_order': displayOrder,
      'custom_title': customTitle,
      'created_by': createdBy,
    };
  }

  /// Check if this reference points to valid content
  bool get isValid => !isOrphaned && !isDeleted && resolvedContent != null;
  
  /// Get display title (custom or from original)
  String get displayTitle {
    if (customTitle != null && customTitle!.isNotEmpty) {
      return customTitle!;
    }
    if (resolvedContent != null) {
      return resolvedContent!['title'] ?? resolvedContent!['name'] ?? 'Untitled';
    }
    return 'Reference';
  }
}

/// Exception thrown when trying to delete content that has references
class ContentHasReferencesException implements Exception {
  final String message;
  final List<ContentReference> references;
  
  ContentHasReferencesException({
    required this.message,
    required this.references,
  });
  
  @override
  String toString() => message;
}

/// Service for managing content references
/// 
/// References are pointers to original content. When content appears in
/// multiple places, only one instance exists as the "original" and all
/// other appearances are references that point to it.
/// 
/// Key behaviors:
/// - Updates to original content automatically reflect in all references
/// - References can have custom display titles
/// - Deleting original content is blocked if references exist (or orphans them)
/// - Moving original content doesn't break references (they point to ID)
class ReferenceService {
  SupabaseClient get _supabase => Supa.client;

  /// Create a reference to existing content
  Future<ContentReference> createReference({
    required String originalId,
    required String originalTable,
    required String parentId,
    required String parentTable,
    required String parentField,
    String? customTitle,
    int? displayOrder,
  }) async {
    try {
      debugPrint('[Reference] Creating reference to $originalId in $originalTable');
      
      // Verify original content exists
      final original = await _supabase
          .from(originalTable)
          .select('id')
          .eq('id', originalId)
          .maybeSingle();
      
      if (original == null) {
        throw Exception('Original content not found');
      }
      
      // Calculate display order if not provided
      final order = displayOrder ?? await _getNextDisplayOrder(parentId, parentTable);
      
      // Create the reference
      final data = {
        'original_id': originalId,
        'original_table': originalTable,
        'parent_id': parentId,
        'parent_table': parentTable,
        'parent_field': parentField,
        'display_order': order,
        'custom_title': customTitle,
        'created_by': Supa.currentUser?.id,
      };
      
      final response = await _supabase
          .from('content_references')
          .insert(data)
          .select()
          .single();
      
      debugPrint('[Reference] Created reference: ${response['id']}');
      return ContentReference.fromJson(response);
    } catch (e) {
      debugPrint('[Reference] Create error: $e');
      rethrow;
    }
  }

  /// Resolve a reference to get the original content
  Future<Map<String, dynamic>?> resolveReference(ContentReference ref) async {
    try {
      if (ref.isOrphaned) {
        debugPrint('[Reference] Reference ${ref.id} is orphaned');
        return null;
      }
      
      final content = await _supabase
          .from(ref.originalTable)
          .select()
          .eq('id', ref.originalId)
          .maybeSingle();
      
      if (content == null || content['is_deleted'] == true) {
        debugPrint('[Reference] Original content not found or deleted');
        return null;
      }
      
      return content;
    } catch (e) {
      debugPrint('[Reference] Resolve error: $e');
      return null;
    }
  }

  /// Get all references pointing to a specific content
  Future<List<ContentReference>> getReferencesTo(String contentId) async {
    try {
      final refs = await _supabase
          .from('content_references')
          .select()
          .eq('original_id', contentId)
          .eq('is_deleted', false);
      
      return (refs as List)
          .map((r) => ContentReference.fromJson(r))
          .toList();
    } catch (e) {
      debugPrint('[Reference] Get references error: $e');
      return [];
    }
  }

  /// Get all references under a parent (e.g., all references in an article)
  Future<List<ContentReference>> getReferencesIn({
    required String parentId,
    required String parentTable,
  }) async {
    try {
      final refs = await _supabase
          .from('content_references')
          .select()
          .eq('parent_id', parentId)
          .eq('parent_table', parentTable)
          .eq('is_deleted', false)
          .order('display_order');
      
      return (refs as List)
          .map((r) => ContentReference.fromJson(r))
          .toList();
    } catch (e) {
      debugPrint('[Reference] Get references in error: $e');
      return [];
    }
  }

  /// Check if content has any references
  Future<bool> hasReferences(String contentId) async {
    try {
      final refs = await _supabase
          .from('content_references')
          .select('id')
          .eq('original_id', contentId)
          .eq('is_deleted', false)
          .limit(1);
      
      return (refs as List).isNotEmpty;
    } catch (e) {
      debugPrint('[Reference] Has references error: $e');
      return false;
    }
  }

  /// Delete a reference (not the original content)
  Future<void> deleteReference(String referenceId) async {
    try {
      debugPrint('[Reference] Deleting reference $referenceId');
      
      await _supabase
          .from('content_references')
          .update({
            'is_deleted': true,
            'deleted_at': DateTime.now().toIso8601String(),
            'deleted_by': Supa.currentUser?.id,
          })
          .eq('id', referenceId);
      
      debugPrint('[Reference] Reference deleted');
    } catch (e) {
      debugPrint('[Reference] Delete error: $e');
      rethrow;
    }
  }

  /// Update a reference's custom title
  Future<void> updateReferenceTitle(String referenceId, String? title) async {
    try {
      await _supabase
          .from('content_references')
          .update({
            'custom_title': title,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', referenceId);
    } catch (e) {
      debugPrint('[Reference] Update title error: $e');
      rethrow;
    }
  }

  /// Check if content can be deleted (no references)
  /// Throws ContentHasReferencesException if references exist
  Future<void> validateDeletion(String contentId) async {
    final refs = await getReferencesTo(contentId);
    
    if (refs.isNotEmpty) {
      throw ContentHasReferencesException(
        message: 'Cannot delete: This content is referenced in ${refs.length} location(s).',
        references: refs,
      );
    }
  }

  /// Build the navigation path to original content
  Future<String> getOriginalPath(ContentReference ref) async {
    try {
      // Build path based on table hierarchy
      switch (ref.originalTable) {
        case 'articles':
          return await _buildArticlePath(ref.originalId);
        case 'article_items':
          return await _buildArticleItemPath(ref.originalId);
        case 'content_items':
          return await _buildContentItemPath(ref.originalId);
        case 'topics':
          return await _buildTopicPath(ref.originalId);
        case 'branches':
          return await _buildBranchPath(ref.originalId);
        case 'sections':
          return await _buildSectionPath(ref.originalId);
        case 'paths':
          return await _buildPathPath(ref.originalId);
        default:
          return '';
      }
    } catch (e) {
      debugPrint('[Reference] Get path error: $e');
      return '';
    }
  }

  Future<String> _buildArticlePath(String articleId) async {
    final article = await _supabase
        .from('articles')
        .select('category_id')
        .eq('id', articleId)
        .maybeSingle();
    
    if (article == null) return '';
    
    // Return route path for navigation
    return '/items?id=$articleId';
  }

  Future<String> _buildArticleItemPath(String itemId) async {
    final item = await _supabase
        .from('article_items')
        .select('article_id')
        .eq('id', itemId)
        .maybeSingle();
    
    if (item == null) return '';
    
    return '/items?id=${item['article_id']}&scrollTo=$itemId';
  }

  Future<String> _buildContentItemPath(String itemId) async {
    final item = await _supabase
        .from('content_items')
        .select('topic_id')
        .eq('id', itemId)
        .maybeSingle();
    
    if (item == null) return '';
    
    return '/content?topicId=${item['topic_id']}&scrollTo=$itemId';
  }

  Future<String> _buildTopicPath(String topicId) async {
    return '/content?topicId=$topicId';
  }

  Future<String> _buildBranchPath(String branchId) async {
    return '/topics?branchId=$branchId';
  }

  Future<String> _buildSectionPath(String sectionId) async {
    return '/branches?sectionId=$sectionId';
  }

  Future<String> _buildPathPath(String pathId) async {
    return '/sections?pathId=$pathId';
  }

  Future<int> _getNextDisplayOrder(String parentId, String parentTable) async {
    try {
      final result = await _supabase
          .from('content_references')
          .select('display_order')
          .eq('parent_id', parentId)
          .eq('parent_table', parentTable)
          .order('display_order', ascending: false)
          .limit(1);
      
      if (result.isEmpty) return 0;
      return (result.first['display_order'] ?? -1) + 1;
    } catch (e) {
      return 0;
    }
  }
}
