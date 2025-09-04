// lib/pages/homepage.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';

import 'package:prodhunt/services/firebase_service.dart';
import 'package:prodhunt/model/product_model.dart';
import 'package:prodhunt/model/trending_model.dart';
import 'package:prodhunt/ui/helper/product_ui_mapper.dart';
import 'package:prodhunt/widgets/product_card.dart';
import 'package:prodhunt/widgets/side_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedSideDrawer(
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => context.openDrawer(),
            ),
          ),
          backgroundColor: cs.surface,
          elevation: 0,
          titleSpacing: 16,
          title: Text(
            'Product Hunt',
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          actions: [
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () {},
              icon: const Icon(Icons.search_rounded),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: cs.secondaryContainer,
                child: Icon(Icons.person, color: cs.onSecondaryContainer),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                controller: _tab,
                isScrollable: true,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                labelColor: cs.primary,
                unselectedLabelColor: cs.onSurfaceVariant,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(color: cs.primary, width: 2),
                ),
                tabs: const [
                  Tab(text: 'Trending'),
                  Tab(text: 'Recommendations'),
                  Tab(text: 'All Products'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tab,
          children: const [
            _TrendingTab(),
            _RecommendationsTab(),
            _AllProductsTab(),
          ],
        ),
      ),
    );
  }
}

/* ---------------- TRENDING (Keep-Alive) ---------------- */

class _TrendingTab extends StatefulWidget {
  const _TrendingTab();
  @override
  State<_TrendingTab> createState() => _TrendingTabState();
}

class _TrendingTabState extends State<_TrendingTab>
    with AutomaticKeepAliveClientMixin {
  String _todayUtcId() {
    final d = DateTime.now().toUtc();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final id = _todayUtcId();
    final docRef = FirebaseService.firestore
        .collection('dailyRankings')
        .doc(id);

    return StreamBuilder<DocumentSnapshot>(
      // 👇 includeMetadataChanges: cache→server transition ko capture karega
      stream: docRef.snapshots(includeMetadataChanges: true),
      builder: (context, snap) {
        final isLoading =
            snap.connectionState == ConnectionState.waiting ||
            !snap.hasData ||
            (snap.hasData &&
                !snap.data!.exists &&
                snap.data!.metadata.isFromCache);

        if (isLoading) return _skeletonList(context);

        if (snap.hasError) return _errorBox(context, 'Failed to load trending');
        if (!snap.data!.exists)
          return const Center(child: Text('No trending yet'));

        final model = TrendingModel.fromFirestore(snap.data!);
        final items = model.topProducts
            .map(ProductUIMapper.fromTrending)
            .toList();

        return _cardsList(
          items,
          onRefresh: () async {
            // force server fetch
            await docRef.get(const GetOptions(source: Source.server));
          },
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/* ---------------- RECOMMENDATIONS (Keep-Alive) ---------------- */

class _RecommendationsTab extends StatefulWidget {
  const _RecommendationsTab();
  @override
  State<_RecommendationsTab> createState() => _RecommendationsTabState();
}

class _RecommendationsTabState extends State<_RecommendationsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    final query = FirebaseService.productsRef
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt', descending: true)
        .limit(30);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(includeMetadataChanges: true),
      builder: (context, snap) {
        final isLoading =
            snap.connectionState == ConnectionState.waiting ||
            !snap.hasData ||
            (snap.hasData &&
                snap.data!.docs.isEmpty &&
                snap.data!.metadata.isFromCache);

        if (isLoading) return _skeletonList(context);

        if (snap.hasError) {
          return _errorBox(context, 'Failed to load recommendations');
        }
        if (snap.data!.docs.isEmpty) {
          return const Center(child: Text('No recommendations yet'));
        }

        final items = snap.data!.docs
            .map((d) => ProductModel.fromFirestore(d))
            .map(ProductUIMapper.fromProductModel)
            .toList();

        return _cardsList(
          items,
          onRefresh: () async {
            await query.get(const GetOptions(source: Source.server));
          },
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/* ---------------- ALL PRODUCTS (Keep-Alive) ---------------- */

class _AllProductsTab extends StatefulWidget {
  const _AllProductsTab();
  @override
  State<_AllProductsTab> createState() => _AllProductsTabState();
}

class _AllProductsTabState extends State<_AllProductsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    final query = FirebaseService.productsRef
        .where('status', isEqualTo: 'published')
        .orderBy('launchDate', descending: true)
        .limit(50);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(includeMetadataChanges: true),
      builder: (context, snap) {
        final isLoading =
            snap.connectionState == ConnectionState.waiting ||
            !snap.hasData ||
            (snap.hasData &&
                snap.data!.docs.isEmpty &&
                snap.data!.metadata.isFromCache);

        if (isLoading) return _skeletonList(context);

        if (snap.hasError) return _errorBox(context, 'Failed to load products');
        if (snap.data!.docs.isEmpty)
          return const Center(child: Text('No products'));

        final items = snap.data!.docs
            .map((d) => ProductModel.fromFirestore(d))
            .map(ProductUIMapper.fromProductModel)
            .toList();

        return _cardsList(
          items,
          onRefresh: () async {
            await query.get(const GetOptions(source: Source.server));
          },
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/* ---------------- Shared UI ---------------- */

// ✅ ListView.builder + gentle slide/fade-in per item + pull-to-refresh
Widget _cardsList(
  List<ProductUI> items, {
  required Future<void> Function() onRefresh,
}) {
  return RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final w = TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.05, end: 0),
          duration: Duration(milliseconds: 180 + (i * 18).clamp(0, 180)),
          curve: Curves.easeOut,
          builder: (_, offset, child) => Transform.translate(
            offset: Offset(0, 24 * offset),
            child: Opacity(opacity: 1 - offset, child: child),
          ),
          child: ProductCard(product: items[i]),
        );
        return Padding(
          padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 14),
          child: KeyedSubtree(key: ValueKey(items[i].id), child: w),
        );
      },
    ),
  );
}

// 🔷 Skeleton list with Shimmer
Widget _skeletonList(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return ListView.separated(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
    itemCount: 6,
    itemBuilder: (_, __) => Shimmer.fromColors(
      baseColor: cs.surfaceContainerHigh,
      highlightColor: cs.surfaceContainerHighest.withOpacity(0.7),
      period: const Duration(milliseconds: 1200),
      child: const ProductCard.skeleton(),
    ),
    separatorBuilder: (_, __) => const SizedBox(height: 14),
  );
}

Widget _errorBox(BuildContext context, String msg) {
  final cs = Theme.of(context).colorScheme;
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.wifi_tethering_error, color: cs.error),
        const SizedBox(height: 8),
        Text(msg, style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => {}, // pull to refresh is available
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}
