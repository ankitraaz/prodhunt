import 'package:flutter/material.dart';
import 'package:prodhunt/ui/helper/product_ui_mapper.dart';

// ⬇️ NEW: services for live counts & bookmark
import 'package:prodhunt/services/upvote_service.dart';
import 'package:prodhunt/services/comment_service.dart';
import 'package:prodhunt/services/save_service.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});
  final ProductUI product;

  const ProductCard.skeleton({super.key})
    : product = const ProductUI.skeleton();

  bool get _isSkeleton => product.isSkeleton;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget image() {
      if (_isSkeleton ||
          product.coverUrl == null ||
          product.coverUrl!.isEmpty) {
        return _skeletonBox(context);
      }
      return Image.network(
        product.coverUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _skeletonBox(context),
        errorBuilder: (_, __, ___) => _skeletonBox(context),
      );
    }

    Widget avatar() {
      if (_isSkeleton ||
          product.avatarUrl == null ||
          product.avatarUrl!.isEmpty) {
        return CircleAvatar(
          radius: 14,
          backgroundColor: cs.secondaryContainer,
          child: Icon(
            Icons.auto_awesome,
            size: 16,
            color: cs.onSecondaryContainer,
          ),
        );
      }
      return CircleAvatar(
        radius: 14,
        backgroundImage: NetworkImage(product.avatarUrl!),
        backgroundColor: cs.surfaceContainerHighest,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // media
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(aspectRatio: 16 / 9, child: image()),
          ),

          // title row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                avatar(),
                const SizedBox(width: 8),
                Expanded(
                  child: _isSkeleton
                      ? _skeletonLine(context, width: 160)
                      : Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.visibility, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                _isSkeleton
                    ? _skeletonLine(context, width: 24, height: 10)
                    : Text(
                        product.viewsLabel,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                const SizedBox(width: 10),
                _isSkeleton
                    ? _skeletonLine(context, width: 40, height: 10)
                    : Text(
                        product.timeAgo,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
              ],
            ),
          ),

          // tags
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _isSkeleton
                ? Row(
                    children: [
                      _skeletonLine(context, width: 80, height: 10),
                      const SizedBox(width: 8),
                      _skeletonLine(context, width: 90, height: 10),
                      const SizedBox(width: 8),
                      _skeletonLine(context, width: 70, height: 10),
                    ],
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: -6,
                    children: product.tags.take(3).map((t) {
                      return Text(
                        '• $t',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
          ),

          // category pill
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: _isSkeleton
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: _skeletonCapsule(context, width: 160, height: 26),
                  )
                : _Pill(text: product.category),
          ),

          // metrics row (SAFE)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: [
                const SizedBox(width: 4),

                // ✅ guard: only use streams when product.id is non-empty & not skeleton
                if (!_isSkeleton && product.id.isNotEmpty) ...[
                  _MetricLive(
                    icon: Icons.arrow_upward_rounded,
                    stream: UpvoteService.getUpvoteCountStream(product.id),
                    fallback: product.upvotes,
                    onTap: () => UpvoteService.toggleUpvote(product.id),
                    tooltip: 'Upvote',
                  ),
                  _MetricLive(
                    icon: Icons.mode_comment_outlined,
                    stream: CommentService.getCommentCount(product.id),
                    fallback: product.comments,
                    tooltip: 'Comments',
                  ),
                  _Metric(icon: Icons.share_outlined, value: product.shares),

                  // Bookmark (realtime)
                  StreamBuilder<bool>(
                    stream: SaveService.isSaved(product.id),
                    builder: (context, s) {
                      final saved = s.data ?? false;
                      final cs = Theme.of(context).colorScheme;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: IconButton(
                          tooltip: saved ? 'Saved' : 'Save',
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            saved ? Icons.bookmark : Icons.bookmark_outline,
                          ),
                          onPressed: () => SaveService.toggleSave(product.id),
                        ),
                      );
                    },
                  ),
                ] else ...[
                  // 🔒 skeleton / empty id → show static placeholders (no Firestore calls)
                  _Metric(
                    icon: Icons.arrow_upward_rounded,
                    value: product.upvotes,
                  ),
                  _Metric(
                    icon: Icons.mode_comment_outlined,
                    value: product.comments,
                  ),
                  _Metric(icon: Icons.share_outlined, value: product.shares),
                  // static bookmark capsule (disabled)
                  Builder(
                    builder: (context) {
                      final cs = Theme.of(context).colorScheme;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: const Icon(Icons.bookmark_outline, size: 20),
                      );
                    },
                  ),
                ],

                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: product.onMorePressed,
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // skeleton helpers
  Widget _skeletonBox(BuildContext context) =>
      Container(color: Theme.of(context).colorScheme.surfaceContainerHigh);

  Widget _skeletonLine(
    BuildContext context, {
    double width = 120,
    double height = 12,
  }) {
    final c = Theme.of(context).colorScheme.surfaceContainerHigh;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _skeletonCapsule(
    BuildContext context, {
    double width = 64,
    double height = 28,
  }) {
    final c = Theme.of(context).colorScheme.surfaceContainerHigh;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: cs.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value});
  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.onSurface),
          const SizedBox(width: 6),
          Text(
            '$value',
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// 🔁 Live metric with StreamBuilder (+ optional onTap)
class _MetricLive extends StatelessWidget {
  const _MetricLive({
    required this.icon,
    required this.stream,
    required this.fallback,
    this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final Stream<int> stream;
  final int fallback;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget box(int val) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.onSurface),
          const SizedBox(width: 6),
          Text(
            '$val',
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    final child = StreamBuilder<int>(
      stream: stream,
      builder: (_, snap) => box(snap.data ?? fallback),
    );

    if (onTap == null) return child;

    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: child,
      ),
    );
  }
}
