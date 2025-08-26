import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class SaveService {
  static CollectionReference _savesCol(String uid) =>
      FirebaseService.usersRef.doc(uid).collection('saves');

  static Future<bool> toggleSave(String productId) async {
    final uid = FirebaseService.currentUserId;
    if (uid == null) return false;

    final ref = _savesCol(uid).doc(productId);
    final snap = await ref.get();

    if (snap.exists) {
      await ref.delete();
      return false; // unsaved
    } else {
      await ref.set({
        'productId': productId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true; // saved
    }
  }

  static Stream<bool> isSaved(String productId) {
    final uid = FirebaseService.currentUserId;
    if (uid == null) return const Stream.empty();
    return _savesCol(uid).doc(productId).snapshots().map((d) => d.exists);
  }

  static Stream<List<String>> savedProductIds() {
    final uid = FirebaseService.currentUserId;
    if (uid == null) return const Stream.empty();
    return _savesCol(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((q) => q.docs.map((d) => d.id).toList());
  }
}
