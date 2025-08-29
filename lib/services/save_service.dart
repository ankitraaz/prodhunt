import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class SaveService {
  static CollectionReference<Map<String, dynamic>> _savesCol(String uid) =>
      FirebaseService.usersRef.doc(uid).collection('saves');

  /// Toggle save/unsave for the current user. Returns true if now saved.
  static Future<bool> toggleSave(String productId) async {
    final uid = FirebaseService.currentUserId;
    if (uid == null) return false;

    try {
      final docRef = _savesCol(uid).doc(productId);
      final snap = await docRef.get();

      if (snap.exists) {
        await docRef.delete();
        return false; // now unsaved
      } else {
        await docRef.set({
          'productId': productId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true; // now saved
      }
    } catch (e) {
      // Optional: log or surface error
      return false;
    }
  }

  /// Live flag whether current user has saved a product.
  static Stream<bool> isSaved(String productId) {
    final uid = FirebaseService.currentUserId;
    if (uid == null) return const Stream.empty();

    return _savesCol(uid)
        .doc(productId)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> d) => d.exists);
  }

  /// Live list of saved product ids (newest first).
  static Stream<List<String>> savedProductIds() {
    final uid = FirebaseService.currentUserId;
    if (uid == null) return const Stream.empty();

    return _savesCol(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> q) =>
              q.docs.map((d) => d.id).toList(),
        );
  }
}
