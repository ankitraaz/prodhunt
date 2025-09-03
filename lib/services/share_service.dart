import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:prodhunt/services/firebase_service.dart';

class ShareService {
  static Future<void> shareProduct({
    required String productId,
    required String title,
    required String deepLink,
  }) async {
    await Share.share('$title\n$deepLink');

    final ref = FirebaseService.productsRef.doc(productId);
    await FirebaseService.firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = (snap.data() ?? {}) as Map<String, dynamic>;
      final current = (data['shareCount'] ?? 0) as int;
      tx.update(ref, {
        'shareCount': current + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Stream<int> shareCountStream(String productId) {
    return FirebaseService.productsRef.doc(productId).snapshots().map((d) {
      if (!d.exists) return 0;
      return ((d.data() ?? const {}) as Map<String, dynamic>)['shareCount'] ??
          0;
    });
  }
}
