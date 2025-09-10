import 'package:flutter/material.dart';
import 'package:prodhunt/services/notification_service.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: NotificationService.getMyNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No notifications yet"));
          }

          final notifs = snapshot.data!;

          return ListView.separated(
            itemCount: notifs.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: cs.outlineVariant),
            itemBuilder: (context, index) {
              final n = notifs[index];
              final isUnread = !(n['read'] ?? false);

              return ListTile(
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: cs.surfaceContainerHighest,
                  backgroundImage:
                      (n['actorPhoto'] != null &&
                          n['actorPhoto'].toString().isNotEmpty)
                      ? NetworkImage(n['actorPhoto'])
                      : null,
                  child:
                      (n['actorPhoto'] == null ||
                          n['actorPhoto'].toString().isEmpty)
                      ? Icon(Icons.person, color: cs.onSurfaceVariant)
                      : null,
                ),
                title: Text(
                  n['message'] ?? '',
                  style: TextStyle(
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    color: cs.onSurface,
                  ),
                ),
                subtitle: Text(
                  n['type'] == "comment"
                      ? "💬 Comment"
                      : n['type'] == "upvote"
                      ? "⬆️ Upvote"
                      : "🔔 Notification",
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                trailing: isUnread
                    ? Icon(Icons.fiber_new, color: cs.primary, size: 20)
                    : null,
                onTap: () async {
                  // Mark as read
                  if (n['id'] != null) {
                    await NotificationService.markAsRead(n['id']);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
