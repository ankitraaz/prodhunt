import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prodhunt/model/user_model.dart';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  // Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      _isLoading = true;
      notifyListeners();

      User? user = _auth.currentUser;
      if (user == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        _currentUser = UserModel.fromFirestore(doc);
      }

      _isLoading = false;
      notifyListeners();
      return _currentUser;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile (complete profile)
  Future<bool> updateUserProfile(UserModel updatedUser) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore
          .collection('users')
          .doc(updatedUser.userId)
          .update(updatedUser.toMap());

      _currentUser = updatedUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Update specific field (यह backend का part था)
  Future<bool> updateUserField(String field, dynamic value) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      await _firestore.collection('users').doc(user.uid).update({
        field: value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local user object
      if (_currentUser != null) {
        switch (field) {
          case 'bio':
            _currentUser = _currentUser!.copyWith(bio: value);
            break;
          case 'username':
            _currentUser = _currentUser!.copyWith(username: value);
            break;
          case 'displayName':
            _currentUser = _currentUser!.copyWith(displayName: value);
            break;
          case 'website':
            _currentUser = _currentUser!.copyWith(website: value);
            break;
          case 'twitter':
            _currentUser = _currentUser!.copyWith(twitter: value);
            break;
          case 'linkedin':
            _currentUser = _currentUser!.copyWith(linkedin: value);
            break;
          case 'profilePicture':
            _currentUser = _currentUser!.copyWith(profilePicture: value);
            break;
        }
        notifyListeners();
      }

      return true;
    } catch (e) {
      print('Error updating user field: $e');
      return false;
    }
  }

  // Create user profile (Backend method)
  Future<bool> createUserProfile(UserModel user) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('users').doc(user.userId).set(user.toMap());

      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error creating user profile: $e');
      return false;
    }
  }

  // Check if username exists (Backend method)
  Future<bool> checkUsernameExists(String username) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking username: $e');
      return false;
    }
  }

  // Clear user data on logout
  void clearUserData() {
    _currentUser = null;
    notifyListeners();
  }
}
