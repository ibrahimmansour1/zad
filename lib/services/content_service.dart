import 'package:zad_aldaia/core/supabase_client.dart';

/// Service for managing hierarchical content data
/// Handles: Languages → Paths → Sections → Branches → Topics → Content Items
class ContentService {
  /// Fetch all languages
  /// Returns list of language records ordered by created_at (newest first)
  Future<List<Map<String, dynamic>>> getLanguages() async {
    try {
      final response = await Supa.client
          .from('languages')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Failed to fetch languages: $e');
    }
  }

  /// Fetch all paths for a specific language
  Future<List<Map<String, dynamic>>> getPaths(String languageId) async {
    try {
      final response = await Supa.client
          .from('paths')
          .select()
          .eq('language_id', languageId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Failed to fetch paths: $e');
    }
  }

  /// Fetch all sections for a specific path
  Future<List<Map<String, dynamic>>> getSections(String pathId) async {
    try {
      final response = await Supa.client
          .from('sections')
          .select()
          .eq('path_id', pathId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Failed to fetch sections: $e');
    }
  }

  /// Fetch all branches for a specific section
  Future<List<Map<String, dynamic>>> getBranches(String sectionId) async {
    try {
      final response = await Supa.client
          .from('branches')
          .select()
          .eq('section_id', sectionId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Failed to fetch branches: $e');
    }
  }

  /// Fetch all topics for a specific branch
  Future<List<Map<String, dynamic>>> getTopics(String branchId) async {
    try {
      final response = await Supa.client
          .from('topics')
          .select()
          .eq('branch_id', branchId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Failed to fetch topics: $e');
    }
  }

  /// Fetch all content items for a specific topic
  Future<List<Map<String, dynamic>>> getContentItems(String topicId) async {
    try {
      final response = await Supa.client
          .from('content_items')
          .select()
          .eq('topic_id', topicId)
          .order('display_order', ascending: true);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Failed to fetch content items: $e');
    }
  }

  /// Create a new topic
  Future<Map<String, dynamic>> createTopic(Map<String, dynamic> data) async {
    try {
      final response =
          await Supa.client.from('topics').insert(data).select().single();

      return response;
    } catch (e) {
      throw Exception('Failed to create topic: $e');
    }
  }

  /// Create a new content item
  Future<Map<String, dynamic>> createContentItem(
      Map<String, dynamic> data) async {
    try {
      final response = await Supa.client
          .from('content_items')
          .insert(data)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to create content item: $e');
    }
  }

  /// Update a topic
  Future<void> updateTopic(String topicId, Map<String, dynamic> data) async {
    try {
      await Supa.client.from('topics').update(data).eq('id', topicId);
    } catch (e) {
      throw Exception('Failed to update topic: $e');
    }
  }

  /// Update a content item
  Future<void> updateContentItem(
      String contentItemId, Map<String, dynamic> data) async {
    try {
      await Supa.client
          .from('content_items')
          .update(data)
          .eq('id', contentItemId);
    } catch (e) {
      throw Exception('Failed to update content item: $e');
    }
  }

  /// Delete a topic
  Future<void> deleteTopic(String topicId) async {
    try {
      await Supa.client.from('topics').delete().eq('id', topicId);
    } catch (e) {
      throw Exception('Failed to delete topic: $e');
    }
  }

  /// Delete a content item
  Future<void> deleteContentItem(String contentItemId) async {
    try {
      await Supa.client.from('content_items').delete().eq('id', contentItemId);
    } catch (e) {
      throw Exception('Failed to delete content item: $e');
    }
  }
}
