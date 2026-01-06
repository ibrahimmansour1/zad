import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:image_downloader_web/image_downloader_web.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class Storage {
  static download(url) async {
    if (kIsWeb) {
      await saveImageWeb(url);
    } else {
      await saveImageAndroid(url);
    }
  }

  static saveImageAndroid(String imageUrl) async {
    var status = await Permission.storage.request();
    var androidVersion = (await DeviceInfoPlugin().androidInfo).version.release;
    if (status.isGranted || int.parse(androidVersion) >= 11) {
      var response = await get(Uri.parse(imageUrl));
      var downloadDirectory = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOAD);
      var filePathAndName = '$downloadDirectory/${Uuid().v4()}.jpg';
      File file = File(filePathAndName);
      await file.writeAsBytes(response.bodyBytes);
    }
  }

  static saveImageWeb(String imageUrl) async {
    try {
      await WebImageDownloader.downloadImageFromWeb(imageUrl, name: Uuid().v4());
    } catch (e) {
      print(e);
    }
  }
}
