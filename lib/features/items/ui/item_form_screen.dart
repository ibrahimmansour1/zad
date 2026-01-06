import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zad_aldaia/core/di/dependency_injection.dart';
import 'package:zad_aldaia/core/routing/routes.dart';
import 'package:zad_aldaia/features/items/data/models/item.dart';
import 'package:zad_aldaia/features/items/logic/items_cubit.dart';
import 'package:zad_aldaia/features/upload/image_upload.dart';
import 'package:zad_aldaia/generated/l10n.dart';

class ItemFormScreen extends StatefulWidget {
  final String? itemId;
  final String? articleId;

  const ItemFormScreen({super.key, this.itemId, this.articleId})
      : assert(itemId != null || articleId != null);

  bool get isEditMode => itemId != null;

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  late final ItemsCubit store = getIt<ItemsCubit>();
  Item item = Item(id: '');
  var toggleSelections = <bool>[true, false, false];
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final backgroundColorController = TextEditingController();
  final noteController = TextEditingController();
  final contentController = TextEditingController();
  final youtubeUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      store.loadItem({'id': widget.itemId!});
    } else {
      fillForm();
    }
  }

  onToggle(index) {
    for (int i = 0; i < toggleSelections.length; i++) {
      toggleSelections[i] = i == index;
    }
    item.type = ItemType.values[index];
    setState(() {});
  }

  listener(context, state) {
    if (state is ErrorState) {
      print(state.error);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(state.error)));
    }
    if (state is SavedState) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Item ${widget.isEditMode ? "updated" : "created"} successfully!')));
      if (item.articleId != null) {
        Navigator.of(context)
            .pushNamed(MyRoutes.items, arguments: {"id": item.articleId});
      }
    }
    if (state is LoadedState) {
      item = state.item;
      fillForm();
    }
  }

  fillForm() async {
    titleController.text = item.title ?? '';
    noteController.text = item.note ?? '';
    contentController.text = item.content ?? '';
    youtubeUrlController.text = item.youtubeUrl ?? '';
    backgroundColorController.text = item.backgroundColor ?? '';
    toggleSelections = ItemType.values.map((e) => e == item.type).toList();
    setState(() {});
  }

  bool validate() {
    if (item.type == ItemType.image && item.imageIdentifier == null) {
      return false;
    }
    // if (item.type == ItemType.video && item.youtubeUrl == null) {
    //   return false;
    // }
    // if (item.type == ItemType.text && (item.title == null || item.content == null)) {
    //   return false;
    // }
    return true;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && validate()) {
      item.articleId = item.articleId ?? widget.articleId;
      item.title = titleController.text.trim();
      item.content = contentController.text.trim();
      item.youtubeUrl = youtubeUrlController.text.trim();
      item.note = noteController.text.trim();
      item.backgroundColor = backgroundColorController.text.trim().isNotEmpty
          ? backgroundColorController.text.trim()
          : null;

      await store.saveItem(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          centerTitle: true,
          title: Text(widget.isEditMode ? 'Edit Item' : 'Create New Item')),
      body: BlocProvider(
        create: (context) => store,
        child: BlocListener<ItemsCubit, ItemsState>(
          listener: listener,
          child: BlocBuilder<ItemsCubit, ItemsState>(
            builder: (context, state) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 15.h),
                      Center(
                        child: ToggleButtons(
                          onPressed: onToggle,
                          isSelected: toggleSelections,
                          children: [
                            Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 32),
                                child: Text(S.of(context).text)),
                            Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 32),
                                child: Text(S.of(context).image)),
                            Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 32),
                                child: Text(S.of(context).video)),
                          ],
                        ),
                      ),
                      // Title field for all item types
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      if (item.type == ItemType.text) ...[
                        TextFormField(
                          controller: contentController,
                          decoration:
                              const InputDecoration(labelText: 'Content'),
                          maxLines: 5,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter content';
                            }
                            return null;
                          },
                        ),
                      ],
                      TextFormField(
                          controller: noteController,
                          decoration: const InputDecoration(labelText: 'Note (optional)'),
                          maxLines: 3,
                      ),
                      TextFormField(
                        controller: backgroundColorController,
                        decoration: const InputDecoration(
                          labelText: 'Background color (optional)',
                          hintText: '#RRGGBB or color name',
                          helperText:
                              'Examples: #FFE5E5, #E5F3FF, lightblue, lightyellow',
                        ),
                      ),
                      if (item.type == ItemType.video)
                        TextFormField(
                          controller: youtubeUrlController,
                          decoration:
                              const InputDecoration(labelText: 'Youtube url'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a Youtube url';
                            }
                            return null;
                          },
                        ),
                      if (item.type == ItemType.image) ...[
                        const SizedBox(height: 30),
                        ImageUpload(
                          url: item.imageUrl,
                          onImageUpdated: (identifier, image) {
                            setState(() {
                              item.imageIdentifier = identifier;
                              item.imageUrl = image;
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: 30),
                      if (state is SavingState)
                        const Center(child: CircularProgressIndicator())
                      else
                        SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                                onPressed: _submitForm,
                                child: Text(widget.isEditMode
                                    ? 'Update Item'
                                    : 'Create Item'))),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
