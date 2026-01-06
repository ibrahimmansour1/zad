import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zad_aldaia/core/di/dependency_injection.dart';
import 'package:zad_aldaia/core/helpers/storage.dart';
import 'package:zad_aldaia/core/supabase_client.dart';
import 'package:zad_aldaia/core/widgets/highlighted_text.dart';
import 'package:zad_aldaia/features/items/data/models/item.dart';
import 'package:zad_aldaia/features/items/logic/items_cubit.dart';
import 'package:zad_aldaia/generated/l10n.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final ItemsCubit cubit = getIt<ItemsCubit>();
  String query = '';
  bool hasSearched = false;
  bool showFilters = false;

  // Filter data
  List<Map<String, dynamic>> languages = [];
  List<Map<String, dynamic>> paths = [];
  List<Map<String, dynamic>> sections = [];
  List<Map<String, dynamic>> articles = [];

  String? selectedLanguageId;
  String? selectedPathId;
  String? selectedSectionId;
  String? selectedArticleId;

  @override
  void initState() {
    super.initState();
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    try {
      final result = await Supa.client
          .from('languages')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);
      setState(() {
        languages = List<Map<String, dynamic>>.from(result as List);
      });
    } catch (e) {
      print('Error loading languages: $e');
    }
  }

  Future<void> _loadPaths(String languageId) async {
    try {
      final result = await Supa.client
          .from('paths')
          .select()
          .eq('language_id', languageId)
          .eq('is_active', true)
          .order('display_order', ascending: true);
      setState(() {
        paths = List<Map<String, dynamic>>.from(result as List);
        selectedPathId = null;
        sections = [];
        selectedSectionId = null;
        articles = [];
        selectedArticleId = null;
      });
    } catch (e) {
      print('Error loading paths: $e');
    }
  }

  Future<void> _loadSections(String pathId) async {
    try {
      final result = await Supa.client
          .from('sections')
          .select()
          .eq('path_id', pathId)
          .eq('is_active', true)
          .order('display_order', ascending: true);
      setState(() {
        sections = List<Map<String, dynamic>>.from(result as List);
        selectedSectionId = null;
        articles = [];
        selectedArticleId = null;
      });
    } catch (e) {
      print('Error loading sections: $e');
    }
  }

  Future<void> _loadArticles(String sectionId) async {
    try {
      final result = await Supa.client
          .from('articles')
          .select()
          .eq('category_id', sectionId);
      setState(() {
        articles = List<Map<String, dynamic>>.from(result as List);
        selectedArticleId = null;
      });
    } catch (e) {
      print('Error loading articles: $e');
    }
  }

  void loadData() {
    if (query.trim().isNotEmpty) {
      setState(() => hasSearched = true);

      // Build filters
      final Map<String, dynamic> eqMap = {};
      if (selectedArticleId != null) {
        eqMap['article_id'] = selectedArticleId;
      }

      cubit.loadItems(
        eqMap: eqMap,
        likeMap: {'content': query.trim()},
      );
    }
  }

  void _clearFilters() {
    setState(() {
      selectedLanguageId = null;
      selectedPathId = null;
      selectedSectionId = null;
      selectedArticleId = null;
      paths = [];
      sections = [];
      articles = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAE6),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(10),
          child: Column(
            children: [
              // Search bar row
              Row(
                children: [
                  Expanded(
                    child: SearchBar(
                      backgroundColor:
                          const WidgetStatePropertyAll(Colors.white),
                      hintText: S.of(context).search,
                      trailing: [
                        if (query.isNotEmpty)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                query = '';
                                hasSearched = false;
                              });
                            },
                            icon: const Icon(Icons.clear),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() => query = value);
                      },
                      onSubmitted: (_) => loadData(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: loadData,
                      icon: const Icon(Icons.search, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: showFilters ? Colors.orange : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() => showFilters = !showFilters);
                      },
                      icon: Icon(
                        Icons.filter_list,
                        color: showFilters ? Colors.white : Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.black54),
                    ),
                  ),
                ],
              ),

              // Filters section
              if (showFilters) ...[
                const SizedBox(height: 16),
                _buildFiltersSection(),
              ],

              const SizedBox(height: 16),

              // Results
              Expanded(
                child: BlocProvider(
                  create: (context) => cubit,
                  child: BlocBuilder<ItemsCubit, ItemsState>(
                    builder: (context, state) {
                      // Initial state - show hint
                      if (!hasSearched && state is! LoadingState) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search,
                                  size: 80, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                S.of(context).search,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Enter keywords to search',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (state is ErrorState) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 60, color: Colors.red.shade300),
                              const SizedBox(height: 16),
                              Text(
                                'Error',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.red.shade400),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: loadData,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }
                      if (state is LoadingState) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is ListLoadedState) {
                        if (state.items.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off,
                                    size: 80, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'No results found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try different keywords',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                '${state.items.length} result${state.items.length != 1 ? 's' : ''} found',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: state.items.length,
                                itemBuilder: (context, index) {
                                  final item = state.items[index];
                                  return _buildSearchResultItem(item);
                                },
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Container();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Search',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Language dropdown
          _buildDropdown(
            label: 'Language',
            value: selectedLanguageId,
            items: languages,
            onChanged: (value) {
              setState(() => selectedLanguageId = value);
              if (value != null) _loadPaths(value);
            },
          ),

          // Path dropdown
          if (selectedLanguageId != null && paths.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDropdown(
              label: 'Path',
              value: selectedPathId,
              items: paths,
              onChanged: (value) {
                setState(() => selectedPathId = value);
                if (value != null) _loadSections(value);
              },
            ),
          ],

          // Section dropdown
          if (selectedPathId != null && sections.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDropdown(
              label: 'Category',
              value: selectedSectionId,
              items: sections,
              onChanged: (value) {
                setState(() => selectedSectionId = value);
                if (value != null) _loadArticles(value);
              },
            ),
          ],

          // Article dropdown
          if (selectedSectionId != null && articles.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDropdown(
              label: 'Article',
              value: selectedArticleId,
              items: articles,
              nameField: 'title',
              onChanged: (value) {
                setState(() => selectedArticleId = value);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<Map<String, dynamic>> items,
    required Function(String?) onChanged,
    String nameField = 'name',
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text('All $label'),
        ),
        ...items.map((item) => DropdownMenuItem<String>(
              value: item['id'] as String,
              child: Text(item[nameField]?.toString() ?? 'Unknown'),
            )),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildSearchResultItem(Item item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with highlighting
            if (item.title != null && item.title!.isNotEmpty)
              HighlightedText(
                text: item.title!,
                searchQuery: query,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

            const SizedBox(height: 8),

            // Content with highlighting
            if (item.content != null && item.content!.isNotEmpty)
              HighlightedText(
                text: item.content!,
                searchQuery: query,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                maxLines: 5,
              ),

            // Note with highlighting
            if (item.note != null && item.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.yellow.shade200),
                ),
                child: HighlightedText(
                  text: item.note!,
                  searchQuery: query,
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],

            // Image
            if (item.type == ItemType.image && item.imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 100,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => Storage.download(item.imageUrl!),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Download Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005A32),
                  foregroundColor: Colors.white,
                ),
              ),
            ],

            // Item type badge
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getTypeColor(item.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.type.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getTypeColor(item.type),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(ItemType type) {
    switch (type) {
      case ItemType.text:
        return Colors.blue;
      case ItemType.image:
        return Colors.green;
      case ItemType.video:
        return Colors.red;
    }
  }
}
