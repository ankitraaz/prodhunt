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
  final String website;
  final String logo;
  final List<String> gallery;
  final String category;
  final List<String> tags;
  final String createdBy;

  /// These can be null in older/partial docs, so make them nullable.
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? launchDate;

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
    this.createdAt,
    this.updatedAt,
    this.launchDate,
    this.upvoteCount = 0,
    this.commentCount = 0,
    this.status = 'draft',
    this.isFeatured = false,
    this.creatorInfo = const {},
  });

  /// When writing, if any date is null, we simply omit it (Firestore will keep existing or you can set it before call)
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'tagline': tagline,
      'description': description,
      'website': website,
      'logo': logo,
      'gallery': gallery,
      'category': category,
      'tags': tags,
      'createdBy': createdBy,
      'upvoteCount': upvoteCount,
      'commentCount': commentCount,
      'status': status,
      'isFeatured': isFeatured,
      'creatorInfo': creatorInfo,
    };

    if (createdAt != null) map['createdAt'] = Timestamp.fromDate(createdAt!);
    if (updatedAt != null) map['updatedAt'] = Timestamp.fromDate(updatedAt!);
    if (launchDate != null) map['launchDate'] = Timestamp.fromDate(launchDate!);

    return map;
  }

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? const {};

    return ProductModel(
      productId: doc.id,
      name: (data['name'] ?? '') as String,
      tagline: (data['tagline'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      website: (data['website'] ?? '') as String,
      logo: (data['logo'] ?? '') as String,
      gallery: List<String>.from(data['gallery'] ?? const []),
      category: (data['category'] ?? '') as String,
      tags: List<String>.from(data['tags'] ?? const []),
      createdBy: (data['createdBy'] ?? data['creatorId'] ?? '') as String,

      // tolerant date parsing
      createdAt: _asDate(data['createdAt']),
      updatedAt: _asDate(data['updatedAt']),
      launchDate: _asDate(data['launchDate']),

      // ints can come as num/double
      upvoteCount: (data['upvoteCount'] is num)
          ? (data['upvoteCount'] as num).toInt()
          : 0,
      commentCount: (data['commentCount'] is num)
          ? (data['commentCount'] as num).toInt()
          : 0,

      status: (data['status'] ?? 'draft') as String,
      isFeatured: (data['isFeatured'] ?? false) as bool,
      creatorInfo: Map<String, dynamic>.from(data['creatorInfo'] ?? const {}),
    );
  }

  ProductModel copyWith({
    String? productId,
    String? name,
    String? tagline,
    String? description,
    String? website,
    String? logo,
    List<String>? gallery,
    String? category,
    List<String>? tags,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? launchDate,
    int? upvoteCount,
    int? commentCount,
    String? status,
    bool? isFeatured,
    Map<String, dynamic>? creatorInfo,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      description: description ?? this.description,
      website: website ?? this.website,
      logo: logo ?? this.logo,
      gallery: gallery ?? this.gallery,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      launchDate: launchDate ?? this.launchDate,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      commentCount: commentCount ?? this.commentCount,
      status: status ?? this.status,
      isFeatured: isFeatured ?? this.isFeatured,
      creatorInfo: creatorInfo ?? this.creatorInfo,
    );
  }
}
