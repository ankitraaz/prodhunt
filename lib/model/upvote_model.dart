import 'package:cloud_firestore/cloud_firestore.dart';

class UpvoteModel {
  final String userId;
  final String productId;
  final DateTime createdAt;
  final Map<String, dynamic> userInfo;

  UpvoteModel({
    required this.userId,
    required this.productId,
    required this.createdAt,
    required this.userInfo,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productId': productId,
      'createdAt': Timestamp.fromDate(createdAt),
      'userInfo': userInfo,
    };
  }

  // Create from Firestore Document
  factory UpvoteModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UpvoteModel(
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      userInfo: Map<String, dynamic>.from(data['userInfo'] ?? {}),
    );
  }

  // Create from Map
  factory UpvoteModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UpvoteModel(
      userId: map['userId'] ?? '',
      productId: map['productId'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt']),
      userInfo: Map<String, dynamic>.from(map['userInfo'] ?? {}),
    );
  }

  // Copy with new values
  UpvoteModel copyWith({
    String? userId,
    String? productId,
    DateTime? createdAt,
    Map<String, dynamic>? userInfo,
  }) {
    return UpvoteModel(
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      createdAt: createdAt ?? this.createdAt,
      userInfo: userInfo ?? this.userInfo,
    );
  }

  @override
  String toString() {
    return 'UpvoteModel(userId: $userId, productId: $productId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpvoteModel &&
        other.userId == userId &&
        other.productId == productId;
  }

  @override
  int get hashCode {
    return userId.hashCode ^ productId.hashCode;
  }
}
