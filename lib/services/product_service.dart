import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prodhunt/model/user_model.dart';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _currentUser;
  bool _isLoading = false;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  String? get _uid => _auth.currentUser?.uid;

  /// One-shot fetch of the signed-in user's profile
  Future<UserModel?> getCurrentUserProfile() async {
    if (_uid == null) return null;

    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore.collection('users').doc(_uid).get();

      if (doc.exists) {
        _currentUser = UserModel.fromFirestore(doc);
      } else {
        _currentUser = null;
      }
      return _currentUser;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Start a realtime listener for the current user's doc.
  /// Call this after sign-in (e.g., in your app bootstrap).
  void startUserListener() {
    // If no user or already listening, skip
    if (_uid == null || _userSub != null) return;

    _userSub = _firestore
        .collection('users')
        .doc(_uid)
        .snapshots()
        .listen(
          (snap) {
            if (snap.exists) {
              _currentUser = UserModel.fromFirestore(snap);
            } else {
              _currentUser = null;
            }
            notifyListeners();
          },
          onError: (e) {
            debugPrint('User stream error: $e');
          },
        );
  }

  /// Stop the realtime listener (called on logout)
  void stopUserListener() {
    _userSub?.cancel();
    _userSub = null;
  }

  /// Update the full profile safely:
  /// - never overwrite `createdAt`
  /// - always set `updatedAt` (server)
  /// - merge to avoid dropping unknown fields (and keep rules happy)
  Future<bool> updateUserProfile(UserModel updatedUser) async {
    try {
      _isLoading = true;
      notifyListeners();

      final map = updatedUser.toMap();
      map.remove('createdAt'); // do not mutate createdAt from client

      await _firestore.collection('users').doc(updatedUser.userId).set({
        ...map,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _currentUser = updatedUser;
      return true;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update a single field + bump `updatedAt`.
  /// NOTE: For username uniqueness/validation you already use UserService
  /// from your EditProfile flow; this is a simple low-level helper.
  Future<bool> updateUserField(String field, dynamic value) async {
    try {
      final uid = _uid;
      if (uid == null) return false;

      // tiny guard: keep username normalized (app-level validation stays in UserService)
      if (field == 'username' && value is String) {
        value = value.trim().toLowerCase();
      }

      await _firestore.collection('users').doc(uid).update({
        field: value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // reflect locally
      if (_currentUser != null) {
        switch (field) {
          case 'bio':
            _currentUser = _currentUser!.copyWith(bio: value as String? ?? '');
            break;
          case 'username':
            _currentUser = _currentUser!.copyWith(
              username: value as String? ?? '',
            );
            break;
          case 'displayName':
            _currentUser = _currentUser!.copyWith(
              displayName: value as String? ?? '',
            );
            break;
          case 'website':
            _currentUser = _currentUser!.copyWith(
              website: value as String? ?? '',
            );
            break;
          case 'twitter':
            _currentUser = _currentUser!.copyWith(
              twitter: value as String? ?? '',
            );
            break;
          case 'linkedin':
            _currentUser = _currentUser!.copyWith(
              linkedin: value as String? ?? '',
            );
            break;
          case 'profilePicture':
            _currentUser = _currentUser!.copyWith(
              profilePicture: value as String? ?? '',
            );
            break;
          default:
            // ignore unknown fields in local cache
            break;
        }
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error updating user field: $e');
      return false;
    }
  }

  /// Create user profile (first-time)
  Future<bool> createUserProfile(UserModel user) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('users').doc(user.userId).set({
        ...user.toMap(),
        // server timestamps—client must not set these
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _currentUser = user;
      return true;
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// App-level helper; Firestore rules don't enforce uniqueness—
  /// you already gate this in your flows.
  Future<bool> checkUsernameExists(String username) async {
    try {
      final q = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.trim().toLowerCase())
          .limit(1)
          .get();

      return q.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking username: $e');
      return false;
    }
  }

  /// Clear local cache (on logout)
  void clearUserData() {
    stopUserListener();
    _currentUser = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopUserListener();
    super.dispose();
  }
}
