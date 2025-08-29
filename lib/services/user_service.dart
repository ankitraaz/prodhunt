import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prodhunt/model/user_model.dart';
import 'package:prodhunt/services/firebase_service.dart';

class UserService {
  // CREATE (forces server timestamps + defaults)
  static Future<void> createUserProfile(UserModel user) async {
    try {
      await FirebaseService.usersRef.doc(user.userId).set({
        ...user.toMap(), // your fields
        'followers': <String>[],
        'following': <String>[],
        'followersCount': 0,
        'followingCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }

  // READ single
  static Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await FirebaseService.usersRef.doc(userId).get();
      if (doc.exists) return UserModel.fromFirestore(doc);
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // READ current
  static Future<UserModel?> getCurrentUserProfile() async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return null;
    return getUserProfile(userId);
  }

  // 🔴 Live current user (for real-time username, etc.)
  static Stream<UserModel?> currentUserStream() {
    final uid = FirebaseService.currentUserId;
    if (uid == null) return const Stream.empty();
    return FirebaseService.usersRef.doc(uid).snapshots().map((s) {
      if (!s.exists) return null;
      return UserModel.fromFirestore(s);
    });
  }

  // UPDATE (protect createdAt; always bump updatedAt)
  static Future<void> updateUserProfile(UserModel user) async {
    try {
      final map = user.toMap(); // by default no timestamps included
      map.remove('createdAt'); // never overwrite createdAt
      await FirebaseService.usersRef.doc(user.userId).set({
        ...map,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // UPDATE specific field
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

  // ✅ owner-safe helper (current user par hi write karega)
  static Future<void> updateMyField(String field, dynamic value) async {
    final uid = FirebaseService.currentUserId;
    if (uid == null) throw Exception('Not logged in');
    await FirebaseService.usersRef.doc(uid).update({
      field: value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ✅ Username update (validation + uniqueness + timestamps + Auth sync)
  static Future<void> updateUsername(String newUsername) async {
    final uid = FirebaseService.currentUserId;
    if (uid == null) {
      throw Exception('Not logged in');
    }

    final username = newUsername.trim().toLowerCase();

    // basic validation
    final ok = RegExp(r'^[a-z0-9_]{4,}$').hasMatch(username);
    if (!ok) {
      throw Exception(
        'Username must be 4+ chars, lowercase letters, numbers, _ only.',
      );
    }

    // current value
    final doc = await FirebaseService.usersRef.doc(uid).get();
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final current = (data['username'] ?? '').toString();

    // uniqueness (allow if unchanged)
    if (current != username) {
      final exists = await checkUsernameExists(username);
      if (exists) {
        throw Exception('This username is already taken.');
      }
    }

    // update Firestore
    await FirebaseService.usersRef.doc(uid).update({
      'username': username,
      'displayName': username, // optional mirror
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // optional: sync FirebaseAuth displayName
    try {
      await FirebaseAuth.instance.currentUser?.updateDisplayName(username);
    } catch (_) {}
  }

  // EXISTS username
  static Future<bool> checkUsernameExists(String username) async {
    try {
      final query = await FirebaseService.usersRef
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking username: $e');
      return false;
    }
  }

  // SEARCH (simple prefix)
  static Future<List<UserModel>> searchUsers(String query) async {
    try {
      final snapshot = await FirebaseService.usersRef
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThan: '$query\uf8ff')
          .limit(20)
          .get();
      return snapshot.docs.map(UserModel.fromFirestore).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // FOLLOW
  static Future<void> followUser(String targetUserId) async {
    final currentUserId = FirebaseService.currentUserId;
    if (currentUserId == null) return;
    if (currentUserId == targetUserId) return; // self-follow guard

    final users = FirebaseService.usersRef;
    final currRef = users.doc(currentUserId);
    final tgtRef = users.doc(targetUserId);

    await FirebaseService.firestore.runTransaction((tx) async {
      final currSnap = await tx.get(currRef);
      final tgtSnap = await tx.get(tgtRef);
      if (!currSnap.exists || !tgtSnap.exists) return;

      final currData = (currSnap.data() as Map<String, dynamic>?) ?? {};
      final List following = (currData['following'] is Iterable)
          ? List.from(currData['following'])
          : <dynamic>[];
      final bool alreadyFollowing = following.contains(targetUserId);

      if (!alreadyFollowing) {
        tx.update(currRef, {
          'following': FieldValue.arrayUnion([targetUserId]),
          'followingCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        tx.update(tgtRef, {
          'followers': FieldValue.arrayUnion([currentUserId]),
          'followersCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // UNFOLLOW
  static Future<void> unfollowUser(String targetUserId) async {
    final currentUserId = FirebaseService.currentUserId;
    if (currentUserId == null) return;
    if (currentUserId == targetUserId) return;

    final users = FirebaseService.usersRef;
    final currRef = users.doc(currentUserId);
    final tgtRef = users.doc(targetUserId);

    await FirebaseService.firestore.runTransaction((tx) async {
      final currSnap = await tx.get(currRef);
      final tgtSnap = await tx.get(tgtRef);
      if (!currSnap.exists || !tgtSnap.exists) return;

      final currData = (currSnap.data() as Map<String, dynamic>?) ?? {};
      final tgtData = (tgtSnap.data() as Map<String, dynamic>?) ?? {};

      final List following = (currData['following'] is Iterable)
          ? List.from(currData['following'])
          : <dynamic>[];
      final List followers = (tgtData['followers'] is Iterable)
          ? List.from(tgtData['followers'])
          : <dynamic>[];

      final bool isFollowing = following.contains(targetUserId);
      final bool targetHasCurrent = followers.contains(currentUserId);

      if (isFollowing && targetHasCurrent) {
        tx.update(currRef, {
          'following': FieldValue.arrayRemove([targetUserId]),
          'followingCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        tx.update(tgtRef, {
          'followers': FieldValue.arrayRemove([currentUserId]),
          'followersCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // DELETE
  static Future<void> deleteUserProfile(String userId) async {
    try {
      await FirebaseService.usersRef.doc(userId).delete();
    } catch (e) {
      print('Error deleting user profile: $e');
      rethrow;
    }
  }

  // STREAM: followers (users who have current userId in their "following")
  static Stream<List<UserModel>> getUserFollowers(String userId) {
    return FirebaseService.usersRef
        .where('following', arrayContains: userId)
        .snapshots()
        .map((snap) => snap.docs.map(UserModel.fromFirestore).toList());
  }

  // STREAM: following (resolve ids to UserModel)
  static Stream<List<UserModel>> getUserFollowing(String userId) {
    return FirebaseService.usersRef.doc(userId).snapshots().asyncMap((
      doc,
    ) async {
      if (!doc.exists) return <UserModel>[];
      final user = UserModel.fromFirestore(doc);
      if (user.following.isEmpty) return <UserModel>[];
      final futures = user.following.map(getUserProfile).toList();
      final results = await Future.wait(futures);
      return results.whereType<UserModel>().toList();
    });
  }
}
