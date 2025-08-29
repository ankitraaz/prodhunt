// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  // Singletons
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Getters
  static FirebaseFirestore get firestore => _firestore;
  static FirebaseAuth get auth => _auth;
  static FirebaseStorage get storage => _storage;

  // ----- Typed collection references (Firestore v6 uses generics) -----
  static CollectionReference<Map<String, dynamic>> get usersRef =>
      _firestore.collection('users');

  static CollectionReference<Map<String, dynamic>> get productsRef =>
      _firestore.collection('products');

  static CollectionReference<Map<String, dynamic>> get categoriesRef =>
      _firestore.collection('categories');

  // Optional typed doc helpers (handy, use if you like)
  static DocumentReference<Map<String, dynamic>> userDoc(String uid) =>
      usersRef.doc(uid);

  static DocumentReference<Map<String, dynamic>> productDoc(String id) =>
      productsRef.doc(id);

  // Storage path helper (optional)
  static Reference userAvatarRef(String uid) =>
      _storage.ref('users/$uid/avatar.jpg');

  // Auth shortcuts
  static String? get currentUserId => _auth.currentUser?.uid;
  static User? get currentUser => _auth.currentUser;
  static bool get isAuthenticated => _auth.currentUser != null;
}
