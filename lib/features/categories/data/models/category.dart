class Countable {
  final int count;

  Countable({required this.count});
}

class Category {
  String id;
  String? parentId;
  bool isActive;
  int? order;
  String? title;
  String? image;
  String? imageIdentifier;
  String? lang;
  DateTime? createdAt;
  bool get hasChildren => childrenCount > 0;
  String? section;

  int get childrenCount => categories != null && categories!.isNotEmpty
      ? categories!.first.count
      : 0;
  int get articlesCount =>
      articles != null && articles!.isNotEmpty ? articles!.first.count : 0;

  List<Countable>? articles;
  List<Countable>? categories;

  bool isOffline = false;

  Category({
    required this.id,
    this.parentId,
    this.title,
    this.image,
    this.imageIdentifier,
    this.isActive = true,
    this.section = "",
    this.lang,
    this.createdAt,
    this.order,
    this.articles,
    this.categories,
    this.isOffline = false,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    print(json);
    print('-------------------');
    return Category(
      id: json['id'] ?? '',
      title: json['title'],
      parentId: json['parent_id'],
      lang: json['lang'],
      image: json['image'],
      imageIdentifier: json['image_identifier'],
      order: json['order'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      section: json['section'],
      articles: (json['articles'] as List<dynamic>?)
          ?.map((e) => Countable(count: (e as Map)['count'] as int))
          .toList(),
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => Countable(count: (e as Map)['count'] as int))
          .toList(),
    );
  }

  Map<String, dynamic> toFormJson() {
    return {
      'parent_id': parentId,
      'is_active': isActive,
      'title': title,
      'image_identifier': imageIdentifier,
      'image': image,
      'lang': lang,
      'order': order
    };
  }

  // Map<String, dynamic> toJson() {
  //   return {'id': id, 'title': title, 'section': section, 'lang': lang, 'order': order, 'articles': articles?.map((e) => e.toJson()).toList()};
  // }
}

// class Article {
//   final String id;
//   final String title;
//   final String section;
//   final String category;
//   final String language;
//   final DateTime createdAt;

//   Article({required this.id, required this.title, required this.section, required this.category, required this.language, required this.createdAt});

//   factory Article.fromJson(Map<String, dynamic> json) {
//     return Article(
//       id: json['id'] ?? '',
//       title: json['title'] ?? '',
//       section: json['section'] ?? '',
//       category: json['category'] ?? '',
//       language: json['lang'] ?? '',
//       createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {'id': id, 'title': title, 'section': section, 'category': category, 'lang': language, 'created_at': createdAt.toIso8601String()};
//   }
// }
