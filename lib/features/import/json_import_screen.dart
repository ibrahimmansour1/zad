import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zad_aldaia/core/widgets/admin_mode_toggle.dart';
import 'package:zad_aldaia/core/widgets/global_home_button.dart';
import 'package:zad_aldaia/core/supabase_client.dart';

/// A screen for importing JSON data with custom field mapping
class JsonImportScreen extends StatefulWidget {
  const JsonImportScreen({super.key});

  @override
  State<JsonImportScreen> createState() => _JsonImportScreenState();
}

class _JsonImportScreenState extends State<JsonImportScreen> {
  Map<String, dynamic>? _jsonData;
  String? _fileName;
  List<String> _availableKeys = [];
  String? _selectedArrayKey; // The key containing the array of items
  List<Map<String, dynamic>> _itemsToImport = [];

  // Target destination
  String? _targetTable;
  String? _targetLanguageId;
  String? _targetPathId;
  String? _targetSectionId;

  // Available options for dropdowns
  List<Map<String, dynamic>> _languages = [];
  List<Map<String, dynamic>> _paths = [];
  List<Map<String, dynamic>> _sections = [];

  // Field mapping: app field -> json key
  final Map<String, String?> _fieldMapping = {};

  // Loading state
  bool _isLoading = false;
  bool _isImporting = false;

