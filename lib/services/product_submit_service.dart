// lib/services/product_submit_service.dart

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prodhunt/services/firebase_service.dart';

/// Product creation + image upload service.
/// Uses 'pending' for admin approval.
class ProductSubmitService {
  static final _products = FirebaseService.productsRef;
  static final _storage = FirebaseService.storage;

  static Future<String> createProduct({
    // basic fields
    required String name,
    required String tagline,
    String? description,
    String? category,
    List<String>? tags,

    // scheduling
    required bool publishNow,
    DateTime? scheduledAt,

    // images
    XFile? logoFile,
    Uint8List? logoBytes,
    XFile? coverFile,
    Uint8List? coverBytes,
  }) async {
    final uid = FirebaseService.currentUserId;
    if (uid == null) throw Exception("Not signed in");

    final docRef = _products.doc();
    final serverNow = FieldValue.serverTimestamp();
    final fallbackLaunch = Timestamp.fromDate(
      scheduledAt ?? DateTime.now().add(const Duration(minutes: 5)),
    );

    /// 🔥 CREATE FIRESTORE DOC (NO IMAGES YET)
    /// Rules allow create() with status = pending
    await docRef.set({
      'name': name.trim(),
      'tagline': tagline.trim(),
      'description': (description ?? '').trim(),
      'category': (category ?? 'General').trim(),
      'tags': tags ?? [],

      'createdBy': uid,

      /// 🔥 ADMIN APPROVAL SYSTEM
      'status': 'pending',

      /// If publishNow=true → Launch now
      /// Else → Schedule
      'launchDate': publishNow ? serverNow : fallbackLaunch,

      /// Safe counters (allowed only on create)
      'upvoteCount': 0,
      'commentCount': 0,
      'shareCount': 0,
      'views': 0,

      'createdAt': serverNow,
      'updatedAt': serverNow,
    });

    // Upload images
    String? logoUrl;
    if (logoBytes != null || logoFile != null) {
      logoUrl = await _uploadImage(
        path: "users/$uid/products/${docRef.id}/logo.jpg",
        file: logoFile,
        bytes: logoBytes,
      );
    }

    String? coverUrl;
    if (coverBytes != null || coverFile != null) {
      coverUrl = await _uploadImage(
        path: "users/$uid/products/${docRef.id}/cover.jpg",
        file: coverFile,
        bytes: coverBytes,
      );
    }

    /// 🔥 UPDATE ONLY SAFE FIELDS → ALLOWED BY RULES
    final bust = DateTime.now().millisecondsSinceEpoch;

    await docRef.update({
      if (logoUrl != null) 'logoUrl': "$logoUrl?v=$bust",
      if (coverUrl != null) 'coverUrl': "$coverUrl?v=$bust",
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Upload ANY image safely
  static Future<String> _uploadImage({
    required String path,
    XFile? file,
    Uint8List? bytes,
  }) async {
    final ref = _storage.ref(path);
    final data = bytes ?? await file!.readAsBytes();

    await ref.putData(data, SettableMetadata(contentType: "image/jpeg"));

    return await ref.getDownloadURL();
  }
}
