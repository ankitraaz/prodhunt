// lib/services/product_submit_service.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'package:prodhunt/services/firebase_service.dart';

/// Handles product creation (publish now or schedule) + image uploads.
/// Works on mobile and web (supports XFile and raw bytes).
class ProductService {
  static final CollectionReference<Map<String, dynamic>> _products =
      FirebaseService.productsRef;
  static final FirebaseStorage _storage = FirebaseService.storage;

  /// Creates a product document that satisfies your Firestore **rules**:
  /// - `createdBy` must equal `auth.uid`
  /// - `status` must be `"draft"` or `"published"` at create-time
  /// - `upvoteCount` and `commentCount` start at 0
  ///
  /// For scheduling, we set `status: "draft"` and a future `launchDate`.
  /// A Cloud Function (or cron job) can flip `status -> "published"`
  /// when `launchDate <= now`.
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

    // new product id
    final docRef = _products.doc();

    // timestamps
    final serverNow = FieldValue.serverTimestamp();
    final DateTime defaultFuture = DateTime.now().add(
      const Duration(minutes: 5),
    );

    // initial payload (passes security rules)
    final Map<String, dynamic> payload = {
      'name': name.trim(),
      'tagline': tagline.trim(),
      'description': (description ?? '').trim(),
      'category': (category ?? 'General').trim(),
      'tags': (tags ?? const <String>[]),

      'createdBy': uid,
      'status': publishNow ? 'published' : 'draft',

      // for ordering on "All Products" and for scheduler
      'launchDate': publishNow
          ? serverNow
          : Timestamp.fromDate(scheduledAt ?? defaultFuture),

      // rule-friendly counters
      'upvoteCount': 0,
      'commentCount': 0,

      // misc
      'createdAt': serverNow,
      'updatedAt': serverNow,

      // image fields (filled after upload)
      'logoUrl': '',
      'coverUrl': '',

      // optional metric
      'views': 0,
    };

    // write the product doc first (images come after)
    await docRef.set(payload);

    // Upload images (ignore if none). Store under the user's folder
    // so your Storage rules can allow owner writes.
    String? logoUrl;
    if (logoBytes != null || logoFile != null) {
      logoUrl = await _uploadImage(
        path: 'users/$uid/products/${docRef.id}/logo.jpg',
        file: logoFile,
        bytes: logoBytes,
      );
    }

    String? coverUrl;
    if (coverBytes != null || coverFile != null) {
      coverUrl = await _uploadImage(
        path: 'users/$uid/products/${docRef.id}/cover.jpg',
        file: coverFile,
        bytes: coverBytes,
      );
    }

    // Update doc with uploaded image URLs (if any) + bump updatedAt
    if (logoUrl != null || coverUrl != null) {
      final bust = DateTime.now().millisecondsSinceEpoch;
      await docRef.update({
        if (logoUrl != null) 'logoUrl': '$logoUrl?t=$bust',
        if (coverUrl != null) 'coverUrl': '$coverUrl?t=$bust',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // done — return id so UI can navigate/snack
    return docRef.id;
  }

  /// Internal helper to upload either bytes (web) or file (mobile).
  static Future<String?> _uploadImage({
    required String path,
    XFile? file,
    Uint8List? bytes,
  }) async {
    try {
      final ref = _storage.ref(path);

      // pick a content-type
      final String contentType = _guessContentType(file);

      if (bytes != null) {
        await ref.putData(bytes, SettableMetadata(contentType: contentType));
      } else if (file != null) {
        await ref.putFile(
          File(file.path),
          SettableMetadata(contentType: contentType),
        );
      } else {
        return null;
      }

      return await ref.getDownloadURL();
    } catch (_) {
      // swallow image errors so product creation doesn't fail entirely
      return null;
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
