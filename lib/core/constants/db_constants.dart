/// Database schema constants for Supabase
/// This file contains all table names, column names, and content types
/// to prevent typos and maintain consistency across the codebase.

/// Database table names
class DbTables {
  // Content hierarchy tables
  static const String languages = 'languages';
  static const String paths = 'paths';
  static const String sections = 'sections';
  static const String branches = 'branches';
  static const String topics = 'topics';
  static const String contentItems = 'content_items';

  // Article-based content tables
  static const String articles = 'articles';
  static const String articleItems = 'article_items';

  // Admin and system tables
  static const String contentReferences = 'content_references';
  static const String recycleBin = 'recycle_bin';

  // Social tables
  static const String profiles = 'profiles';
  static const String posts = 'posts';
  static const String blockedUsers = 'blocked_users';

  // Storage bucket name
  static const String storageBucket = 'content-images';
}

/// Database column names (common across tables)
class DbColumns {
  // Primary and foreign keys
  static const String id = 'id';
  static const String languageId = 'language_id';
  static const String pathId = 'path_id';
  static const String sectionId = 'section_id';
  static const String branchId = 'branch_id';
  static const String topicId = 'topic_id';
  static const String categoryId = 'category_id';
  static const String articleId = 'article_id';
  static const String parentId = 'parent_id';

  // Common fields
  static const String title = 'title';
  static const String name = 'name';
  static const String description = 'description';
  static const String content = 'content';
  static const String type = 'type';
  
  // Display and ordering
  static const String displayOrder = 'display_order';
  static const String order = 'order'; // For article_items (legacy)
  
  // Image and media fields
  static const String imageUrl = 'image_url';
  static const String image = 'image';
  static const String imageIdentifier = 'image_identifier';
  static const String mediaUrl = 'media_url';
  static const String thumbnailUrl = 'thumbnail_url';
  static const String youtubeUrl = 'youtube_url';
  
  // Status and metadata
  static const String isActive = 'is_active';
  static const String isDeleted = 'is_deleted';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String deletedAt = 'deleted_at';
  static const String deletedBy = 'deleted_by';
  
  // Article item specific
  static const String note = 'note';
  static const String backgroundColor = 'background_color';
  
  // Language specific
  static const String code = 'code';
  static const String flagUrl = 'flag_url';
  
  // Reference specific
  static const String originalId = 'original_id';
  static const String originalTable = 'original_table';
  static const String parentTable = 'parent_table';
  static const String parentField = 'parent_field';
  static const String customTitle = 'custom_title';
  static const String createdBy = 'created_by';
  
  // Content item specific
  static const String duration = 'duration';
  static const String fileSize = 'file_size';
  static const String metadata = 'metadata';
  
  // Recycle bin specific
  static const String originalTitle = 'original_title';
  static const String itemType = 'item_type';
}

/// Content types used in the app
class ContentTypes {
  // Content hierarchy types
  static const String language = 'language';
  static const String languages = 'languages';
  static const String path = 'path';
  static const String paths = 'paths';
  static const String section = 'section';
  static const String sections = 'sections';
  static const String branch = 'branch';
  static const String branches = 'branches';
  static const String topic = 'topic';
  static const String topics = 'topics';
  static const String contentItem = 'content_item';
  static const String contentItems = 'content_items';

  // Article types
  static const String article = 'article';
  static const String articles = 'articles';
  static const String item = 'item';
  static const String articleItems = 'article_items';

  // Media content types
  static const String text = 'text';
  static const String image = 'image';
  static const String video = 'video';
  static const String audio = 'audio';
  static const String pdf = 'pdf';
}

/// Helper class to map between content types and table names
class DbSchemaMapper {
  /// Get table name for a content type
  static String getTableName(String contentType) {
    return {
      ContentTypes.language: DbTables.languages,
      ContentTypes.languages: DbTables.languages,
      ContentTypes.path: DbTables.paths,
      ContentTypes.paths: DbTables.paths,
      ContentTypes.section: DbTables.sections,
      ContentTypes.sections: DbTables.sections,
      ContentTypes.branch: DbTables.branches,
      ContentTypes.branches: DbTables.branches,
      ContentTypes.topic: DbTables.topics,
      ContentTypes.topics: DbTables.topics,
      ContentTypes.contentItem: DbTables.contentItems,
      ContentTypes.contentItems: DbTables.contentItems,
      ContentTypes.article: DbTables.articles,
      ContentTypes.articles: DbTables.articles,
      ContentTypes.item: DbTables.articleItems,
      ContentTypes.articleItems: DbTables.articleItems,
    }[contentType] ?? contentType;
  }

  /// Get parent field name for a content type
  static String getParentFieldName(String contentType) {
    return {
      ContentTypes.language: DbColumns.languageId,
      ContentTypes.languages: DbColumns.languageId,
      ContentTypes.path: DbColumns.pathId,
      ContentTypes.paths: DbColumns.pathId,
      ContentTypes.section: DbColumns.sectionId,
      ContentTypes.sections: DbColumns.sectionId,
      ContentTypes.branch: DbColumns.branchId,
      ContentTypes.branches: DbColumns.branchId,
      ContentTypes.topic: DbColumns.topicId,
      ContentTypes.topics: DbColumns.topicId,
      ContentTypes.article: DbColumns.categoryId,
      ContentTypes.articles: DbColumns.categoryId,
      ContentTypes.item: DbColumns.articleId,
      ContentTypes.articleItems: DbColumns.articleId,
      ContentTypes.contentItem: DbColumns.topicId,
      ContentTypes.contentItems: DbColumns.topicId,
    }[contentType] ?? DbColumns.parentId;
  }

  /// Get child table name for a content type
  static String? getChildTableName(String contentType) {
    return {
      ContentTypes.language: DbTables.paths,
      ContentTypes.path: DbTables.sections,
      ContentTypes.section: DbTables.branches,
      ContentTypes.branch: DbTables.topics,
      ContentTypes.topic: DbTables.contentItems,
      ContentTypes.article: DbTables.articleItems,
    }[contentType];
  }

  /// Get content type from table name
  static String? getContentType(String tableName) {
    return {
      DbTables.languages: ContentTypes.language,
      DbTables.paths: ContentTypes.path,
      DbTables.sections: ContentTypes.section,
      DbTables.branches: ContentTypes.branch,
      DbTables.topics: ContentTypes.topic,
      DbTables.contentItems: ContentTypes.contentItem,
      DbTables.articles: ContentTypes.article,
      DbTables.articleItems: ContentTypes.item,
    }[tableName];
  }

  /// Get order column name for a table
  static String getOrderColumn(String tableName) {
    // article_items uses 'order', others use 'display_order'
    return tableName == DbTables.articleItems
        ? DbColumns.order
        : DbColumns.displayOrder;
  }

  /// Check if content type has children
  static bool hasChildren(String contentType) {
    return getChildTableName(contentType) != null;
  }

  /// Get all hierarchical content types in order
  static List<String> get hierarchyOrder => [
    ContentTypes.language,
    ContentTypes.path,
    ContentTypes.section,
    ContentTypes.branch,
    ContentTypes.topic,
    ContentTypes.contentItem,
  ];

  /// Get all article-based content types
  static List<String> get articleTypes => [
    ContentTypes.article,
    ContentTypes.item,
  ];
}
