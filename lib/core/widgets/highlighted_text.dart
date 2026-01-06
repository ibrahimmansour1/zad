import 'package:flutter/material.dart';

/// Widget that highlights search terms within text
class HighlightedText extends StatelessWidget {
  final String text;
  final String? searchQuery;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final int maxLines;
  final TextOverflow overflow;

  const HighlightedText({
    super.key,
    required this.text,
    this.searchQuery,
    this.style,
    this.highlightStyle,
    this.maxLines = 10,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    if (searchQuery == null || searchQuery!.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final defaultStyle = style ?? const TextStyle(color: Colors.black87);
    final defaultHighlightStyle = highlightStyle ??
        TextStyle(
          backgroundColor: Colors.yellow.shade300,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        );

    final spans = _buildTextSpans(
        text, searchQuery!, defaultStyle, defaultHighlightStyle);

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  List<TextSpan> _buildTextSpans(
    String text,
    String query,
    TextStyle normalStyle,
    TextStyle highlightStyle,
  ) {
    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    int start = 0;
    int index = lowerText.indexOf(lowerQuery, start);

    while (index != -1) {
      // Add text before the match
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: normalStyle,
        ));
      }

      // Add the highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: highlightStyle,
      ));

      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    // Add remaining text after the last match
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: normalStyle,
      ));
    }

    return spans;
  }
}

/// Extension to check if a string contains another string (case insensitive)
extension StringSearchExtension on String {
  bool containsIgnoreCase(String other) {
    return toLowerCase().contains(other.toLowerCase());
  }

  /// Get the highlighted portions of text
  List<HighlightMatch> getHighlightMatches(String query) {
    final matches = <HighlightMatch>[];
    final lowerText = toLowerCase();
    final lowerQuery = query.toLowerCase();

    int start = 0;
    int index = lowerText.indexOf(lowerQuery, start);

    while (index != -1) {
      matches.add(HighlightMatch(
        start: index,
        end: index + query.length,
        matchedText: substring(index, index + query.length),
      ));
      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    return matches;
  }
}

class HighlightMatch {
  final int start;
  final int end;
  final String matchedText;

  HighlightMatch({
    required this.start,
    required this.end,
    required this.matchedText,
  });
}
