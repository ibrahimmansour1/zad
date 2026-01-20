enum ItemType { text, image, video }

class Item {
  String id;
  String? articleId;
  int? order;
  ItemType type;
  String? note;
  String? title;
  String? content;
  String? youtubeUrl;
  String? createdAt;
  String? imageUrl;
  String? imageIdentifier;
  String? backgroundColor; // For text/image background colors

  Item({
    required this.id,
    this.note,
    this.order,
    this.type = ItemType.text,
    this.title,
    this.content,
    this.imageUrl,
    this.youtubeUrl,
    this.createdAt,
    this.articleId,
    this.imageIdentifier,
    this.backgroundColor,
    this.isOffline = false,
  });

  bool isOffline = false;

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json['id'],
        note: json['note'],
        order: json['order'],
        type: ItemType.values
            .where((element) => element.name == json['type'])
            .first,
        title: json['title'],
        content: json['content'],
        imageUrl: json['image_url'],
        youtubeUrl: json['youtube_url'],
        createdAt: json['created_at'],
        articleId: json['article_id'],
        imageIdentifier: json['image_identifier'],
        backgroundColor: json['background_color'],
      );

  Map<String, dynamic> toFormJson() => {
        "article_id": articleId,
        "note": note,
        "display_order": order ?? 0,
        "type": type.name,
        "title": title,
        "content": content,
        "image_url": imageUrl,
        "youtube_url": youtubeUrl,
        "image_identifier": imageIdentifier,
        "background_color": backgroundColor,
      };
}