  // Preview mode
  int _currentPreviewIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    try {
      final languages = await Supa.client
          .from('languages')
          .select('id, name, code')
          .order('name', ascending: true);
      setState(() {
        _languages = List<Map<String, dynamic>>.from(languages as List);
      });
    } catch (e) {
      debugPrint('Error loading languages: $e');
    }
  }

  Future<void> _loadPaths(String languageId) async {
    try {
      final paths = await Supa.client
          .from('paths')
          .select('id, title, name')
          .eq('language_id', languageId)
          .order('display_order', ascending: true);
      setState(() {
        _paths = List<Map<String, dynamic>>.from(paths as List);
        _targetPathId = null;
        _sections = [];
        _targetSectionId = null;
      });
    } catch (e) {
      debugPrint('Error loading paths: $e');
    }
  }

  Future<void> _loadSections(String pathId) async {
    try {
      final sections = await Supa.client
          .from('sections')
          .select('id, title, name')
          .eq('path_id', pathId)
          .order('display_order', ascending: true);
      setState(() {
        _sections = List<Map<String, dynamic>>.from(sections as List);
        _targetSectionId = null;
      });
    } catch (e) {
      debugPrint('Error loading sections: $e');
    }
  }

  Future<void> _pickJsonFile() async {
    try {
      setState(() => _isLoading = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isLoading = false);
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

      final data = jsonDecode(jsonString);

      setState(() {
        _fileName = file.name;
        _jsonData = _parseJsonData(data);
        _availableKeys = _extractTopLevelKeys(_jsonData!);
        _selectedArrayKey = null;
        _itemsToImport = [];
        _fieldMapping.clear();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reading JSON file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _parseJsonData(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is List) {
      return {'items': data};
    } else {
      return {'value': data};
    }
  }

  List<String> _extractTopLevelKeys(Map<String, dynamic> data) {
    return data.keys.toList();
  }

  List<String> _extractItemKeys(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return [];
    final keys = <String>{};
    for (var item in items) {
      keys.addAll(_flattenKeys(item));
    }
    return keys.toList()..sort();
  }

  List<String> _flattenKeys(Map<String, dynamic> map, [String prefix = '']) {
    final keys = <String>[];
    for (var entry in map.entries) {
      final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
      keys.add(key);
      if (entry.value is Map<String, dynamic>) {
        keys.addAll(_flattenKeys(entry.value as Map<String, dynamic>, key));
      }
    }
    return keys;
  }

  dynamic _getNestedValue(Map<String, dynamic> map, String path) {
    final keys = path.split('.');
    dynamic current = map;
    for (var key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }

  void _selectArrayKey(String? key) {
    if (key == null) return;

    final value = _jsonData![key];
    List<Map<String, dynamic>> items = [];

    if (value is List) {
      items = value.whereType<Map<String, dynamic>>().toList();
    } else if (value is Map<String, dynamic>) {
      // If it's a single object, wrap it in a list
      items = [value];
    }

    setState(() {
      _selectedArrayKey = key;
      _itemsToImport = items;
      _fieldMapping.clear();
      _currentPreviewIndex = 0;
    });
  }

  List<String> _getTargetFields() {
    switch (_targetTable) {
      case 'articles':
        return ['title'];
      case 'article_items':
        return [
          'title',
          'content',
          'note',
          'type',
          'image_url',
          'youtube_url',
          'background_color',
          'order'
        ];
      case 'paths':
        return ['title', 'name', 'description', 'image_url'];
      case 'sections':
        return ['title', 'name', 'description', 'image_url'];
      case 'branches':
        return ['title', 'name', 'description', 'image_url'];
      case 'topics':
        return ['title', 'name', 'description', 'image_url'];
      default:
        return [];
    }
  }

  Future<void> _performImport() async {
    if (_itemsToImport.isEmpty || _targetTable == null) return;

    // Validate required parent IDs based on target table
    String? parentIdField;
    String? parentIdValue;

    switch (_targetTable) {
      case 'paths':
        if (_targetLanguageId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a language'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        parentIdField = 'language_id';
        parentIdValue = _targetLanguageId;
        break;
      case 'sections':
        if (_targetPathId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a path'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        parentIdField = 'path_id';
        parentIdValue = _targetPathId;
        break;
      case 'branches':
        if (_targetSectionId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a section'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        parentIdField = 'section_id';
        parentIdValue = _targetSectionId;
        break;
      case 'articles':
        if (_targetSectionId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a section (category)'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        parentIdField = 'category_id';
        parentIdValue = _targetSectionId;
        break;
    }

    setState(() => _isImporting = true);

    try {
      int successCount = 0;
      int errorCount = 0;
      String? lastCreatedArticleId;

      for (int i = 0; i < _itemsToImport.length; i++) {
        final sourceItem = _itemsToImport[i];
        final targetItem = <String, dynamic>{};

        // Apply field mappings
        for (var entry in _fieldMapping.entries) {
          if (entry.value != null && entry.value!.isNotEmpty) {
            final value = _getNestedValue(sourceItem, entry.value!);
            if (value != null) {
              targetItem[entry.key] = value.toString();
            }
          }
        }

        // Add parent reference
        if (parentIdField != null && parentIdValue != null) {
          targetItem[parentIdField] = parentIdValue;
        }

        // Handle article_items special case - they need an article_id
        if (_targetTable == 'article_items') {
          if (lastCreatedArticleId == null) {
            // Create a parent article first
            final articleTitle = targetItem['title'] ?? 'Imported Article';
            final articleResult = await Supa.client
                .from('articles')
                .insert({
                  'title': articleTitle,
                  'category_id': _targetSectionId,
                  'is_active': true,
                })
                .select()
                .single();
            lastCreatedArticleId = articleResult['id'];
          }
          targetItem['article_id'] = lastCreatedArticleId;
          targetItem['order'] = i;
          if (!targetItem.containsKey('type')) {
            targetItem['type'] = 'text';
          }
        }

        // Set default display_order
        if (!targetItem.containsKey('display_order') &&
            _targetTable != 'article_items') {
          targetItem['display_order'] = i;
        }

        // Set active flag
        if (!targetItem.containsKey('is_active')) {
          targetItem['is_active'] = true;
        }

        try {
          await Supa.client.from(_targetTable!).insert(targetItem);
          successCount++;
        } catch (e) {
          errorCount++;
          debugPrint('Error inserting item: $e');
        }
      }

      setState(() => _isImporting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Import complete: $successCount success, $errorCount errors'),
            backgroundColor: errorCount == 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() => _isImporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import JSON Data'),
        backgroundColor: const Color(0xFF005A32),
        foregroundColor: Colors.white,
        actions: [
          const AdminModeIndicator(),
          const AdminModeQuickToggle(),
          GlobalHomeButton(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step 1: Select JSON File
                  _buildStepCard(
                    step: 1,
                    title: 'Select JSON File',
                    isCompleted: _jsonData != null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickJsonFile,
                          icon: const Icon(Icons.upload_file),
                          label: Text(_fileName ?? 'Choose JSON File'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF005A32),
                            foregroundColor: Colors.white,
                          ),
                        ),
                        if (_fileName != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'File: $_fileName',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Text(
                            'Found ${_availableKeys.length} top-level keys',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Step 2: Select Data Array
                  if (_jsonData != null) ...[
                    const SizedBox(height: 16),
                    _buildStepCard(
                      step: 2,
                      title: 'Select Data to Import',
                      isCompleted: _itemsToImport.isNotEmpty,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select which key contains the data you want to import:',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableKeys.map((key) {
                              final value = _jsonData![key];
                              final isArray = value is List;
                              final count = isArray ? (value).length : 1;
                              return ChoiceChip(
                                label: Text(
                                    '$key ($count ${isArray ? 'items' : 'item'})'),
                                selected: _selectedArrayKey == key,
                                onSelected: (selected) {
                                  if (selected) _selectArrayKey(key);
                                },
                                selectedColor:
                                    const Color(0xFF005A32).withOpacity(0.2),
                              );
                            }).toList(),
                          ),
                          if (_itemsToImport.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Selected ${_itemsToImport.length} items to import',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF005A32),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Step 3: Select Target
                  if (_itemsToImport.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildStepCard(
                      step: 3,
                      title: 'Select Where to Import',
                      isCompleted: _targetTable != null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Import as',
                              border: OutlineInputBorder(),
                            ),
                            value: _targetTable,
                            items: const [
                              DropdownMenuItem(
                                  value: 'articles', child: Text('Articles')),
                              DropdownMenuItem(
                                  value: 'article_items',
                                  child: Text(
                                      'Article Items (into single article)')),
                              DropdownMenuItem(
                                  value: 'paths', child: Text('Paths')),
                              DropdownMenuItem(
                                  value: 'sections',
                                  child: Text('Sections (Categories)')),
                              DropdownMenuItem(
                                  value: 'branches',
                                  child: Text('Branches (Subcategories)')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _targetTable = value;
                                _fieldMapping.clear();
                              });
                            },
                          ),
                          const SizedBox(height: 12),

                          // Language selector
                          if (_targetTable != null) ...[
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Language',
                                border: OutlineInputBorder(),
                              ),
                              value: _targetLanguageId,
                              items: _languages.map((lang) {
                                return DropdownMenuItem(
                                  value: lang['id'] as String,
                                  child: Text(lang['name'] ??
                                      lang['code'] ??
                                      'Unknown'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _targetLanguageId = value;
                                });
                                if (value != null) _loadPaths(value);
                              },
                            ),
                          ],

                          // Path selector
                          if (_targetLanguageId != null &&
                              _targetTable != 'paths') ...[
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Path',
                                border: OutlineInputBorder(),
                              ),
                              value: _targetPathId,
                              items: _paths.map((path) {
                                return DropdownMenuItem(
                                  value: path['id'] as String,
                                  child: Text(path['title'] ??
                                      path['name'] ??
                                      'Unknown'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _targetPathId = value;
                                });
                                if (value != null) _loadSections(value);
                              },
                            ),
                          ],

                          // Section selector
                          if (_targetPathId != null &&
                              !['paths', 'sections']
                                  .contains(_targetTable)) ...[
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Section (Category)',
                                border: OutlineInputBorder(),
                              ),
                              value: _targetSectionId,
                              items: _sections.map((section) {
                                return DropdownMenuItem(
                                  value: section['id'] as String,
                                  child: Text(section['title'] ??
                                      section['name'] ??
                                      'Unknown'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _targetSectionId = value;
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Step 4: Map Fields
                  if (_targetTable != null && _itemsToImport.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildStepCard(
                      step: 4,
                      title: 'Map Fields',
                      isCompleted: _fieldMapping.isNotEmpty,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Map your JSON keys to the app fields:',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          ..._getTargetFields().map((field) {
                            final sourceKeys = _extractItemKeys(_itemsToImport);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        field,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_back, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 3,
                                    child: DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        isDense: true,
                                      ),
                                      value: _fieldMapping[field],
                                      hint: const Text('Select source key'),
                                      items: [
                                        const DropdownMenuItem(
                                          value: '',
                                          child: Text('-- None --',
                                              style: TextStyle(
                                                  color: Colors.grey)),
                                        ),
                                        ...sourceKeys.map((key) {
                                          return DropdownMenuItem(
                                            value: key,
                                            child: Text(key,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          );
                                        }),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _fieldMapping[field] = value;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],

                  // Step 5: Preview
                  if (_fieldMapping.isNotEmpty &&
                      _itemsToImport.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildStepCard(
                      step: 5,
                      title: 'Preview & Import',
                      isCompleted: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Preview (${_currentPreviewIndex + 1}/${_itemsToImport.length})',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _currentPreviewIndex > 0
                                        ? () => setState(
                                            () => _currentPreviewIndex--)
                                        : null,
                                    icon: const Icon(Icons.arrow_back_ios),
                                    iconSize: 18,
                                  ),
                                  IconButton(
                                    onPressed: _currentPreviewIndex <
                                            _itemsToImport.length - 1
                                        ? () => setState(
                                            () => _currentPreviewIndex++)
                                        : null,
                                    icon: const Icon(Icons.arrow_forward_ios),
                                    iconSize: 18,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(),
                          if (_itemsToImport.isNotEmpty)
                            ..._fieldMapping.entries
                                .where((e) =>
                                    e.value != null && e.value!.isNotEmpty)
                                .map((entry) {
                              final value = _getNestedValue(
                                _itemsToImport[_currentPreviewIndex],
                                entry.value!,
                              );
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        '${entry.key}:',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF005A32),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        value?.toString() ?? '(empty)',
                                        style: TextStyle(
                                          color: value != null
                                              ? Colors.black87
                                              : Colors.grey,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isImporting ? null : _performImport,
                              icon: _isImporting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.upload),
                              label: Text(
                                _isImporting
                                    ? 'Importing...'
                                    : 'Import ${_itemsToImport.length} Items',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF005A32),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildStepCard({
    required int step,
    required String title,
    required bool isCompleted,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : const Color(0xFF005A32),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : Text(
                            '$step',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
