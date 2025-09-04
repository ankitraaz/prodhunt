import 'package:flutter/material.dart';
import 'package:prodhunt/model/product_model.dart';
import 'package:prodhunt/model/trending_model.dart';

/// UI model consumed by ProductCard
class ProductUI {
  final String id;
  final String name;
  final String category;
  final List<String> tags;

  /// Card ke top me jo large image jayegi (product cover)
  final String? coverUrl;

  /// Avatar ab user ka hoga -> iske liye creatorId chahiye
  final String creatorId;

  // metrics
  final int views;
  final int upvotes;
  final int comments;
  final int shares;
  final int saves;

  final String timeAgo;
  final VoidCallback? onMorePressed;
  final bool isSkeleton;

  const ProductUI({
    required this.id,
    required this.name,
    required this.category,
    required this.tags,
    required this.coverUrl,
    required this.creatorId,
    required this.views,
    required this.upvotes,
    required this.comments,
    required this.shares,
    required this.saves,
    required this.timeAgo,
    this.onMorePressed,
    this.isSkeleton = false,
  });

  const ProductUI.skeleton()
    : id = '',
      name = '',
      category = '',
      tags = const [],
      coverUrl = null,
      creatorId = '',
      views = 0,
      upvotes = 0,
      comments = 0,
      shares = 0,
      saves = 0,
      timeAgo = '',
      onMorePressed = null,
      isSkeleton = true;

  String get viewsLabel =>
      views >= 1000 ? '${(views / 1000).toStringAsFixed(1)}k' : '$views';
}

/// Map domain models → UI model
class ProductUIMapper {
  /// For "All Products" / "Recommendations"
  static ProductUI fromProductModel(ProductModel p) {
    final launched = p.launchDate ?? p.createdAt ?? DateTime.now();
    return ProductUI(
      id: p.productId,
      name: p.name,
      category: p.category,
      tags: p.tags,
      // coverUrl comes from Firestore field `coverUrl`
      coverUrl: (p.coverUrl.isNotEmpty ? p.coverUrl : null),
      // ⬇️ avatar ke liye creatorId pass karein (photo hum ProductCard me users/<uid> se nikaalenge)
      creatorId: p.createdBy,
      views: p.views ?? 0, // if you added views in model; else keep 0
      upvotes: p.upvoteCount,
      comments: p.commentCount,
      shares: 0,
      saves: 0,
      timeAgo: _timeAgo(launched),
      onMorePressed: () {},
    );
  }

  /// For Trending tab (TrendingModel.topProducts)
  static ProductUI fromTrending(TrendingProduct t) {
    final launched = t.productLaunchDate ?? DateTime.now();
    return ProductUI(
      id: t.productId,
      name: t.productName,
      category: '—',
      tags: const [],
      // trending me cover nahi hota, to null rehne do (UI graceful grey box dikhayega)
      coverUrl: null,
      // creatorId trending snapshot me nahi hota; blank -> placeholder avatar
      creatorId: '',
      views: 0,
      upvotes: t.upvoteCount,
      comments: 0,
      shares: 0,
      saves: 0,
      timeAgo: _timeAgo(launched),
      onMorePressed: () {},
    );
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
