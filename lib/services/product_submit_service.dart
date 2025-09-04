// lib/services/product_submit_service.dart
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:image_picker/image_picker.dart';

import 'package:prodhunt/services/firebase_service.dart';

/// Handles product creation (publish now or schedule) + image uploads.
/// Always uses putData (bytes) for Storage to dodge iOS "Message too long".
class ProductSubmitService {
  static final CollectionReference<Map<String, dynamic>> _products =
      FirebaseService.productsRef;
  static final FirebaseStorage _storage = FirebaseService.storage;

  /// Create product + upload images (logo/cover). Returns the product id.
  static Future<String> createProduct({
    // basics
    required String name,
    required String tagline,
    String? description,
    String? category,
    List<String>? tags,

    // publish vs schedule
    required bool publishNow,
    DateTime? scheduledAt,

    // images (either file OR bytes; both optional)
    XFile? logoFile,
    Uint8List? logoBytes,
    XFile? coverFile,
    Uint8List? coverBytes,
  }) async {
    final uid = FirebaseService.currentUserId;
    if (uid == null) {
      throw Exception('Not signed in');
    }

    final docRef = _products.doc();

    // Firestore timestamps
    final serverNow = FieldValue.serverTimestamp();
    final DateTime defaultFuture = DateTime.now().add(
      const Duration(minutes: 5),
    );

    // Initial payload (image URLs filled after upload)
    final Map<String, dynamic> payload = {
      'name': name.trim(),
      'tagline': tagline.trim(),
      'description': (description ?? '').trim(),
      'category': (category ?? 'General').trim(),
      'tags': (tags ?? const <String>[]),

      'createdBy': uid,
      'status': publishNow ? 'published' : 'draft',
      'launchDate': publishNow
          ? serverNow
          : Timestamp.fromDate(scheduledAt ?? defaultFuture),

      'upvoteCount': 0,
      'commentCount': 0,

      'createdAt': serverNow,
      'updatedAt': serverNow,

      'views': 0,
    };

    // 1) Create product doc
    debugPrint('📌 [Firestore] Creating doc products/${docRef.id}');
    try {
      await docRef.set(payload);
      debugPrint('✅ [Firestore] Created: ${docRef.id}');
    } catch (e, st) {
      debugPrint('❌ [Firestore] Create failed: $e\n$st');
      rethrow;
    }

    // 2) Upload images (bytes on all platforms)
    String? logoUrl;
    if (logoBytes != null || logoFile != null) {
      final path = 'users/$uid/products/${docRef.id}/logo.jpg';
      try {
        debugPrint(
          '📤 [Storage] Uploading LOGO → $path'
          '${kIsWeb && logoBytes != null ? ' (bytes: ${logoBytes!.length} B)' : ''}',
        );
        logoUrl = await _uploadImage(
          path: path,
          file: logoFile,
          bytes: logoBytes,
        );
        debugPrint('✅ [Storage] Logo upload success → $logoUrl');
      } catch (e, st) {
        debugPrint('❌ [Storage] Logo upload failed: $e\n$st');
        await _safeBumpUpdatedAt(docRef);
        throw Exception('Logo upload failed: $e');
      }
    }

    String? coverUrl;
    if (coverBytes != null || coverFile != null) {
      final path = 'users/$uid/products/${docRef.id}/cover.jpg';
      try {
        debugPrint(
          '📤 [Storage] Uploading COVER → $path'
          '${kIsWeb && coverBytes != null ? ' (bytes: ${coverBytes!.length} B)' : ''}',
        );
        coverUrl = await _uploadImage(
          path: path,
          file: coverFile,
          bytes: coverBytes,
        );
        debugPrint('✅ [Storage] Cover upload success → $coverUrl');
      } catch (e, st) {
        debugPrint('❌ [Storage] Cover upload failed: $e\n$st');
        await _safeBumpUpdatedAt(docRef);
        throw Exception('Cover upload failed: $e');
      }
    }

    // 3) Patch URLs (if any) + cache-bust
    if (logoUrl != null || coverUrl != null) {
      final bust = DateTime.now().millisecondsSinceEpoch;
      final updateMap = <String, dynamic>{
        if (logoUrl != null) 'logoUrl': '$logoUrl?t=$bust',
        if (coverUrl != null) 'coverUrl': '$coverUrl?t=$bust',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      debugPrint('📌 [Firestore] Updating image URLs for ${docRef.id}');
      try {
        await docRef.update(updateMap);
        debugPrint('✅ [Firestore] Image URLs updated');
      } catch (e, st) {
        debugPrint('❌ [Firestore] Update URLs failed: $e\n$st');
        rethrow;
      }
    } else {
      debugPrint('ℹ️ No images to update on Firestore.');
    }

    return docRef.id;
  }

  /// Upload helper: ALWAYS uses putData (bytes). If [bytes] is null, reads from [file].
  static Future<String> _uploadImage({
    required String path,
    XFile? file,
    Uint8List? bytes,
  }) async {
    final ref = _storage.ref(path);
    final String contentType = _guessContentType(file);

    try {
      // Prepare data
      final Uint8List data = bytes ?? await file!.readAsBytes();
      debugPrint(
        '⬆️  putData -> $path (contentType: $contentType, bytes: ${data.lengthInBytes})',
      );

      await ref.putData(data, SettableMetadata(contentType: contentType));

      final url = await ref.getDownloadURL();
      debugPrint('🔗 [Storage] Download URL: $url');
      return url;
    } catch (e, st) {
      debugPrint('🔥 [Storage] Upload failed at $path: $e\n$st');
      rethrow;
    }
  }

  static Future<void> _safeBumpUpdatedAt(
    DocumentReference<Map<String, dynamic>> docRef,
  ) async {
    try {
      await docRef.update({'updatedAt': FieldValue.serverTimestamp()});
      debugPrint('↻ [Firestore] updatedAt bumped after failure');
    } catch (_) {
      // ignore
    }
  }

  static String _guessContentType(XFile? f) {
    final p = (f?.path ?? '').toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    if (p.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
