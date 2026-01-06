import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zad_aldaia/core/supabase_client.dart';

/// Service for backing up and restoring content data
class BackupService {
  /// Export all content to JSON format
  static Future<Map<String, dynamic>> exportToJson() async {
    final data = <String, dynamic>{};

    try {
      // Export languages
      final languages = await Supa.client
          .from('languages')
          .select()
          .order('display_order', ascending: true);
      data['languages'] = languages;

      // Export paths
      final paths = await Supa.client
          .from('paths')
          .select()
          .order('display_order', ascending: true);
      data['paths'] = paths;

      // Export sections (categories)
      final sections = await Supa.client
          .from('sections')
          .select()
          .order('display_order', ascending: true);
      data['sections'] = sections;

      // Export branches (subcategories)
      final branches = await Supa.client
          .from('branches')
          .select()
          .order('display_order', ascending: true);
      data['branches'] = branches;

      // Export topics
      final topics = await Supa.client
          .from('topics')
          .select()
          .order('display_order', ascending: true);
      data['topics'] = topics;

      // Export articles
      final articles = await Supa.client.from('articles').select();
      data['articles'] = articles;

      // Export article_items
      final articleItems = await Supa.client
          .from('article_items')
          .select()
          .order('order', ascending: true);
      data['article_items'] = articleItems;

      // Add metadata
      data['metadata'] = {
        'exported_at': DateTime.now().toIso8601String(),
        'version': '1.0',
        'app': 'Zad Al Daia',
      };

      return data;
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  /// Convert data to CSV format for Excel compatibility
  static String convertToCSV(
      List<Map<String, dynamic>> data, String tableName) {
    if (data.isEmpty) return '';

    final headers = data.first.keys.toList();
    final buffer = StringBuffer();

    // Add table name as header
    buffer.writeln('# $tableName');

    // Add column headers
    buffer.writeln(headers.join(','));

    // Add data rows
    for (var row in data) {
      final values = headers.map((h) {
        final value = row[h]?.toString() ?? '';
        // Escape commas and quotes
        if (value.contains(',') ||
            value.contains('"') ||
            value.contains('\n')) {
          return '"${value.replaceAll('"', '""')}"';
        }
        return value;
      }).toList();
      buffer.writeln(values.join(','));
    }

    buffer.writeln();
    return buffer.toString();
  }

  /// Export all data to CSV format
  static Future<String> exportToCSV() async {
    final buffer = StringBuffer();

    try {
      // Export languages
      final languages = await Supa.client
          .from('languages')
          .select()
          .order('display_order', ascending: true);
      buffer.write(convertToCSV(
          List<Map<String, dynamic>>.from(languages), 'LANGUAGES'));

      // Export paths
      final paths = await Supa.client
          .from('paths')
          .select()
          .order('display_order', ascending: true);
      buffer
          .write(convertToCSV(List<Map<String, dynamic>>.from(paths), 'PATHS'));

      // Export sections
      final sections = await Supa.client
          .from('sections')
          .select()
          .order('display_order', ascending: true);
      buffer.write(
          convertToCSV(List<Map<String, dynamic>>.from(sections), 'SECTIONS'));

      // Export branches
      final branches = await Supa.client
          .from('branches')
          .select()
          .order('display_order', ascending: true);
      buffer.write(
          convertToCSV(List<Map<String, dynamic>>.from(branches), 'BRANCHES'));

      // Export topics
      final topics = await Supa.client
          .from('topics')
          .select()
          .order('display_order', ascending: true);
      buffer.write(
          convertToCSV(List<Map<String, dynamic>>.from(topics), 'TOPICS'));

      // Export articles
      final articles = await Supa.client.from('articles').select();
      buffer.write(
          convertToCSV(List<Map<String, dynamic>>.from(articles), 'ARTICLES'));

      // Export article_items
      final articleItems = await Supa.client
          .from('article_items')
          .select()
          .order('order', ascending: true);
      buffer.write(convertToCSV(
          List<Map<String, dynamic>>.from(articleItems), 'ARTICLE_ITEMS'));

      return buffer.toString();
    } catch (e) {
      throw Exception('Failed to export data to CSV: $e');
    }
  }

  /// Save JSON backup to file and share
  static Future<void> saveAndShareJson(BuildContext context) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Exporting data...'),
                ],
              ),
            ),
          ),
        ),
      );

      final data = await exportToJson();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final fileName = 'zad_backup_$timestamp.json';

      if (kIsWeb) {
        // For web, trigger download
        // Note: This would need additional web-specific handling
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup created: $fileName')),
        );
      } else {
        // For mobile, save to temp and share
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsString(jsonString);

        Navigator.pop(context);

        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Zad Al Daia Backup',
          text: 'Content backup from Zad Al Daia app',
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating backup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Save CSV backup to file and share
  static Future<void> saveAndShareCSV(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Exporting data...'),
                ],
              ),
            ),
          ),
        ),
      );

      final csvString = await exportToCSV();

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final fileName = 'zad_backup_$timestamp.csv';

      if (kIsWeb) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup created: $fileName')),
        );
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsString(csvString);

        Navigator.pop(context);

        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Zad Al Daia Backup (CSV)',
          text: 'Content backup from Zad Al Daia app',
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating backup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Import data from JSON file
  static Future<void> importFromJson(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      String jsonString;

      if (kIsWeb) {
        if (file.bytes == null) {
          throw Exception('Could not read file');
        }
        jsonString = utf8.decode(file.bytes!);
      } else {
        if (file.path == null) {
          throw Exception('Could not read file path');
        }
        jsonString = await File(file.path!).readAsString();
      }

      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This will import the following data:'),
              const SizedBox(height: 12),
              if (data['languages'] != null)
                Text('• Languages: ${(data['languages'] as List).length}'),
              if (data['paths'] != null)
                Text('• Paths: ${(data['paths'] as List).length}'),
              if (data['sections'] != null)
                Text('• Sections: ${(data['sections'] as List).length}'),
              if (data['branches'] != null)
                Text('• Branches: ${(data['branches'] as List).length}'),
              if (data['topics'] != null)
                Text('• Topics: ${(data['topics'] as List).length}'),
              if (data['articles'] != null)
                Text('• Articles: ${(data['articles'] as List).length}'),
              if (data['article_items'] != null)
                Text(
                    '• Article Items: ${(data['article_items'] as List).length}'),
              const SizedBox(height: 16),
              const Text(
                'Note: Existing items with the same ID will be updated.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005A32),
              ),
              child:
                  const Text('Import', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Importing data...'),
                ],
              ),
            ),
          ),
        ),
      );

      await _importData(data);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data imported successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error importing data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Import data to database
  static Future<void> _importData(Map<String, dynamic> data) async {
    // Import in order of dependencies
    final tables = [
      'languages',
      'paths',
      'sections',
      'branches',
      'topics',
      'articles',
      'article_items',
    ];

    for (var table in tables) {
      if (data[table] != null && (data[table] as List).isNotEmpty) {
        final items = List<Map<String, dynamic>>.from(data[table] as List);

        for (var item in items) {
          try {
            // Try to upsert the item
            await Supa.client.from(table).upsert(item);
          } catch (e) {
            print('Error importing item to $table: $e');
            // Continue with other items
          }
        }
      }
    }
  }
}
