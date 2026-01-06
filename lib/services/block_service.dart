import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/supabase_client.dart';

/// Model class for BlockedUser data
class BlockedUser {
  final String id;
  final String blockerId;
  final String blockedId;
  final DateTime createdAt;
  final String? blockedUserDisplayName;
  final String? blockedUserAvatarUrl;

  BlockedUser({
    required this.id,
    required this.blockerId,
    required this.blockedId,
    required this.createdAt,
    this.blockedUserDisplayName,
    this.blockedUserAvatarUrl,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      id: json['id'] as String,
      blockerId: json['blocker_id'] as String,
      blockedId: json['blocked_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      blockedUserDisplayName: json['blocked_user_display_name'] as String? ??
          (json['profiles'] != null
              ? json['profiles']['display_name'] as String?
              : null),
      blockedUserAvatarUrl: json['blocked_user_avatar_url'] as String? ??
          (json['profiles'] != null
              ? json['profiles']['avatar_url'] as String?
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'blocker_id': blockerId,
      'blocked_id': blockedId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Service for managing blocked users
/// Handles blocking/unblocking functionality
class BlockService {
  /// Table name constant
  static const String _tableName = 'blocked_users';

  /// Local cache of blocked user IDs for quick lookup
  Set<String> _blockedUserIds = {};

  /// Whether the cache has been initialized
  bool _cacheInitialized = false;

  /// Block a user
  /// Prevents seeing their posts and interactions
  Future<void> blockUser(String userId) async {
    final currentUser = Supa.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to block someone');
    }

    if (userId == currentUser.id) {
      throw Exception('You cannot block yourself');
    }

    try {
      await Supa.client.from(_tableName).insert({
        'blocker_id': currentUser.id,
        'blocked_id': userId,
      });

      // Update local cache
      _blockedUserIds.add(userId);
    } on PostgrestException catch (e) {
      // Handle duplicate block attempt gracefully
      if (e.code == '23505') {
        // Unique constraint violation
        throw Exception('User is already blocked');
      }
      throw Exception('Failed to block user: ${e.message}');
    } catch (e) {
      throw Exception('Failed to block user: $e');
    }
  }

  /// Unblock a user
  /// Allows seeing their posts again
  Future<void> unblockUser(String userId) async {
    final currentUser = Supa.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to unblock someone');
    }

    try {
      await Supa.client
          .from(_tableName)
          .delete()
          .eq('blocker_id', currentUser.id)
          .eq('blocked_id', userId);

      // Update local cache
      _blockedUserIds.remove(userId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to unblock user: ${e.message}');
    } catch (e) {
      throw Exception('Failed to unblock user: $e');
    }
  }

  /// Get all blocked users for current user
  /// Returns list with user profile information
  Future<List<BlockedUser>> getBlockedUsers() async {
    final currentUser = Supa.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to view blocked users');
    }

    try {
      final response = await Supa.client
          .from(_tableName)
          .select('''
            *,
            profiles:blocked_id (
              display_name,
              avatar_url
            )
          ''')
          .eq('blocker_id', currentUser.id)
          .order('created_at', ascending: false);

      final blockedUsers = (response as List)
          .map((json) => BlockedUser.fromJson(json as Map<String, dynamic>))
          .toList();

      // Update cache
      _blockedUserIds = blockedUsers.map((u) => u.blockedId).toSet();
      _cacheInitialized = true;

      return blockedUsers;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch blocked users: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch blocked users: $e');
    }
  }

  /// Check if a specific user is blocked
  /// Uses local cache for quick lookup after first fetch
  Future<bool> isBlocked(String userId) async {
    // If cache is initialized, use it for quick lookup
    if (_cacheInitialized) {
      return _blockedUserIds.contains(userId);
    }

    final currentUser = Supa.currentUser;
    if (currentUser == null) {
      return false;
    }

    try {
      final response = await Supa.client
          .from(_tableName)
          .select('id')
          .eq('blocker_id', currentUser.id)
          .eq('blocked_id', userId)
          .maybeSingle();

      return response != null;
    } on PostgrestException {
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if a user is blocked (synchronous, uses cache)
  /// Returns false if cache is not initialized
  bool isBlockedSync(String userId) {
    return _blockedUserIds.contains(userId);
  }

  /// Initialize the blocked users cache
  /// Call this on app startup or after login
  Future<void> initializeCache() async {
    final currentUser = Supa.currentUser;
    if (currentUser == null) {
      _blockedUserIds = {};
      _cacheInitialized = false;
      return;
    }

    try {
      final response = await Supa.client
          .from(_tableName)
          .select('blocked_id')
          .eq('blocker_id', currentUser.id);

      _blockedUserIds = (response as List)
          .map((json) => json['blocked_id'] as String)
          .toSet();
      _cacheInitialized = true;
    } catch (e) {
      // Fail silently, will retry on next check
      _blockedUserIds = {};
      _cacheInitialized = false;
    }
  }

  /// Clear the cache (call on logout)
  void clearCache() {
    _blockedUserIds = {};
    _cacheInitialized = false;
  }

  /// Get the count of blocked users
  Future<int> getBlockedCount() async {
    final currentUser = Supa.currentUser;
    if (currentUser == null) {
      return 0;
    }

    try {
      final response = await Supa.client
          .from(_tableName)
          .select('id')
          .eq('blocker_id', currentUser.id)
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      return 0;
    }
  }

  /// Stream of blocked users for real-time updates
  Stream<List<BlockedUser>> getBlockedUsersStream() {
    final currentUser = Supa.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return Supa.client
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('blocker_id', currentUser.id)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => BlockedUser.fromJson(json)).toList());
  }
}
