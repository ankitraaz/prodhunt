import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prodhunt/model/user_model.dart';
import 'package:prodhunt/services/firebase_service.dart';

class UserService {
  // Create user profile
  static Future<void> createUserProfile(UserModel user) async {
    try {
      await FirebaseService.usersRef.doc(user.userId).set(user.toMap());
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }

  // Get user profile
  static Future<UserModel?> getUserProfile(String userId) async {
    try {
      DocumentSnapshot doc = await FirebaseService.usersRef.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Get current user profile
  static Future<UserModel?> getCurrentUserProfile() async {
    String? userId = FirebaseService.currentUserId;
    if (userId != null) {
      return await getUserProfile(userId);
    }
    return null;
  }

  // Update user profile
  static Future<void> updateUserProfile(UserModel user) async {
    try {
      await FirebaseService.usersRef.doc(user.userId).update(user.toMap());
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Update specific field
  static Future<void> updateUserField(
    String userId,
    String field,
    dynamic value,
  ) async {
    try {
      await FirebaseService.usersRef.doc(userId).update({
        field: value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user field: $e');
      rethrow;
    }
  }

  // Check if username exists
  static Future<bool> checkUsernameExists(String username) async {
    try {
      QuerySnapshot query = await FirebaseService.usersRef
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking username: $e');
      return false;
    }
  }

  // Search users by username
  static Future<List<UserModel>> searchUsers(String query) async {
    try {
      // Note: This is basic search. For advanced search, use Algolia
      QuerySnapshot snapshot = await FirebaseService.usersRef
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThan: query + 'z')
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Follow user
  static Future<void> followUser(String targetUserId) async {
    try {
      String? currentUserId = FirebaseService.currentUserId;
      if (currentUserId == null) return;

      await FirebaseService.firestore.runTransaction((transaction) async {
        // Add to current user's following list
        transaction.update(FirebaseService.usersRef.doc(currentUserId), {
          'following': FieldValue.arrayUnion([targetUserId]),
        });

        // Add to target user's followers list
        transaction.update(FirebaseService.usersRef.doc(targetUserId), {
          'followers': FieldValue.arrayUnion([currentUserId]),
        });
      });
    } catch (e) {
      print('Error following user: $e');
      rethrow;
    }
  }

  // Unfollow user
  static Future<void> unfollowUser(String targetUserId) async {
    try {
      String? currentUserId = FirebaseService.currentUserId;
      if (currentUserId == null) return;

      await FirebaseService.firestore.runTransaction((transaction) async {
        // Remove from current user's following list
        transaction.update(FirebaseService.usersRef.doc(currentUserId), {
          'following': FieldValue.arrayRemove([targetUserId]),
        });

        // Remove from target user's followers list
        transaction.update(FirebaseService.usersRef.doc(targetUserId), {
          'followers': FieldValue.arrayRemove([currentUserId]),
        });
      });
    } catch (e) {
      print('Error unfollowing user: $e');
      rethrow;
    }
  }

  // Delete user profile
  static Future<void> deleteUserProfile(String userId) async {
    try {
      await FirebaseService.usersRef.doc(userId).delete();
    } catch (e) {
      print('Error deleting user profile: $e');
      rethrow;
    }
  }

  // Get user's followers
  static Stream<List<UserModel>> getUserFollowers(String userId) {
    return FirebaseService.usersRef
        .where('following', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList(),
        );
  }

  // Get user's following
  static Stream<List<UserModel>> getUserFollowing(String userId) {
    return FirebaseService.usersRef.doc(userId).snapshots().asyncMap((
      doc,
    ) async {
      if (doc.exists) {
        UserModel user = UserModel.fromFirestore(doc);
        List<Future<UserModel?>> futures = user.following
            .map((id) => getUserProfile(id))
            .toList();

        List<UserModel?> results = await Future.wait(futures);
        return results.where((user) => user != null).cast<UserModel>().toList();
      }
      return <UserModel>[];
    });
  }
}
