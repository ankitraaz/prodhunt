import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prodhunt/services/firebase_service.dart';

class NotificationService {
  static final _notifRef = FirebaseService.firestore.collection(
    'notifications',
  );

  /// ✅ Create a new notification
  static Future<void> createNotification({
    required String userId, // jisko notify karna hai (product owner)
    required String actorId, // jisne action kiya (commenter/upvoter)
    required String actorName,
    required String actorPhoto,
    required String productId,
    required String type, // "comment" | "upvote"
    required String message,
  }) async {
    try {
      await _notifRef.add({
        'userId': userId,
        'actorId': actorId,
        'actorName': actorName,
        'actorPhoto': actorPhoto,
        'productId': productId,
        'type': type,
        'message': message,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error creating notification: $e");
    }
  }

  /// ✅ Stream for current user's notifications (latest first)
  static Stream<List<Map<String, dynamic>>> getMyNotifications() {
    final currentUserId = FirebaseService.currentUserId;
    if (currentUserId == null) {
      return const Stream.empty();
    }

    return _notifRef
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final data = doc.data();
            return {'id': doc.id, ...data};
          }).toList(),
        );
  }

  /// ✅ Mark notification as read
  static Future<void> markAsRead(String notifId) async {
    try {
      await _notifRef.doc(notifId).update({'read': true});
    } catch (e) {
      print("Error marking notification as read: $e");
    }
  }
}
