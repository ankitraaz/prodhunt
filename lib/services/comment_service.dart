import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prodhunt/model/user_model.dart';
import 'package:prodhunt/services/firebase_service.dart';
import 'package:prodhunt/services/user_service.dart';

class CommentModel {
  final String commentId;
  final String userId;
  final String productId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int upvotes;
  final String? parentCommentId;
  final Map<String, dynamic> userInfo;
  final int repliesCount;

  CommentModel({
    required this.commentId,
    required this.userId,
    required this.productId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.upvotes = 0,
    this.parentCommentId,
    required this.userInfo,
    this.repliesCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productId': productId,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'upvotes': upvotes,
      'parentCommentId': parentCommentId,
      'userInfo': userInfo,
      'repliesCount': repliesCount,
    };
  }

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      commentId: doc.id,
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      upvotes: data['upvotes'] ?? 0,
      parentCommentId: data['parentCommentId'],
      userInfo: Map<String, dynamic>.from(data['userInfo'] ?? {}),
      repliesCount: data['repliesCount'] ?? 0,
    );
  }
}

class CommentService {
  // Add comment
  static Future<String?> addComment(
    String productId,
    String content, {
    String? parentCommentId,
  }) async {
    try {
      String? currentUserId = FirebaseService.currentUserId;
      if (currentUserId == null) return null;

      UserModel? currentUser = await UserService.getCurrentUserProfile();
      if (currentUser == null) return null;

      CommentModel comment = CommentModel(
        commentId: '', // Will be set by Firestore
        userId: currentUserId,
        productId: productId,
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        parentCommentId: parentCommentId,
        userInfo: {
          'username': currentUser.username,
          'displayName': currentUser.displayName,
          'profilePicture': currentUser.profilePicture,
        },
      );

      DocumentReference commentRef = await FirebaseService.productsRef
          .doc(productId)
          .collection('comments')
          .add(comment.toMap());

      // Update comment count on product
      await FirebaseService.productsRef.doc(productId).update({
        'commentCount': FieldValue.increment(1),
      });

      // If it's a reply, update parent comment reply count
      if (parentCommentId != null) {
        await FirebaseService.productsRef
            .doc(productId)
            .collection('comments')
            .doc(parentCommentId)
            .update({'repliesCount': FieldValue.increment(1)});
      }

      return commentRef.id;
    } catch (e) {
      print('Error adding comment: $e');
      return null;
    }
  }

  // Get comments for product (top-level comments only)
  static Stream<List<CommentModel>> getProductComments(String productId) {
    return FirebaseService.productsRef
        .doc(productId)
        .collection('comments')
        .where('parentCommentId', isNull: true)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommentModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get replies for a comment
  static Stream<List<CommentModel>> getCommentReplies(
    String productId,
    String parentCommentId,
  ) {
    return FirebaseService.productsRef
        .doc(productId)
        .collection('comments')
        .where('parentCommentId', isEqualTo: parentCommentId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommentModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Update comment
  static Future<bool> updateComment(
    String productId,
    String commentId,
    String newContent,
  ) async {
    try {
      await FirebaseService.productsRef
          .doc(productId)
          .collection('comments')
          .doc(commentId)
          .update({
            'content': newContent,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      return true;
    } catch (e) {
      print('Error updating comment: $e');
      return false;
    }
  }

  // Delete comment
  static Future<bool> deleteComment(String productId, String commentId) async {
    try {
      // Get comment first to check if it has replies
      DocumentSnapshot commentDoc = await FirebaseService.productsRef
          .doc(productId)
          .collection('comments')
          .doc(commentId)
          .get();

      if (!commentDoc.exists) return false;

      CommentModel comment = CommentModel.fromFirestore(commentDoc);

      // Delete all replies if it's a parent comment
      if (comment.parentCommentId == null && comment.repliesCount > 0) {
        QuerySnapshot replies = await FirebaseService.productsRef
            .doc(productId)
            .collection('comments')
            .where('parentCommentId', isEqualTo: commentId)
            .get();

        for (DocumentSnapshot replyDoc in replies.docs) {
          await replyDoc.reference.delete();
        }

        // Update product comment count (subtract replies + 1 for parent)
        await FirebaseService.productsRef.doc(productId).update({
          'commentCount': FieldValue.increment(-(comment.repliesCount + 1)),
        });
      } else {
        // It's a reply, update parent reply count
        if (comment.parentCommentId != null) {
          await FirebaseService.productsRef
              .doc(productId)
              .collection('comments')
              .doc(comment.parentCommentId!)
              .update({'repliesCount': FieldValue.increment(-1)});
        }

        // Update product comment count
        await FirebaseService.productsRef.doc(productId).update({
          'commentCount': FieldValue.increment(-1),
        });
      }

      // Delete the comment
      await FirebaseService.productsRef
          .doc(productId)
          .collection('comments')
          .doc(commentId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  // Upvote comment
  static Future<bool> upvoteComment(String productId, String commentId) async {
    try {
      await FirebaseService.productsRef
          .doc(productId)
          .collection('comments')
          .doc(commentId)
          .update({'upvotes': FieldValue.increment(1)});
      return true;
    } catch (e) {
      print('Error upvoting comment: $e');
      return false;
    }
  }

  // Get comment count for product
  static Stream<int> getCommentCount(String productId) {
    return FirebaseService.productsRef.doc(productId).snapshots().map((doc) {
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['commentCount'] ?? 0;
      }
      return 0;
    });
  }
}
