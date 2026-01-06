import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zad_aldaia/core/supabase_client.dart';

/// Service for downloading and managing offline content
class OfflineContentService {
  static const String _offlineDataKey = 'offline_content_data';
  static const String _lastSyncKey = 'offline_last_sync';
  static const String _downloadedLanguagesKey = 'offline_downloaded_languages';

  /// Check if offline data is available
  static Future<bool> hasOfflineData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_offlineDataKey);
  }

  /// Get last sync time
  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_lastSyncKey);
    if (timestamp == null) return null;
    return DateTime.tryParse(timestamp);
  }

  /// Get list of downloaded language IDs
  static Future<List<String>> getDownloadedLanguages() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_downloadedLanguagesKey);
    return data ?? [];
  }

  /// Download content for a specific language
  static Future<void> downloadLanguageContent(
    BuildContext context,
    String languageId,
    String languageName, {
    Function(double progress, String status)? onProgress,
  }) async {
    try {
      final data = <String, dynamic>{};
      
      onProgress?.call(0.1, 'Fetching language data...');

      // Fetch language
      final language = await Supa.client
          .from('languages')
          .select()
          .eq('id', languageId)
          .single();
      data['language'] = language;

      onProgress?.call(0.2, 'Fetching paths...');

      // Fetch paths for this language
      final paths = await Supa.client
          .from('paths')
          .select()
          .eq('language_id', languageId)
          .order('display_order', ascending: true);
      data['paths'] = paths;

      onProgress?.call(0.3, 'Fetching sections...');

      // Fetch sections for all paths
      final pathIds = (paths as List).map((p) => p['id'] as String).toList();
      List<dynamic> sections = [];
      for (var pathId in pathIds) {
        final pathSections = await Supa.client
            .from('sections')
            .select()
            .eq('path_id', pathId)
            .order('display_order', ascending: true);
        sections.addAll(pathSections as List);
      }
      data['sections'] = sections;

      onProgress?.call(0.4, 'Fetching branches...');

      // Fetch branches for all sections
      final sectionIds = sections.map((s) => s['id'] as String).toList();
      List<dynamic> branches = [];
      for (var sectionId in sectionIds) {
        final sectionBranches = await Supa.client
            .from('branches')
            .select()
            .eq('section_id', sectionId)
            .order('display_order', ascending: true);
        branches.addAll(sectionBranches as List);
      }
      data['branches'] = branches;

      onProgress?.call(0.5, 'Fetching topics...');

      // Fetch topics for all branches
      final branchIds = branches.map((b) => b['id'] as String).toList();
      List<dynamic> topics = [];
      for (var branchId in branchIds) {
        final branchTopics = await Supa.client
            .from('topics')
            .select()
            .eq('branch_id', branchId)
            .order('display_order', ascending: true);
        topics.addAll(branchTopics as List);
      }
      data['topics'] = topics;

      onProgress?.call(0.6, 'Fetching articles...');

      // Fetch all articles related to sections (categories)
      List<dynamic> articles = [];
      for (var sectionId in sectionIds) {
        final sectionArticles = await Supa.client
            .from('articles')
            .select()
            .eq('category_id', sectionId);
        articles.addAll(sectionArticles as List);
      }
      data['articles'] = articles;

      onProgress?.call(0.7, 'Fetching article items...');

      // Fetch all article items
      final articleIds = articles.map((a) => a['id'] as String).toList();
      List<dynamic> articleItems = [];
      for (var articleId in articleIds) {
        final items = await Supa.client
            .from('article_items')
            .select()
            .eq('article_id', articleId)
            .order('order', ascending: true);
        articleItems.addAll(items as List);
      }
      data['article_items'] = articleItems;

      onProgress?.call(0.8, 'Saving offline data...');

      // Save to local storage
      await _saveOfflineData(languageId, data);

      // Update downloaded languages list
      final prefs = await SharedPreferences.getInstance();
      final downloadedLanguages = await getDownloadedLanguages();
      if (!downloadedLanguages.contains(languageId)) {
        downloadedLanguages.add(languageId);
        await prefs.setStringList(_downloadedLanguagesKey, downloadedLanguages);
      }

      onProgress?.call(1.0, 'Download complete!');

    } catch (e) {
      throw Exception('Failed to download content: $e');
    }
  }

  /// Save offline data for a language
  static Future<void> _saveOfflineData(String languageId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing offline data
    final existingDataStr = prefs.getString(_offlineDataKey);
    Map<String, dynamic> allData = {};
    if (existingDataStr != null) {
      allData = jsonDecode(existingDataStr) as Map<String, dynamic>;
    }
    
    // Add/update language data
    allData[languageId] = data;
    
    // Save back
    await prefs.setString(_offlineDataKey, jsonEncode(allData));
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Get offline data for a language
  static Future<Map<String, dynamic>?> getOfflineData(String languageId) async {
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString(_offlineDataKey);
    if (dataStr == null) return null;
    
    final allData = jsonDecode(dataStr) as Map<String, dynamic>;
    return allData[languageId] as Map<String, dynamic>?;
  }

  /// Delete offline data for a language
  static Future<void> deleteLanguageOfflineData(String languageId) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Remove from data
    final dataStr = prefs.getString(_offlineDataKey);
    if (dataStr != null) {
      final allData = jsonDecode(dataStr) as Map<String, dynamic>;
      allData.remove(languageId);
      await prefs.setString(_offlineDataKey, jsonEncode(allData));
    }
    
    // Remove from downloaded list
    final downloadedLanguages = await getDownloadedLanguages();
    downloadedLanguages.remove(languageId);
    await prefs.setStringList(_downloadedLanguagesKey, downloadedLanguages);
  }

  /// Delete all offline data
  static Future<void> clearAllOfflineData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_offlineDataKey);
    await prefs.remove(_lastSyncKey);
    await prefs.remove(_downloadedLanguagesKey);
  }

  /// Get total size of offline data
  static Future<String> getOfflineDataSize() async {
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString(_offlineDataKey);
    if (dataStr == null) return '0 KB';
    
    final bytes = utf8.encode(dataStr).length;
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Show language selector dialog then download
  static Future<void> showLanguageSelectorAndDownload(BuildContext context) async {
    // Fetch available languages
    try {
      final languages = await Supa.client
          .from('languages')
          .select('id, name, code, flag_url')
          .order('name', ascending: true);

      if (!context.mounted) return;

      // Get already downloaded languages
      final downloadedLangs = await getDownloadedLanguages();

      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.download_for_offline, color: Colors.teal.shade700),
              const SizedBox(width: 12),
              const Text('Download for Offline'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select a language to download for offline use:',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: (languages as List).length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final lang = languages[index];
                      final isDownloaded = downloadedLangs.contains(lang['id']);
                      return ListTile(
                        leading: lang['flag_url'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  lang['flag_url'],
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.teal.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      Icons.language,
                                      size: 20,
                                      color: Colors.teal.shade700,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.language,
                                  size: 20,
                                  color: Colors.teal.shade700,
                                ),
                              ),
                        title: Text(lang['name'] ?? 'Unknown'),
                        subtitle: lang['code'] != null
                            ? Text(lang['code'].toString().toUpperCase())
                            : null,
                        trailing: isDownloaded
                            ? Chip(
                                label: const Text('Downloaded'),
                                backgroundColor: Colors.green.shade100,
                                labelStyle: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 12,
                                ),
                              )
                            : Icon(
                                Icons.download,
                                color: Colors.teal.shade700,
                              ),
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          showDownloadDialog(
                            context,
                            lang['id'],
                            lang['name'] ?? 'Language',
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load languages: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show download dialog for a language
  static Future<void> showDownloadDialog(
    BuildContext context,
    String languageId,
    String languageName,
  ) async {
    double progress = 0;
    String status = 'Preparing...';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Start download
          if (progress == 0) {
            downloadLanguageContent(
              context,
              languageId,
              languageName,
              onProgress: (p, s) {
                setState(() {
                  progress = p;
                  status = s;
                });
                if (p >= 1.0) {
                  Future.delayed(const Duration(milliseconds: 500), () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$languageName content downloaded for offline use!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  });
                }
              },
            ).catchError((e) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Download failed: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            });
          }

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.download, color: Color(0xFF005A32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Downloading $languageName',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF005A32)),
                ),
                const SizedBox(height: 16),
                Text(
                  status,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF005A32),
                  ),
                ),
              ],
            ),
            actions: [
              if (progress < 1.0)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
            ],
          );
        },
      ),
    );
  }
}
