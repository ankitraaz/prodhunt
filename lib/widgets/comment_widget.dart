import 'package:flutter/material.dart';
import 'package:prodhunt/model/comment_model.dart';
import 'package:prodhunt/services/comment_service.dart';
import 'package:prodhunt/services/firebase_service.dart';

class CommentWidget extends StatelessWidget {
  final String productId;
  const CommentWidget({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CommentModel>>(
      stream: CommentService.getProductComments(productId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Failed to load comments'),
          );
        }

        final comments = snapshot.data ?? [];
        if (comments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text('No comments yet.'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          itemBuilder: (context, i) {
            final comment = comments[i];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CommentTile(productId: productId, comment: comment),
                // Replies (indented)
                Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: StreamBuilder<List<CommentModel>>(
                    stream: CommentService.getCommentReplies(
                      productId,
                      comment.commentId,
                    ),
                    builder: (context, replySnap) {
                      final replies = replySnap.data ?? [];
                      if (replies.isEmpty) return const SizedBox.shrink();

                      return Column(
                        children: replies
                            .map(
                              (r) => _CommentTile(
                                productId: productId,
                                comment: r,
                                isReply: true,
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  final String productId;
  final CommentModel comment;
  final bool isReply;

  const _CommentTile({
    required this.productId,
    required this.comment,
    this.isReply = false,
  });

  String _safe(dynamic v) => (v ?? '').toString();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMine = comment.userId == FirebaseService.currentUserId;

    final username = _safe(
      comment.userInfo['username']?.toString().isNotEmpty == true
          ? comment.userInfo['username']
          : comment.userInfo['displayName'],
    );

    final avatarUrl = _safe(comment.userInfo['profilePicture']);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: CircleAvatar(
        radius: 18,
        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
        child: avatarUrl.isEmpty ? const Icon(Icons.person) : null,
      ),
      title: Text(
        username.isEmpty ? 'Unknown User' : username,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        comment.isDeleted ? 'Comment deleted' : comment.content,
        style: TextStyle(
          color: comment.isDeleted ? cs.onSurfaceVariant : cs.onSurface,
          fontStyle: comment.isDeleted ? FontStyle.italic : FontStyle.normal,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!comment.isDeleted) ...[
            // Reply button
            IconButton(
              icon: const Icon(Icons.reply, size: 18),
              tooltip: 'Reply',
              onPressed: () {
                _showReplyDialog(context, productId, comment.commentId);
              },
            ),
            if (isMine)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditDialog(context, productId, comment);
                  } else if (value == 'delete') {
                    _showDeleteDialog(context, productId, comment.commentId);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
          ],
        ],
      ),
    );
  }

  /* ---------------- Dialogs ---------------- */

  void _showReplyDialog(
    BuildContext context,
    String productId,
    String parentCommentId,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reply'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter reply'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                await CommentService.addComment(
                  productId,
                  text,
                  parentCommentId: parentCommentId,
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Reply'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    String productId,
    CommentModel comment,
  ) {
    final controller = TextEditingController(text: comment.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter new content'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty) {
                await CommentService.updateComment(
                  productId,
                  comment.commentId,
                  newContent,
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    String productId,
    String commentId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await CommentService.deleteComment(productId, commentId);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
