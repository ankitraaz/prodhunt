import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prodhunt/services/firebase_service.dart';
import 'package:prodhunt/services/upvote_service.dart';

class ProductDetailPage extends StatelessWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseService.productsRef.doc(productId);

    return Scaffold(
      appBar: AppBar(title: const Text('Product')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: docRef.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('Not found'));
          }
          final data = snap.data!.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '') as String;
          final tagline = (data['tagline'] ?? '') as String;
          final upvotes = (data['upvoteCount'] ?? 0) as int;
          final comments = (data['commentCount'] ?? 0) as int;
          final ts = data['launchDate'];
          final dt = ts is Timestamp ? ts.toDate() : DateTime.tryParse('$ts');
          final dateStr = dt?.toLocal().toString().split('.').first ?? '';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(tagline, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    dateStr,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chat_bubble_outline, size: 18),
                  const SizedBox(width: 4),
                  Text('$comments'),
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    onPressed: () async =>
                        await UpvoteService.toggleUpvote(productId),
                    icon: const Icon(Icons.arrow_upward),
                    label: Text('$upvotes'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // TODO: logo/gallery, links, maker info, categories…
              const Divider(height: 32),

              // View comments
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.message_outlined),
                  label: const Text('View comments'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommentsPage(productId: productId),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Minimal comments page placeholder
class CommentsPage extends StatelessWidget {
  final String productId;
  const CommentsPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final col = FirebaseService.productsRef
        .doc(productId)
        .collection('comments')
        .where('parentCommentId', isNull: true)
        .orderBy('createdAt');

    return Scaffold(
      appBar: AppBar(title: const Text('Comments')),
      body: StreamBuilder<QuerySnapshot>(
        stream: col.snapshots(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No comments yet'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(
                  d['userInfo']?['displayName'] ??
                      d['userInfo']?['username'] ??
                      'User',
                ),
                subtitle: Text(d['content'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}
