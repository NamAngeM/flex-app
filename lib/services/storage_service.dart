// lib/services/storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfileImage(String uid, File imageFile) async {
    final ref = _storage.ref().child('profile_images/$uid.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> deleteProfileImage(String uid) async {
    final ref = _storage.ref().child('profile_images/$uid.jpg');
    await ref.delete();
  }
}