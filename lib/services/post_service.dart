import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/supabase_client.dart';
import 'package:zad_aldaia/services/bad_words.dart';

/// Model class for Post data
class Post {
  final String id;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final String? authorDisplayName;
  final String? authorAvatarUrl;

  Post({
    required this.id,
    required this.authorId,
    required this.content,
    required this.createdAt,
    this.authorDisplayName,
    this.authorAvatarUrl,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorDisplayName: json['author_display_name'] as String? ??
          (json['profiles'] != null
              ? json['profiles']['display_name'] as String?
              : null),
      authorAvatarUrl: json['author_avatar_url'] as String? ??
          (json['profiles'] != null
              ? json['profiles']['avatar_url'] as String?
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_id': authorId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Copy with method for immutability
  Post copyWith({
    String? id,
    String? authorId,
    String? content,
    DateTime? createdAt,
    String? authorDisplayName,
    String? authorAvatarUrl,
  }) {
    return Post(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      authorDisplayName: authorDisplayName ?? this.authorDisplayName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
    );
  }
}

/// Service for managing posts
/// Handles CRUD operations for posts with bad words filtering
class PostService {
  /// Table name constant
  static const String _tableName = 'posts';

  /// Create a new post
  /// Automatically filters bad words from content
  /// Returns the created Post
  Future<Post> createPost(String content) async {
    final user = Supa.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to create a post');
    }

    // Filter bad words before inserting
    final filteredContent = BadWordsFilter.filterBadWords(content.trim());

    if (filteredContent.isEmpty) {
      throw Exception('Post content cannot be empty');
    }

    try {
      final response = await Supa.client
          .from(_tableName)
          .insert({
            'author_id': user.id,
            'content': filteredContent,
          })
          .select()
          .single();

      return Post.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to create post: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  /// Get all posts ordered by created_at DESC
  /// Automatically excludes posts from blocked users (handled by RLS)
  /// Returns a list of Posts with author information
  Future<List<Post>> getPosts() async {
    try {
      final response = await Supa.client.from(_tableName).select('''
            *,
            profiles:author_id (
              display_name,
              avatar_url
            )
          ''').order('created_at', ascending: false);

      return (response as List)
          .map((json) => Post.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch posts: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch posts: $e');
    }
  }

  /// Get posts as a stream for real-time updates
  /// Useful for live feed functionality
  Stream<List<Post>> getPostsStream() {
    return Supa.client
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Post.fromJson(json)).toList());
  }

  /// Get a single post by ID
  Future<Post?> getPostById(String id) async {
    try {
      final response = await Supa.client.from(_tableName).select('''
            *,
            profiles:author_id (
              display_name,
              avatar_url
            )
          ''').eq('id', id).maybeSingle();

      if (response == null) return null;
      return Post.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch post: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch post: $e');
    }
  }

  /// Get posts by a specific user
  Future<List<Post>> getPostsByUser(String userId) async {
    try {
      final response = await Supa.client.from(_tableName).select('''
            *,
            profiles:author_id (
              display_name,
              avatar_url
            )
          ''').eq('author_id', userId).order('created_at', ascending: false);

      return (response as List)
          .map((json) => Post.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch user posts: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch user posts: $e');
    }
  }

  /// Delete a post by ID
  /// Only the author can delete their own posts (enforced by RLS)
  Future<void> deletePost(String id) async {
    final user = Supa.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to delete a post');
    }

    try {
      await Supa.client.from(_tableName).delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete post: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  /// Update a post's content
  /// Only the author can update their own posts (enforced by RLS)
  Future<Post> updatePost(String id, String newContent) async {
    final user = Supa.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to update a post');
    }

    // Filter bad words
    final filteredContent = BadWordsFilter.filterBadWords(newContent.trim());

    if (filteredContent.isEmpty) {
      throw Exception('Post content cannot be empty');
    }

    try {
      final response = await Supa.client
          .from(_tableName)
          .update({'content': filteredContent})
          .eq('id', id)
          .select()
          .single();

      return Post.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update post: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update post: $e');
    }
  }

  /// Check if current user is the author of a post
  bool isAuthor(Post post) {
    final user = Supa.currentUser;
    if (user == null) return false;
    return post.authorId == user.id;
  }

  /// Get paginated posts
  /// Useful for infinite scroll implementations
  Future<List<Post>> getPostsPaginated({
    required int page,
    int limit = 20,
  }) async {
    final offset = (page - 1) * limit;

    try {
      final response = await Supa.client
          .from(_tableName)
          .select('''
            *,
            profiles:author_id (
              display_name,
              avatar_url
            )
          ''')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => Post.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch posts: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch posts: $e');
    }
  }
}
