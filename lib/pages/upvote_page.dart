import 'package:flutter/material.dart';
import 'package:prodhunt/services/upvote_service.dart';

class UpvotePage extends StatelessWidget {
  const UpvotePage({super.key});

  final String _productId = "AHfjRewA55qlwhbM2NCL";

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Upvoters")),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: UpvoteService.getProductUpvoters(_productId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No upvotes yet"));
          }

          final upvoters = snapshot.data!;

          return ListView.separated(
            itemCount: upvoters.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: cs.outlineVariant),
            itemBuilder: (context, index) {
              final u = upvoters[index];
              final userInfo = u['userInfo'] ?? {};
              final name =
                  userInfo['displayName'] ?? userInfo['username'] ?? "Unknown";
              final photo = userInfo['profilePicture'];

              return ListTile(
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: cs.surfaceContainerHighest,
                  backgroundImage:
                      (photo != null && photo.toString().isNotEmpty)
                      ? NetworkImage(photo)
                      : null,
                  child: (photo == null || photo.toString().isEmpty)
                      ? Icon(Icons.person, color: cs.onSurfaceVariant)
                      : null,
                ),
                title: Text(name, style: TextStyle(color: cs.onSurface)),
                subtitle: Text(
                  "Upvoted this product",
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
