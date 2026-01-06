enum ArticleType { Text, Image, Video }

extension ArticleTypeExtension on ArticleType {
  static ArticleType valueOf(String? value) {
    return ArticleType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ArticleType.Text,
    ); // Default to text if not found
  }
}
