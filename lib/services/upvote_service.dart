// lib/services/upvote_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prodhunt/model/user_model.dart';
import 'package:prodhunt/services/user_service.dart';

import '../services/firebase_service.dart';

class UpvoteService {
  // Toggle upvote (add if not exists, remove if exists)
  static Future<bool> toggleUpvote(String productId) async {
    try {
      String? currentUserId = FirebaseService.currentUserId;
      if (currentUserId == null) return false;

      DocumentReference upvoteRef = FirebaseService.productsRef
          .doc(productId)
          .collection('upvotes')
          .doc(currentUserId);

      DocumentReference productRef = FirebaseService.productsRef.doc(productId);

      return await FirebaseService.firestore.runTransaction((
        transaction,
      ) async {
        DocumentSnapshot upvoteSnap = await transaction.get(upvoteRef);
        DocumentSnapshot productSnap = await transaction.get(productRef);

        if (!productSnap.exists) {
          throw Exception('Product not found');
        }

        Map<String, dynamic> productData =
            productSnap.data() as Map<String, dynamic>;
        int currentUpvotes = productData['upvoteCount'] ?? 0;

        if (upvoteSnap.exists) {
          // Remove upvote
          transaction.delete(upvoteRef);
          transaction.update(productRef, {
            'upvoteCount': currentUpvotes - 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return false; // Upvote removed
        } else {
          // Add upvote
          UserModel? currentUser = await UserService.getCurrentUserProfile();

          transaction.set(upvoteRef, {
            'userId': currentUserId,
            'productId': productId,
            'createdAt': FieldValue.serverTimestamp(),
            'userInfo': {
              'username': currentUser?.username ?? 'Anonymous',
              'displayName': currentUser?.displayName ?? 'Anonymous',
              'profilePicture': currentUser?.profilePicture ?? '',
            },
          });

          transaction.update(productRef, {
            'upvoteCount': currentUpvotes + 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return true; // Upvote added
        }
      });
    } catch (e) {
      print('Error toggling upvote: $e');
      return false;
    }
  }

  // Check if current user has upvoted
  static Future<bool> hasUserUpvoted(String productId) async {
    try {
      String? currentUserId = FirebaseService.currentUserId;
      if (currentUserId == null) return false;

      DocumentSnapshot doc = await FirebaseService.productsRef
          .doc(productId)
          .collection('upvotes')
          .doc(currentUserId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking upvote status: $e');
      return false;
    }
  }

  // Get product upvoters
  static Stream<List<Map<String, dynamic>>> getProductUpvoters(
    String productId,
  ) {
    return FirebaseService.productsRef
        .doc(productId)
        .collection('upvotes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Get upvote count stream
  static Stream<int> getUpvoteCountStream(String productId) {
    return FirebaseService.productsRef.doc(productId).snapshots().map((doc) {
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['upvoteCount'] ?? 0;
      }
      return 0;
    });
  }

  // Get user's upvoted products
  static Stream<List<String>> getUserUpvotedProducts(String userId) {
    return FirebaseService.firestore
        .collectionGroup('upvotes')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data()['productId'] as String)
              .toList(),
        );
  }
}
