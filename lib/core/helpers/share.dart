import 'package:share_plus/share_plus.dart';
import 'package:zad_aldaia/features/items/data/models/item.dart';

class Share {
  static Future<void> multi(List<Item> items) async {
    String content = items
        .map((item) {
          if (item.type == ItemType.text) {
            return "${item.title} \n ${item.content}";
          } else if (item.type == ItemType.image) {
            return "Image: ${item.imageUrl}";
          } else if (item.type == ItemType.video) {
            return "Video: ${item.youtubeUrl}";
          }
          return item.id;
        })
        .reduce((value, element) => "$value \n------------\n $element");
    SharePlus.instance.share(ShareParams(text: content));
  }

  static item(Item item) {
    if (item.type == ItemType.text) {
      SharePlus.instance.share(ShareParams(title: item.title, text: item.content));
    } else if (item.type == ItemType.image) {
      SharePlus.instance.share(ShareParams(title: item.note, text: item.imageUrl));
    } else if (item.type == ItemType.video) {
      SharePlus.instance.share(ShareParams(title: item.note, text: item.youtubeUrl));
    }
  }
}
