// lib/models/trending_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TrendingProduct {
  final String productId;
  final int rank;
  final int upvoteCount;
  final String productName;
  final String productTagline;
  final String productLogo;
  final String creatorUsername;
  final DateTime productLaunchDate;

  TrendingProduct({
    required this.productId,
    required this.rank,
    required this.upvoteCount,
    required this.productName,
    required this.productTagline,
    required this.productLogo,
    required this.creatorUsername,
    required this.productLaunchDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'rank': rank,
      'upvoteCount': upvoteCount,
      'productName': productName,
      'productTagline': productTagline,
      'productLogo': productLogo,
      'creatorUsername': creatorUsername,
      'productLaunchDate': Timestamp.fromDate(productLaunchDate),
    };
  }

  factory TrendingProduct.fromMap(Map<String, dynamic> map) {
    return TrendingProduct(
      productId: map['productId'] ?? '',
      rank: map['rank']?.toInt() ?? 0,
      upvoteCount: map['upvoteCount']?.toInt() ?? 0,
      productName: map['productName'] ?? '',
      productTagline: map['productTagline'] ?? '',
      productLogo: map['productLogo'] ?? '',
      creatorUsername: map['creatorUsername'] ?? '',
      productLaunchDate: map['productLaunchDate'] is Timestamp
          ? (map['productLaunchDate'] as Timestamp).toDate()
          : DateTime.parse(map['productLaunchDate']),
    );
  }

  TrendingProduct copyWith({
    String? productId,
    int? rank,
    int? upvoteCount,
    String? productName,
    String? productTagline,
    String? productLogo,
    String? creatorUsername,
    DateTime? productLaunchDate,
  }) {
    return TrendingProduct(
      productId: productId ?? this.productId,
      rank: rank ?? this.rank,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      productName: productName ?? this.productName,
      productTagline: productTagline ?? this.productTagline,
      productLogo: productLogo ?? this.productLogo,
      creatorUsername: creatorUsername ?? this.creatorUsername,
      productLaunchDate: productLaunchDate ?? this.productLaunchDate,
    );
  }

  @override
  String toString() {
    return 'TrendingProduct(rank: $rank, productName: $productName, upvotes: $upvoteCount)';
  }
}

class TrendingModel {
  final String trendingId; // Document ID (usually date string)
  final DateTime date;
  final List<TrendingProduct> topProducts;
  final DateTime generatedAt;
  final String period; // 'daily', 'weekly', 'monthly'
  final int totalProducts;

  TrendingModel({
    required this.trendingId,
    required this.date,
    required this.topProducts,
    required this.generatedAt,
    this.period = 'daily',
    required this.totalProducts,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'topProducts': topProducts.map((product) => product.toMap()).toList(),
      'generatedAt': Timestamp.fromDate(generatedAt),
      'period': period,
      'totalProducts': totalProducts,
    };
  }

  // Create from Firestore Document
  factory TrendingModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    List<TrendingProduct> products = [];
    if (data['topProducts'] != null) {
      products = (data['topProducts'] as List)
          .map((productData) => TrendingProduct.fromMap(productData))
          .toList();
    }

    return TrendingModel(
      trendingId: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      topProducts: products,
      generatedAt: (data['generatedAt'] as Timestamp).toDate(),
      period: data['period'] ?? 'daily',
      totalProducts: data['totalProducts']?.toInt() ?? 0,
    );
  }

  // Create from Map
  factory TrendingModel.fromMap(Map<String, dynamic> map, String documentId) {
    List<TrendingProduct> products = [];
    if (map['topProducts'] != null) {
      products = (map['topProducts'] as List)
          .map((productData) => TrendingProduct.fromMap(productData))
          .toList();
    }

    return TrendingModel(
      trendingId: documentId,
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.parse(map['date']),
      topProducts: products,
      generatedAt: map['generatedAt'] is Timestamp
          ? (map['generatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['generatedAt']),
      period: map['period'] ?? 'daily',
      totalProducts: map['totalProducts']?.toInt() ?? 0,
    );
  }

  // Copy with new values
  TrendingModel copyWith({
    String? trendingId,
    DateTime? date,
    List<TrendingProduct>? topProducts,
    DateTime? generatedAt,
    String? period,
    int? totalProducts,
  }) {
    return TrendingModel(
      trendingId: trendingId ?? this.trendingId,
      date: date ?? this.date,
      topProducts: topProducts ?? this.topProducts,
      generatedAt: generatedAt ?? this.generatedAt,
      period: period ?? this.period,
      totalProducts: totalProducts ?? this.totalProducts,
    );
  }

  // Get top N products
  List<TrendingProduct> getTop(int count) {
    return topProducts.take(count).toList();
  }

  // Get product by rank
  TrendingProduct? getProductByRank(int rank) {
    try {
      return topProducts.firstWhere((product) => product.rank == rank);
    } catch (e) {
      return null;
    }
  }

  // Check if product is in top rankings
  bool isProductTrending(String productId) {
    return topProducts.any((product) => product.productId == productId);
  }

  // Get product rank
  int? getProductRank(String productId) {
    try {
      return topProducts
          .firstWhere((product) => product.productId == productId)
          .rank;
    } catch (e) {
      return null;
    }
  }

  // Format date for document ID
  String get dateId =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  String toString() {
    return 'TrendingModel(date: $dateId, period: $period, totalProducts: $totalProducts, topCount: ${topProducts.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrendingModel && other.trendingId == trendingId;
  }

  @override
  int get hashCode => trendingId.hashCode;
}
