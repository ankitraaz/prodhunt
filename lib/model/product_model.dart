import 'package:cloud_firestore/cloud_firestore.dart';

/// Safe converter: accepts Timestamp | DateTime | String | null
DateTime? _asDate(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

class ProductModel {
  final String productId;
  final String name;
  final String tagline;
  final String description;
  final String category;
  final List<String> tags;
  final String createdBy;

  // ✅ Image fields
  final String logoUrl;
  final String coverUrl;

  // ✅ Dates
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? launchDate;

  // ✅ Counters
  final int upvoteCount;
  final int commentCount;
  final int views;

  final String status; // draft, published, rejected

  ProductModel({
    required this.productId,
    required this.name,
    required this.tagline,
    required this.description,
    required this.category,
    this.tags = const [],
    required this.createdBy,
    this.logoUrl = '',
    this.coverUrl = '',
    this.createdAt,
    this.updatedAt,
    this.launchDate,
    this.upvoteCount = 0,
    this.commentCount = 0,
    this.views = 0,
    this.status = 'draft',
  });

  /// Firestore → Model
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? const {};

    return ProductModel(
      productId: doc.id,
      name: (data['name'] ?? '') as String,
      tagline: (data['tagline'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      category: (data['category'] ?? '') as String,
      tags: List<String>.from(data['tags'] ?? const []),
      createdBy: (data['createdBy'] ?? '') as String,

      logoUrl: (data['logoUrl'] ?? '') as String,
      coverUrl: (data['coverUrl'] ?? '') as String,

      createdAt: _asDate(data['createdAt']),
      updatedAt: _asDate(data['updatedAt']),
      launchDate: _asDate(data['launchDate']),

      upvoteCount: (data['upvoteCount'] is num)
          ? (data['upvoteCount'] as num).toInt()
          : 0,
      commentCount: (data['commentCount'] is num)
          ? (data['commentCount'] as num).toInt()
          : 0,
      views: (data['views'] is num) ? (data['views'] as num).toInt() : 0,

      status: (data['status'] ?? 'draft') as String,
    );
  }

  /// Model → Firestore map
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'tagline': tagline,
      'description': description,
      'category': category,
      'tags': tags,
      'createdBy': createdBy,
      'logoUrl': logoUrl,
      'coverUrl': coverUrl,
      'upvoteCount': upvoteCount,
      'commentCount': commentCount,
      'views': views,
      'status': status,
    };

    if (createdAt != null) map['createdAt'] = Timestamp.fromDate(createdAt!);
    if (updatedAt != null) map['updatedAt'] = Timestamp.fromDate(updatedAt!);
    if (launchDate != null) map['launchDate'] = Timestamp.fromDate(launchDate!);

    return map;
  }

  ProductModel copyWith({
    String? productId,
    String? name,
    String? tagline,
    String? description,
    String? category,
    List<String>? tags,
    String? createdBy,
    String? logoUrl,
    String? coverUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? launchDate,
    int? upvoteCount,
    int? commentCount,
    int? views,
    String? status,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      createdBy: createdBy ?? this.createdBy,
      logoUrl: logoUrl ?? this.logoUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      launchDate: launchDate ?? this.launchDate,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      commentCount: commentCount ?? this.commentCount,
      views: views ?? this.views,
      status: status ?? this.status,
    );
  }
}
