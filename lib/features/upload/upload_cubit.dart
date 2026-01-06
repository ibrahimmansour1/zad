import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadCubit extends Cubit<UploadState> {
  final SupabaseClient _supabase;

  UploadCubit(this._supabase) : super(InitialState());

  Future delete(String identifier) async {
    emit(UploadingState());
    try {
      await _supabase.storage.from('images').remove([identifier]);
      emit(DeletedState());
    } catch (e) {
      print('Error uploading image: $e');
      emit(UploadFailedState(e.toString()));
      return null;
    }
  }

  Future upload(File image, String identifier) async {
    emit(UploadingState());
    try {
      await _supabase.storage.from('images').upload(identifier, image, fileOptions: const FileOptions(upsert: false, cacheControl: '3600'));
      final url = _supabase.storage.from('images').getPublicUrl(identifier);
      print("uploaded image identifier => $identifier");
      print("uploaded image url => $url");
      emit(UploadedState(identifier, url));
    } catch (e) {
      print('Error uploading image: $e');
      emit(UploadFailedState(e.toString()));
      return null;
    }
  }
}

sealed class UploadState {}

class InitialState extends UploadState {}

class UploadingState extends UploadState {}

class UploadedState extends UploadState {
  final String identifier;
  final String url;

  UploadedState(this.identifier, this.url);
}

class DeletedState extends UploadState {}

class UploadFailedState extends UploadState {
  final String error;

  UploadFailedState(this.error);
}
