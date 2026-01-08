class Article {
  String id;
  String? categoryId;
  String? title;
  int displayOrder;
  bool isActive;
  bool isDeleted;

  bool isOffline = false;
  
  // Content statistics
  int textCount = 0;
  int imageCount = 0;
  int videoCount = 0;
  
  int get totalCount => textCount + imageCount + videoCount;

  Article({
    required this.id,
    this.title,
    this.categoryId,
    this.displayOrder = 0,
    this.isActive = true,
    this.isDeleted = false,
    this.isOffline = false,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] ?? '',
      title: json['title'],
      categoryId: json['category_id'],
      displayOrder: json['display_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      isDeleted: json['is_deleted'] ?? false,
    );
  }

  Map<String, dynamic> toFormJson() {
    return {
      'title': title,
      'category_id': categoryId,
      'display_order': displayOrder,
      'is_active': isActive,
    };
  }

  Article copyWith({
    String? id,
    String? title,
    String? categoryId,
    int? displayOrder,
    bool? isActive,
    bool? isDeleted,
    bool? isOffline,
  }) {
    return Article(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}
