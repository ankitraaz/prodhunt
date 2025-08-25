import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firebase_service.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseService.storage;

  // Upload profile picture
  static Future<String?> uploadProfilePicture(XFile imageFile) async {
    try {
      String userId = FirebaseService.currentUserId!;
      String fileName = 'profile_pictures/$userId.jpg';

      Reference ref = _storage.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(File(imageFile.path));

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }

  // Upload product logo
  static Future<String?> uploadProductLogo(
    XFile imageFile,
    String productId,
  ) async {
    try {
      String fileName = 'product_logos/$productId.jpg';

      Reference ref = _storage.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(File(imageFile.path));

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading product logo: $e');
      return null;
    }
  }

  // Upload product gallery images
  static Future<List<String>> uploadProductGallery(
    List<XFile> imageFiles,
    String productId,
  ) async {
    try {
      List<String> downloadUrls = [];

      for (int i = 0; i < imageFiles.length; i++) {
        String fileName = 'product_gallery/$productId/image_$i.jpg';

        Reference ref = _storage.ref().child(fileName);
        UploadTask uploadTask = ref.putFile(File(imageFiles[i].path));

        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        downloadUrls.add(downloadUrl);
      }

      return downloadUrls;
    } catch (e) {
      print('Error uploading product gallery: $e');
      return [];
    }
  }

  // Delete image
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }
}
