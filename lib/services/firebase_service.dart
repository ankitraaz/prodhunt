// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Getters
  static FirebaseFirestore get firestore => _firestore;
  static FirebaseAuth get auth => _auth;
  static FirebaseStorage get storage => _storage;

  // Collection references
  static CollectionReference get usersRef => _firestore.collection('users');
  static CollectionReference get productsRef =>
      _firestore.collection('products');
  static CollectionReference get categoriesRef =>
      _firestore.collection('categories');

  // User reference
  static String? get currentUserId => _auth.currentUser?.uid;
  static User? get currentUser => _auth.currentUser;

  // Check if user is authenticated
  static bool get isAuthenticated => _auth.currentUser != null;
}
