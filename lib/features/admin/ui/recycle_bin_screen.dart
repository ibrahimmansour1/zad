import 'package:flutter/material.dart';
import 'package:zad_aldaia/core/di/dependency_injection.dart';
import 'package:zad_aldaia/core/widgets/admin_mode_toggle.dart';
import 'package:zad_aldaia/core/widgets/global_home_button.dart';
import 'package:zad_aldaia/services/soft_delete_service.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _softDelete = getIt<SoftDeleteService>();
  final List<_BinTab> _tabs = const [
    _BinTab(label: 'Languages', table: 'languages'),
    _BinTab(label: 'Paths', table: 'paths'),
    _BinTab(label: 'Sections', table: 'sections'),
    _BinTab(label: 'Branches', table: 'branches'),
    _BinTab(label: 'Topics', table: 'topics'),
    _BinTab(label: 'Items', table: 'content_items'),
    _BinTab(label: 'Categories', table: 'categories'),
    _BinTab(label: 'Articles', table: 'articles'),
    _BinTab(label: 'Article Items', table: 'article_items'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycle Bin'),
        actions: [
          AdminModeIndicator(),
          const AdminModeQuickToggle(),
          GlobalHomeButton()
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs
            .map((t) => _BinList(table: t.table, softDelete: _softDelete))
            .toList(),
      ),
    );
  }
}

class _BinList extends StatefulWidget {
  final String table;
  final SoftDeleteService softDelete;
  const _BinList({required this.table, required this.softDelete});

  @override
  State<_BinList> createState() => _BinListState();
}

class _BinListState extends State<_BinList> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    try {
      return await widget.softDelete.getDeletedItems(widget.table, limit: 200);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to load ${widget.table}: $e'),
          backgroundColor: Colors.red,
        ));
      }
      return [];
    }
  }

  Future<void> _restore(String id) async {
    try {
      await widget.softDelete.restore(id: id, tableName: widget.table);
      setState(() => _future = _load());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item restored successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on ParentDeletedException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot restore: ${e.message}'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _deleteForever(String id, String? imageIdentifier) async {
    try {
      await widget.softDelete.permanentlyDelete(
        id: id,
        tableName: widget.table,
        imageIdentifier: imageIdentifier,
      );
      setState(() => _future = _load());
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _confirmAndDelete(
      String id, String? imageIdentifier, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently Delete?'),
        content: Text(
          'Are you sure you want to permanently delete "$title"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Forever',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteForever(id, imageIdentifier);
    }
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'unknown';
    try {
      final date = DateTime.parse(dateValue.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateValue.toString();
    }
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('Recycle bin is empty'));
        }
        return RefreshIndicator(
          onRefresh: () async => setState(() => _future = _load()),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              final title = item['title'] ?? item['name'] ?? item['id'];
              final deletedAt = item['deleted_at'] ?? item['deletedAt'];
              final imageId =
                  item['image_identifier'] ?? item['imageIdentifier'];

              // Calculate days until permanent deletion
              String daysRemaining = '';
              if (deletedAt != null) {
                try {
                  final deletedDate = DateTime.parse(deletedAt.toString());
                  final purgeDate = deletedDate.add(recycleBinRetention);
                  final daysLeft = purgeDate.difference(DateTime.now()).inDays;
                  if (daysLeft > 0) {
                    daysRemaining = ' • $daysLeft days left';
                  } else {
                    daysRemaining = ' • Expires soon';
                  }
                } catch (_) {}
              }

              return Card(
                child: ListTile(
                  title: Text('$title'),
                  subtitle:
                      Text('Deleted: ${_formatDate(deletedAt)}$daysRemaining'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Restore',
                        icon: const Icon(Icons.restore, color: Colors.green),
                        onPressed: () => _restore(item['id'] as String),
                      ),
                      IconButton(
                        tooltip: 'Delete Forever',
                        icon:
                            const Icon(Icons.delete_forever, color: Colors.red),
                        onPressed: () => _confirmAndDelete(item['id'] as String,
                            imageId as String?, title.toString()),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _BinTab {
  final String label;
  final String table;
  const _BinTab({required this.label, required this.table});
}
