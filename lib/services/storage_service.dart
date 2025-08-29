// lib/services/storage_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prodhunt/services/firebase_service.dart';

class StorageService {
  static FirebaseStorage get _storage => FirebaseStorage.instance;

  /// Upload user avatar -> gs://.../users/<uid>/avatar.jpg
  static Future<String?> uploadProfilePicture(XFile imageFile) async {
    try {
      final uid = FirebaseService.currentUserId;
      if (uid == null) return null;

      // compress to jpeg (<= ~1MB)
      Uint8List? jpeg = await FlutterImageCompress.compressWithFile(
        imageFile.path,
        quality: 82,
        minWidth: 1024,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      jpeg ??= await File(imageFile.path).readAsBytes();

      final ref = _storage.ref('users/$uid/avatar.jpg');
      await ref.putData(jpeg, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }

  /// Product logo under the signed-in user's folder so rules pass:
  /// gs://.../users/<uid>/products/<productId>/logo.jpg
  static Future<String?> uploadProductLogo(
    XFile imageFile,
    String productId,
  ) async {
    try {
      final uid = FirebaseService.currentUserId;
      if (uid == null) return null;

      final ref = _storage.ref('users/$uid/products/$productId/logo.jpg');
      await ref.putFile(
        File(imageFile.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading product logo: $e');
      return null;
    }
  }

  /// Gallery: gs://.../users/<uid>/products/<productId>/gallery/img_<i>.jpg
  static Future<List<String>> uploadProductGallery(
    List<XFile> imageFiles,
    String productId,
  ) async {
    try {
      final uid = FirebaseService.currentUserId;
      if (uid == null) return [];

      final urls = <String>[];
      for (int i = 0; i < imageFiles.length; i++) {
        final ref = _storage.ref(
          'users/$uid/products/$productId/gallery/img_$i.jpg',
        );
        await ref.putFile(
          File(imageFiles[i].path),
          SettableMetadata(contentType: 'image/jpeg'),
        );
        urls.add(await ref.getDownloadURL());
      }
      return urls;
    } catch (e) {
      print('Error uploading product gallery: $e');
      return [];
    }
  }

  static Future<bool> deleteImage(String imageUrl) async {
    try {
      await _storage.refFromURL(imageUrl).delete();
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }
}
