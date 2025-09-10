// lib/widgets/product_card.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:prodhunt/ui/helper/product_ui_mapper.dart';
import 'package:prodhunt/services/firebase_service.dart';

// live counters
import 'package:prodhunt/services/upvote_service.dart';
import 'package:prodhunt/services/comment_service.dart';
import 'package:prodhunt/services/save_service.dart';
import 'package:prodhunt/services/share_service.dart';
import 'package:prodhunt/services/view_service.dart';

// comments UI
import 'package:prodhunt/widgets/comment_widget.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({super.key, required this.product});
  final ProductUI product;

  const ProductCard.skeleton({super.key})
    : product = const ProductUI.skeleton();

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _viewRegistered = false;

  bool get _isSkeleton => widget.product.isSkeleton;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // NOTE: हम "view" को तभी count करेंगे जब card को user interact करे (tap).
    // अगर आप scroll दिखते ही view count करना चाहते हैं, तो यहाँ register ना करें,
    // बल्कि नीचे _registerView() को tap handlers पर कॉल करें (जो हम already कर रहे हैं).
  }

  Future<void> _registerView() async {
    if (_viewRegistered || widget.product.id.isEmpty) return;
    _viewRegistered = true;
    await ViewService.registerView(widget.product.id);
  }

  void _openCommentsSheet(BuildContext context) {
    if (widget.product.id.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.80,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, controller) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Comments • ${widget.product.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(ctx).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // list
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: CommentWidget(productId: widget.product.id),
                    ),
                  ),
                ),

                // composer
                const Divider(height: 1),
                _CommentComposer(productId: widget.product.id),
              ],
            ),
          ),
        );
      },
    );
  }

  void _shareProduct(BuildContext context) {
    if (widget.product.id.isEmpty) return;
    final deepLink =
        'https://yourapp.com/p/${widget.product.id}'; // TODO: replace with your real link
    ShareService.shareProduct(
      productId: widget.product.id,
      title: widget.product.name,
      deepLink: deepLink,
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final cs = Theme.of(context).colorScheme;

    /* ---------------- Cover (product image) ---------------- */
    Widget cover() {
      if (_isSkeleton ||
          product.coverUrl == null ||
          product.coverUrl!.isEmpty) {
        return _shimmerBox(context, height: double.infinity);
      }

      return GestureDetector(
        onTap: () async {
          await _registerView();
          // TODO: यहां product details page navigation जोड़ सकते हैं।
        },
        child: Image.network(
          product.coverUrl!,
          key: ValueKey(product.coverUrl),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          frameBuilder: (context, child, frame, wasSync) {
            if (frame == null) {
              return _shimmerBox(context, height: double.infinity);
            }
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
        ),
      );
    }

    /* ---------------- Avatar + posted-by (users/<uid>) ---------------- */
    Widget postedBy() {
      if (_isSkeleton || product.creatorId.isEmpty) {
        return Row(
          children: [
            _avatarPlaceholder(cs),
            const SizedBox(width: 8),
            _skeletonLine(context, width: 120, height: 12),
          ],
        );
      }

      final userDoc = FirebaseService.usersRef.doc(product.creatorId);
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userDoc.snapshots(),
        builder: (context, snap) {
          String displayName = 'Unknown';
          String avatarUrl = '';
          if (snap.hasData && snap.data!.exists) {
            final data = snap.data!.data()!;
            avatarUrl =
                (data['profilePicture'] ??
                        data['photoURL'] ??
                        data['avatar'] ??
                        data['image'] ??
                        '')
                    .toString();
            displayName = (data['displayName'] ?? data['username'] ?? 'Unknown')
                .toString();
          }

          Widget avatar() {
            if (avatarUrl.isEmpty) return _avatarPlaceholder(cs);
            final img = Image.network(
              avatarUrl,
              key: ValueKey(avatarUrl),
              width: 28,
              height: 28,
              fit: BoxFit.cover,
              frameBuilder: (context, child, frame, _) {
                if (frame == null) {
                  return ClipOval(child: _shimmerBox(context, height: 28));
                }
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
          }

          return Row(
            children: [
              avatar(),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'by $displayName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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

          // title row (tap = register view)
          GestureDetector(
            onTap: _registerView,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(
                children: [
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
                      : StreamBuilder<int>(
                          stream: ViewService.viewsStream(product.id),
                          builder: (_, s) {
                            final val = s.data ?? product.views;
                            return Text(
                              '$val',
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            );
                          },
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
          ),

          // posted-by row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: postedBy(),
          ),

          // tags
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    children: widget.product.tags.take(3).map((t) {
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
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
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
                  // UPVOTE (live + toggle)
                  _MetricLive(
                    icon: Icons.arrow_upward_rounded,
                    stream: UpvoteService.getUpvoteCountStream(product.id),
                    fallback: product.upvotes,
                    onTap: () => UpvoteService.toggleUpvote(product.id),
                    tooltip: 'Upvote',
                  ),

                  // COMMENTS (live + opens sheet)
                  _MetricLive(
                    icon: Icons.mode_comment_outlined,
                    stream: CommentService.getCommentCount(product.id),
                    fallback: product.comments,
                    tooltip: 'Comments',
                    onTap: () {
                      _openCommentsSheet(context);
                    },
                  ),

                  // SHARE (tap to share + counter updates via service tx)
                  _MetricButton(
                    icon: Icons.share_outlined,
                    value: product.shares,
                    tooltip: 'Share',
                    onTap: () => _shareProduct(context),
                  ),

                  // SAVE (live toggle)
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
                  Container(
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
                  ),
                ],

                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.product.onMorePressed,
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

class _MetricButton extends StatelessWidget {
  const _MetricButton({
    required this.icon,
    required this.value,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final int value;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final child = Container(
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

/* ---------------- Comments composer (parent) ---------------- */

class _CommentComposer extends StatefulWidget {
  const _CommentComposer({required this.productId});
  final String productId;

  @override
  State<_CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<_CommentComposer> {
  final _controller = TextEditingController();
  bool _posting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _posting = true);
    await CommentService.addComment(widget.productId, text);
    if (!mounted) return;
    _controller.clear();
    setState(() => _posting = false);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  filled: true,
                  fillColor: cs.surfaceContainerHigh,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.outlineVariant),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _posting
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    onPressed: _post,
                    icon: const Icon(Icons.send_rounded),
                    tooltip: 'Post',
                  ),
          ],
        ),
      ),
    );
  }
}
