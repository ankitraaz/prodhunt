import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:prodhunt/ui/helper/product_ui_mapper.dart';
import 'package:prodhunt/services/firebase_service.dart';

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

    /* ---------------- Cover (product image) ---------------- */
    Widget cover() {
      if (_isSkeleton ||
          product.coverUrl == null ||
          product.coverUrl!.isEmpty) {
        return _shimmerBox(context, height: double.infinity);
      }

      return Image.network(
        product.coverUrl!,
        key: ValueKey(product.coverUrl),
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        frameBuilder: (context, child, frame, wasSync) {
          if (frame == null)
            return _shimmerBox(context, height: double.infinity);
          return AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: child,
          );
        },
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : _shimmerBox(context, height: double.infinity),
        errorBuilder: (_, __, ___) => _skeletonBox(context),
      );
    }

    /* ---------------- Avatar (creator image from users/<uid>) ---------------- */
    Widget avatar() {
      if (_isSkeleton || product.creatorId.isEmpty) {
        return _avatarPlaceholder(cs);
      }

      final userDoc = FirebaseService.usersRef.doc(product.creatorId);
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userDoc.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData || !snap.data!.exists) {
            return _avatarPlaceholder(cs);
          }
          final data = snap.data!.data()!;
          final url =
              (data['profilePicture'] ??
                      data['photoURL'] ??
                      data['avatar'] ??
                      data['image'] ??
                      '')
                  as String;

          if (url.isEmpty) return _avatarPlaceholder(cs);

          final img = Image.network(
            url,
            key: ValueKey(url),
            width: 28,
            height: 28,
            fit: BoxFit.cover,
            frameBuilder: (context, child, frame, _) {
              if (frame == null)
                return ClipOval(child: _shimmerBox(context, height: 28));
              return AnimatedOpacity(
                opacity: 1,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: child,
              );
            },
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return ClipOval(child: _shimmerBox(context, height: 28));
            },
            errorBuilder: (_, __, ___) =>
                Icon(Icons.person, size: 16, color: cs.onSurface),
          );

          return CircleAvatar(
            radius: 14,
            backgroundColor: cs.surfaceContainerHighest,
            child: ClipOval(child: img),
          );
        },
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
            child: AspectRatio(aspectRatio: 16 / 9, child: cover()),
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

          // metrics row
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: [
                const SizedBox(width: 4),

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

                  StreamBuilder<bool>(
                    stream: SaveService.isSaved(product.id),
                    builder: (context, s) {
                      final saved = s.data ?? false;
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
                  _Metric(
                    icon: Icons.arrow_upward_rounded,
                    value: product.upvotes,
                  ),
                  _Metric(
                    icon: Icons.mode_comment_outlined,
                    value: product.comments,
                  ),
                  _Metric(icon: Icons.share_outlined, value: product.shares),
                  Builder(
                    builder: (context) {
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

  /* ---------------- helpers ---------------- */

  Widget _avatarPlaceholder(ColorScheme cs) => CircleAvatar(
    radius: 14,
    backgroundColor: cs.secondaryContainer,
    child: Icon(Icons.person, size: 16, color: cs.onSecondaryContainer),
  );

  Widget _shimmerBox(BuildContext context, {double? height}) {
    final c = Theme.of(context).colorScheme.surfaceContainerHigh;
    return _Shimmer(
      child: Container(height: height, color: c),
    );
  }

  Widget _skeletonBox(BuildContext context) =>
      Container(color: Theme.of(context).colorScheme.surfaceContainerHigh);

  Widget _skeletonLine(
    BuildContext context, {
    double width = 120,
    double height = 12,
  }) {
    final c = Theme.of(context).colorScheme.surfaceContainerHigh;
    return _Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _skeletonCapsule(
    BuildContext context, {
    double width = 64,
    double height = 28,
  }) {
    final c = Theme.of(context).colorScheme.surfaceContainerHigh;
    return _Shimmer(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(8),
        ),
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
      builder: (_, s) => box(s.data ?? fallback),
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

/* ---------------- Shimmer primitive ---------------- */

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});
  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHigh;
    final hi = Theme.of(context).colorScheme.surfaceContainerHighest;

    return AnimatedBuilder(
      animation: _ac,
      builder: (_, __) {
        return ShaderMask(
          shaderCallback: (rect) {
            final w = rect.width;
            final dx = (w * 1.5) * _ac.value - w * 0.5;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, hi, base],
              stops: const [0.35, 0.5, 0.65],
              transform: _GradientTranslation(dx, 0),
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

class _GradientTranslation extends GradientTransform {
  final double dx, dy;
  const _GradientTranslation(this.dx, this.dy);
  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.identity()..translate(dx, dy);
}
