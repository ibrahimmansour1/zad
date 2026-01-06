import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zad_aldaia/core/di/dependency_injection.dart';
import 'package:zad_aldaia/core/helpers/admin_password.dart';
import 'package:zad_aldaia/core/widgets/admin_breadcrumb.dart';
import 'package:zad_aldaia/features/categories/data/models/category.dart';
import 'package:zad_aldaia/features/categories/logic/categories_cubit.dart';
import 'package:zad_aldaia/features/upload/image_upload.dart';

class AdminLanguagesScreen extends StatefulWidget {
  const AdminLanguagesScreen({super.key});

  @override
  State<AdminLanguagesScreen> createState() => _AdminLanguagesScreenState();
}

class _AdminLanguagesScreenState extends State<AdminLanguagesScreen> {
  late final CategoriesCubit cubit = getIt<CategoriesCubit>();

  @override
  void initState() {
    super.initState();
    cubit.getChildCategories(null); // Load languages (top level)
  }

  void _showAddLanguageDialog() async {
    // Verify password first
    final verified = await AdminPasswordDialog.verifyAddLanguage(context);
    if (!verified) return;

    final nameController = TextEditingController();
    final codeController = TextEditingController();
    String? imageUrl;
    String? imageIdentifier;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Language'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Language Name',
                    hintText: 'e.g., Deutsch, العربية',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Language Code',
                    hintText: 'e.g., german, arabic',
                  ),
                ),
                const SizedBox(height: 16),
                // Image Upload Section
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Language Flag/Icon (Optional)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ImageUpload(
                          url: imageUrl,
                          identifier: imageIdentifier,
                          onImageUpdated: (identifier, url) {
                            setState(() {
                              imageIdentifier = identifier;
                              imageUrl = url;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty &&
                    codeController.text.trim().isNotEmpty) {
                  await _addLanguage(
                    nameController.text.trim(),
                    codeController.text.trim().toLowerCase(),
                    imageUrl,
                    imageIdentifier,
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005A32),
              ),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditLanguageDialog(Category language) async {
    final nameController = TextEditingController(text: language.title);
    String? imageUrl = language.image;
    String? imageIdentifier = language.imageIdentifier;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Language'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Language Name',
                    hintText: 'e.g., Deutsch, العربية',
                  ),
                ),
                const SizedBox(height: 16),
                // Image Upload Section
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Language Flag/Icon',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ImageUpload(
                          url: imageUrl,
                          identifier: imageIdentifier,
                          onImageUpdated: (identifier, url) {
                            setState(() {
                              imageIdentifier = identifier;
                              imageUrl = url;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  await _updateLanguage(
                    language.id,
                    nameController.text.trim(),
                    imageUrl,
                    imageIdentifier,
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005A32),
              ),
              child:
                  const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addLanguage(String name, String code, String? imageUrl,
      String? imageIdentifier) async {
    try {
      await Supabase.instance.client.from('languages').insert({
        'name': name,
        'code': code,
        'flag_url': imageUrl ?? 'assets/images/flags/$code.png',
        'image_identifier': imageIdentifier,
        'display_order': 99, // Add at end
        'is_active': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Language "$name" added successfully!')),
      );

      // Reload languages
      cubit.getChildCategories(null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding language: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateLanguage(
      String id, String name, String? imageUrl, String? imageIdentifier) async {
    try {
      await Supabase.instance.client.from('languages').update({
        'name': name,
        'flag_url': imageUrl,
        'image_identifier': imageIdentifier,
      }).eq('id', id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Language "$name" updated successfully!')),
      );

      // Reload languages
      cubit.getChildCategories(null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating language: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteLanguage(Category language) async {
    // First verify password
    final verified =
        await AdminPasswordDialog.verifyDeleteLanguage(context, language.title);
    if (!verified) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Language'),
        content: Text(
            'Are you sure you want to delete "${language.title}"?\n\nThis will also delete all paths, categories, articles, and items under this language.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client
            .from('languages')
            .delete()
            .eq('id', language.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Language "${language.title}" deleted!')),
        );

        cubit.getChildCategories(null);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting language: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAE6),
      appBar: AdminAppBar(
        title: 'Manage Languages',
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddLanguageDialog,
          ),
        ],
      ),
      body: BlocProvider(
        create: (context) => cubit,
        child: BlocBuilder<CategoriesCubit, CategoriesState>(
          builder: (context, state) {
            if (state is LoadingState) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ErrorState) {
              return Center(child: Text('Error: ${state.error}'));
            }

            if (state is ListLoadedState) {
              if (state.items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.language,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No languages yet',
                        style: TextStyle(
                            fontSize: 18, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddLanguageDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Language'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF005A32),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  final language = state.items[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: _buildLanguageAvatar(language),
                      title: Text(
                        language.title ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${language.childrenCount} paths'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditLanguageDialog(language),
                          ),
                          IconButton(
                            icon: Icon(
                              language.isActive
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: language.isActive
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            onPressed: () async {
                              await Supabase.instance.client
                                  .from('languages')
                                  .update({'is_active': !language.isActive}).eq(
                                      'id', language.id);
                              cubit.getChildCategories(null);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteLanguage(language),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }

            return const SizedBox();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLanguageDialog,
        backgroundColor: const Color(0xFF005A32),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildLanguageAvatar(Category language) {
    // Try to show the uploaded image first
    if (language.image != null && language.image!.isNotEmpty) {
      return CircleAvatar(
        backgroundColor: Colors.grey.shade200,
        backgroundImage: NetworkImage(language.image!),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }

    // Fallback to first letter
    return CircleAvatar(
      backgroundColor: const Color(0xFF005A32),
      child: Text(
        (language.title ?? '').isNotEmpty
            ? (language.title ?? '?')[0].toUpperCase()
            : '?',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
