import 'package:flutter/material.dart';
import 'package:prodhunt/services/user_service.dart';
import 'package:prodhunt/model/user_model.dart';
import 'package:prodhunt/widgets/edit_username.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👇 Real-time username stream
            StreamBuilder<UserModel?>(
              stream: UserService.currentUserStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (!snapshot.hasData) {
                  return const Text("No user data");
                }
                final user = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "@${user.username}",
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text("Edit username"),
                      onPressed: () async {
                        final changed = await showDialog<bool>(
                          context: context,
                          builder: (_) => EditUsernameDialog(
                            initialUsername: user.username,
                          ),
                        );
                        if (changed == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Username updated successfully"),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
