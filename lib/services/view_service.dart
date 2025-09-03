import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prodhunt/services/firebase_service.dart';
import 'package:prodhunt/services/viewer_id.dart';

class ViewService {
  /// 1 viewer per product only once (dedup; userId ya device-id)
  static Future<void> registerView(String productId) async {
    if (productId.isEmpty) return;

    final uid = FirebaseService.currentUserId;
    final viewerId = uid ?? await ViewerId.get();
    final productRef = FirebaseService.productsRef.doc(productId);
    final viewRef = productRef.collection('views').doc(viewerId);

    await FirebaseService.firestore.runTransaction((tx) async {
      final vSnap = await tx.get(viewRef);
      if (vSnap.exists) return; // already counted

      tx.set(viewRef, {
        'viewerId': viewerId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final pSnap = await tx.get(productRef);
      if (!pSnap.exists) return;
      final data = (pSnap.data() ?? {}) as Map<String, dynamic>;
      final curr = (data['views'] ?? 0) as int;

      tx.update(productRef, {
        'views': curr + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Stream<int> viewsStream(String productId) {
    return FirebaseService.productsRef.doc(productId).snapshots().map((d) {
      if (!d.exists) return 0;
      return ((d.data() ?? const {}) as Map<String, dynamic>)['views'] ?? 0;
    });
  }
}
