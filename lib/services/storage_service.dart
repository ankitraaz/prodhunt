// lib/services/storage_service.dart
import 'dart:io' show File;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import 'package:prodhunt/services/firebase_service.dart';

class StorageService {
  static FirebaseStorage get _storage => FirebaseStorage.instance;

  /* ----------------------- Common helpers ----------------------- */

  // New product id (use this before uploading images for drafts/scheduled)
  static String newProductId() => FirebaseService.productsRef.doc().id;

  // Try to compress to JPEG (~<=1MB-ish). Falls back to raw bytes.
  static Future<Uint8List> _compressToJpegBytes(XFile imageFile) async {
    try {
      if (kIsWeb) {
        final raw = await imageFile.readAsBytes();
        final comp = await FlutterImageCompress.compressWithList(
          raw,
          quality: 82,
          minWidth: 1024,
          format: CompressFormat.jpeg,
        );
        return Uint8List.fromList(comp);
      } else {
        final comp = await FlutterImageCompress.compressWithFile(
          imageFile.path,
          quality: 82,
          minWidth: 1024,
          keepExif: false,
          format: CompressFormat.jpeg,
        );
        if (comp != null) return comp;
        return await File(imageFile.path).readAsBytes();
      }
    } catch (_) {
      // last resort
      return kIsWeb
          ? await imageFile.readAsBytes()
          : await File(imageFile.path).readAsBytes();
    }
  }

  static SettableMetadata _meta({
    Map<String, String>? custom,
    String contentType = 'image/jpeg',
  }) {
    return SettableMetadata(
      contentType: contentType,
      customMetadata: custom ?? const {},
    );
  }

  static String _bust(String url) {
    final t = DateTime.now().millisecondsSinceEpoch;
    // Preserve existing query if any
    return url.contains('?') ? '$url&_t=$t' : '$url?_t=$t';
  }

  /* ----------------------- Profile avatar ----------------------- */

  /// Upload user avatar -> gs://.../users/<uid>/avatar.jpg
  /// Returns downloadURL with cache-bust param.
  static Future<String?> uploadProfilePicture(
    XFile imageFile, {
    bool cacheBust = true,
  }) async {
    try {
      final uid = FirebaseService.currentUserId;
      if (uid == null) return null;

      final jpeg = await _compressToJpegBytes(imageFile);
      final ref = _storage.ref('users/$uid/avatar.jpg');

      await ref.putData(jpeg, _meta(custom: {'owner': uid, 'type': 'avatar'}));

      final url = await ref.getDownloadURL();
      return cacheBust ? _bust(url) : url;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }

  /* ----------------------- Product images ----------------------- */
  // NOTE: Scheduling images ka storage se koi direct link nahi hota.
  // Actual scheduling aap product doc me `launchDate` (future) set karke karte ho.
  // Yaha hum sirf optional metadata me launchDate tag kar dete hain.

  /// Product logo -> gs://.../users/<uid>/products/<productId>/logo.jpg
  static Future<String?> uploadProductLogo(
    XFile imageFile,
    String productId, {
    DateTime? launchDate, // optional: tag in metadata
    bool cacheBust = true,
  }) async {
    try {
      final uid = FirebaseService.currentUserId;
      if (uid == null) return null;

      final jpeg = await _compressToJpegBytes(imageFile);
      final ref = _storage.ref('users/$uid/products/$productId/logo.jpg');

      await ref.putData(
        jpeg,
        _meta(
          custom: {
            'owner': uid,
            'productId': productId,
            'role': 'logo',
            if (launchDate != null)
              'launchDateIso': launchDate.toUtc().toIso8601String(),
          },
        ),
      );

      final url = await ref.getDownloadURL();
      return cacheBust ? _bust(url) : url;
    } catch (e) {
      print('Error uploading product logo: $e');
      return null;
    }
  }

  /// Single cover/shot -> gs://.../users/<uid>/products/<productId>/gallery/cover.jpg (or img_<i>.jpg)
  static Future<String?> uploadProductCover(
    XFile imageFile,
    String productId, {
    bool asCover = true,
    int index = 0,
    DateTime? launchDate,
    bool cacheBust = true,
  }) async {
    try {
      final uid = FirebaseService.currentUserId;
      if (uid == null) return null;

      final jpeg = await _compressToJpegBytes(imageFile);
      final fileName = asCover ? 'cover.jpg' : 'img_$index.jpg';
      final ref = _storage.ref(
        'users/$uid/products/$productId/gallery/$fileName',
      );

      await ref.putData(
        jpeg,
        _meta(
          custom: {
            'owner': uid,
            'productId': productId,
            'role': asCover ? 'cover' : 'gallery',
            if (!asCover) 'index': '$index',
            if (launchDate != null)
              'launchDateIso': launchDate.toUtc().toIso8601String(),
          },
        ),
      );

      final url = await ref.getDownloadURL();
      return cacheBust ? _bust(url) : url;
    } catch (e) {
      print('Error uploading product cover: $e');
      return null;
    }
  }

  /// Gallery batch: gs://.../users/<uid>/products/<productId>/gallery/img_<i>.jpg
  static Future<List<String>> uploadProductGallery(
    List<XFile> imageFiles,
    String productId, {
    DateTime? launchDate,
    bool cacheBust = true,
  }) async {
    try {
      final uid = FirebaseService.currentUserId;
      if (uid == null) return [];

      final urls = <String>[];
      for (int i = 0; i < imageFiles.length; i++) {
        final jpeg = await _compressToJpegBytes(imageFiles[i]);
        final ref = _storage.ref(
          'users/$uid/products/$productId/gallery/img_$i.jpg',
        );

        await ref.putData(
          jpeg,
          _meta(
            custom: {
              'owner': uid,
              'productId': productId,
              'role': 'gallery',
              'index': '$i',
              if (launchDate != null)
                'launchDateIso': launchDate.toUtc().toIso8601String(),
            },
          ),
        );

        var url = await ref.getDownloadURL();
        if (cacheBust) url = _bust(url);
        urls.add(url);
      }
      return urls;
    } catch (e) {
      print('Error uploading product gallery: $e');
      return [];
    }
  }

  /* ----------------------- Delete ----------------------- */

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
