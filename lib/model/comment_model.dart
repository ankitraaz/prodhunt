// lib/models/comment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String commentId;
  final String userId;
  final String productId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int upvotes;
  final String? parentCommentId; // For reply system
  final Map<String, dynamic> userInfo;
  final int repliesCount;
  final bool isEdited;
  final bool isDeleted;

  CommentModel({
    required this.commentId,
    required this.userId,
    required this.productId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.upvotes = 0,
    this.parentCommentId, // null for top-level comments
    required this.userInfo,
    this.repliesCount = 0,
    this.isEdited = false,
    this.isDeleted = false,
  });

  // Convert to Map for Firestore
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
      'isEdited': isEdited,
      'isDeleted': isDeleted,
    };
  }

  // Create from Firestore Document
  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      commentId: doc.id,
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      upvotes: data['upvotes']?.toInt() ?? 0,
      parentCommentId: data['parentCommentId'],
      userInfo: Map<String, dynamic>.from(data['userInfo'] ?? {}),
      repliesCount: data['repliesCount']?.toInt() ?? 0,
      isEdited: data['isEdited'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  // Create from Map
  factory CommentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CommentModel(
      commentId: documentId,
      userId: map['userId'] ?? '',
      productId: map['productId'] ?? '',
      content: map['content'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt']),
      upvotes: map['upvotes']?.toInt() ?? 0,
      parentCommentId: map['parentCommentId'],
      userInfo: Map<String, dynamic>.from(map['userInfo'] ?? {}),
      repliesCount: map['repliesCount']?.toInt() ?? 0,
      isEdited: map['isEdited'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  // Copy with new values
  CommentModel copyWith({
    String? commentId,
    String? userId,
    String? productId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? upvotes,
    String? parentCommentId,
    Map<String, dynamic>? userInfo,
    int? repliesCount,
    bool? isEdited,
    bool? isDeleted,
  }) {
    return CommentModel(
      commentId: commentId ?? this.commentId,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      upvotes: upvotes ?? this.upvotes,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      userInfo: userInfo ?? this.userInfo,
      repliesCount: repliesCount ?? this.repliesCount,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // Helper methods
  bool get isReply => parentCommentId != null;

  bool canEdit(String currentUserId) {
    return userId == currentUserId && !isDeleted;
  }

  bool canDelete(String currentUserId, {bool isAdmin = false}) {
    return (userId == currentUserId || isAdmin) && !isDeleted;
  }

  @override
  String toString() {
    return 'CommentModel(commentId: $commentId, userId: $userId, content: $content, isReply: $isReply)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommentModel && other.commentId == commentId;
  }

  @override
  int get hashCode => commentId.hashCode;
}
