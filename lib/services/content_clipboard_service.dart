import 'package:flutter/foundation.dart';

/// Represents content copied to internal clipboard
class ClipboardContent {
  final String sourceId;
  final String
      sourceType; // 'language', 'path', 'section', 'branch', 'topic', 'article', 'item'
  final Map<String, dynamic> data;
  final DateTime copiedAt;

  ClipboardContent({
    required this.sourceId,
    required this.sourceType,
    required this.data,
    required this.copiedAt,
  });

  @override
  String toString() {
    return 'ClipboardContent(type: $sourceType, copiedAt: $copiedAt)';
  }
}

/// Internal clipboard service for copy/paste within the app
/// NOT using system clipboard - internal to app only
class ContentClipboardService extends ChangeNotifier {
  ClipboardContent? _clipboard;

  /// Copy content to internal clipboard
  void copy({
    required String id,
    required String type,
    required Map<String, dynamic> data,
  }) {
    _clipboard = ClipboardContent(
      sourceId: id,
      sourceType: type,
      data: Map<String, dynamic>.from(data),
      copiedAt: DateTime.now(),
    );

    debugPrint('[Clipboard] Copied $type: $id');
    notifyListeners(); // Notify listeners of change
  }

  /// Get content from clipboard
  ClipboardContent? getCopiedContent() => _clipboard;

  /// Check if clipboard has content
  bool hasContent() => _clipboard != null;

  /// Clear clipboard
  void clear() {
    if (_clipboard != null) {
      debugPrint('[Clipboard] Cleared: ${_clipboard!.sourceType}');
    }
    _clipboard = null;
    notifyListeners(); // Notify listeners of change
  }

  /// Get clipboard content type (for UI display)
  String? get contentType => _clipboard?.sourceType;

  /// Get clipboard source ID
  String? get sourceId => _clipboard?.sourceId;

  /// Get clipboard copy time
  DateTime? get copiedAt => _clipboard?.copiedAt;
}
