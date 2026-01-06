class Article {
  String id;
  String? categoryId;
  String? title;
  // final String? section;
  // final String? article;
  // final String? language;
  // final DateTime? createdAt;

  bool isOffline = false;

  Article(
      {required this.id, this.title, this.categoryId, this.isOffline = false});

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] ?? '',
      title: json['title'],
      categoryId: json['category_id'],
      // article: json['article'] ?? '',
      // language: json['lang'] ?? '',
      // createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFormJson() {
    return {'title': title, 'category_id': categoryId};
  }

  // Map<String, dynamic> toJson() {
  //   return {'id': id, 'title': title, 'section': section, 'article': article, 'lang': language, 'created_at': createdAt.toIso8601String()};
  // }
}
