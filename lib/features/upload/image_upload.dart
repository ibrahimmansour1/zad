import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zad_aldaia/core/di/dependency_injection.dart';
import 'package:zad_aldaia/features/upload/upload_cubit.dart';

class ImageUpload extends StatefulWidget {
  final String? url;
  final String? identifier;
  final Function(String?, String?) onImageUpdated;

  const ImageUpload({super.key, required this.onImageUpdated, this.url, this.identifier});

  @override
  State<ImageUpload> createState() => _ImageUploadState();
}

class _ImageUploadState extends State<ImageUpload> {
  File? image;
  late final UploadCubit cubit = getIt<UploadCubit>();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      image = File(pickedFile.path);
      final now = DateTime.now().toIso8601String(); // image!.path
      cubit.upload(image!, now);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 200,
          child: GestureDetector(
            onTap: _pickImage,
            child: BlocProvider(
              create: (context) => cubit,
              child: BlocListener<UploadCubit, UploadState>(
                listener: (context, state) {
                  if (state is UploadedState) {
                    widget.onImageUpdated(state.identifier, state.url);
                  }
                  if (state is UploadFailedState) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Upload failed: ${state.error}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: BlocBuilder<UploadCubit, UploadState>(
                  builder: (context, state) {
                    if (state is UploadingState) {
                      return Center(child: CircularProgressIndicator());
                    }
                    return Card(
                      child:
                          image != null
                              ? Image.file(image!, fit: BoxFit.cover)
                              : widget.url != null
                              ? CachedNetworkImage(imageUrl: widget.url!)
                              : Center(child: Text("Add Image +")),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        if (widget.identifier != null) IconButton(onPressed: () => cubit.delete(widget.identifier!), icon: Icon(Icons.close)),
      ],
    );
  }
}
