import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String productId;
  final String name;
  final String tagline;
  final String description;
  final String website;
  final String logo;
  final List<String> gallery;
  final String category;
  final List<String> tags;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime launchDate;
  final int upvoteCount;
  final int commentCount;
  final String status; // draft, published, rejected
  final bool isFeatured;
  final Map<String, dynamic> creatorInfo;

  ProductModel({
    required this.productId,
    required this.name,
    required this.tagline,
    required this.description,
    required this.website,
    required this.logo,
    this.gallery = const [],
    required this.category,
    this.tags = const [],
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.launchDate,
    this.upvoteCount = 0,
    this.commentCount = 0,
    this.status = 'draft',
    this.isFeatured = false,
    this.creatorInfo = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'tagline': tagline,
      'description': description,
      'website': website,
      'logo': logo,
      'gallery': gallery,
      'category': category,
      'tags': tags,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'launchDate': Timestamp.fromDate(launchDate),
      'upvoteCount': upvoteCount,
      'commentCount': commentCount,
      'status': status,
      'isFeatured': isFeatured,
      'creatorInfo': creatorInfo,
    };
  }

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      productId: doc.id,
      name: data['name'] ?? '',
      tagline: data['tagline'] ?? '',
      description: data['description'] ?? '',
      website: data['website'] ?? '',
      logo: data['logo'] ?? '',
      gallery: List<String>.from(data['gallery'] ?? []),
      category: data['category'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      launchDate: (data['launchDate'] as Timestamp).toDate(),
      upvoteCount: data['upvoteCount']?.toInt() ?? 0,
      commentCount: data['commentCount']?.toInt() ?? 0,
      status: data['status'] ?? 'draft',
      isFeatured: data['isFeatured'] ?? false,
      creatorInfo: Map<String, dynamic>.from(data['creatorInfo'] ?? {}),
    );
  }
}
