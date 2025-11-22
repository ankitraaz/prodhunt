import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prodhunt/services/firebase_service.dart';

class AdminService {
  static final _products = FirebaseService.productsRef;

  /// Approve product
  static Future<void> approveProduct(String productId) async {
    await _products.doc(productId).update({
      'status': 'approved',
      'reviewedBy': FirebaseService.currentUserId,
      'reviewMessage': '',
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reject product
  static Future<void> rejectProduct(String productId, String message) async {
    await _products.doc(productId).update({
      'status': 'rejected',
      'reviewedBy': FirebaseService.currentUserId,
      'reviewMessage': message,
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get pending items stream
  static Stream<QuerySnapshot<Map<String, dynamic>>> pendingProducts() {
    return _products
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
