import 'package:flutter/material.dart';
import 'package:prodhunt/model/product_model.dart';
import 'package:prodhunt/model/trending_model.dart';

/// UI model consumed by ProductCard
class ProductUI {
  final String id;
  final String name;
  final String category;
  final List<String> tags;
  final String? coverUrl; // hero (use gallery[0] or logo)
  final String? avatarUrl; // small logo
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
    required this.avatarUrl,
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
      avatarUrl = null,
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
    // Handle nullable launchDate safely (your updated model makes it nullable)
    final launched = p.launchDate ?? p.createdAt;
    return ProductUI(
      id: p.productId,
      name: p.name,
      category: p.category,
      tags: p.tags,
      coverUrl: (p.gallery.isNotEmpty ? p.gallery.first : p.logo),
      avatarUrl: p.logo,
      views: 2500, // TODO: map real views if you store them
      upvotes: p.upvoteCount,
      comments: p.commentCount,
      shares: 20, // TODO: map if present
      saves: 20, // TODO: map if present
      timeAgo: _timeAgo(launched ?? DateTime.now()),
      onMorePressed: () {},
    );
  }

  /// For Trending tab (TrendingModel.topProducts)
  static ProductUI fromTrending(TrendingProduct t) {
    final launched = t.productLaunchDate ?? DateTime.now();
    return ProductUI(
      id: t.productId,
      name: t.productName,
      category: '—', // category not in trending snapshot
      tags: const [],
      coverUrl: t.productLogo,
      avatarUrl: t.productLogo,
      views: 2500,
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
