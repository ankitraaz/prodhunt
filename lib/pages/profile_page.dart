import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prodhunt/model/user_model.dart';
import 'package:prodhunt/services/firebase_service.dart';
import 'package:prodhunt/services/user_service.dart';
import 'package:prodhunt/widgets/edit_profile.dart';
import 'package:prodhunt/widgets/side_drawer.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3,
      child: AnimatedSideDrawer(
        child: Scaffold(
          appBar: AppBar(
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => context.openDrawer(),
              ),
            ),
            title: const Text('My Profile'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'About'),
                Tab(text: 'Launched'),
                Tab(text: 'Collections'),
              ],
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // 🔹 Header (live)
                StreamBuilder<UserModel?>(
                  stream: UserService.currentUserStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: LinearProgressIndicator(),
                      );
                    }
                    final user = snapshot.data;
                    if (user == null) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Not signed in',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: cs.surfaceVariant,
                            child: Icon(
                              Icons.person,
                              color: cs.onSurfaceVariant,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '@${user.username}',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      'Followers: ${user.followersCount}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Following: ${user.followingCount}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: cs.secondaryContainer,
                              foregroundColor: cs.onSecondaryContainer,
                            ),
                            onPressed: () async {
                              final changed = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditProfilePage(),
                                ),
                              );
                              if (changed == true && context.mounted) {
                                ScaffoldMessenger.of(context)
                                  ..clearSnackBars()
                                  ..showSnackBar(
                                    const SnackBar(
                                      content: Text('Profile updated'),
                                    ),
                                  );
                              }
                            },
                            child: const Text('Edit'),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // 🔹 Tabs
                const Expanded(
                  child: TabBarView(
                    children: [_AboutTab(), _LaunchedTab(), CollectionsTab()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------- Tabs --------------------

class _AboutTab extends StatefulWidget {
  const _AboutTab();

  @override
  State<_AboutTab> createState() => _AboutTabState();
}

class _AboutTabState extends State<_AboutTab> {
  final _bioCtrl = TextEditingController();
  bool _saving = false;
  bool _initialized = false; // stream se first fill ke liye

  @override
  void dispose() {
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveBio() async {
    final text = _bioCtrl.text.trim();
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await UserService.updateMyField('bio', text); // 👈 helper use
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Bio saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('Failed to save bio: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<UserModel?>(
      stream: UserService.currentUserStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          );
        }
        final user = snap.data;
        if (user == null) {
          return Center(
            child: Text(
              'Not signed in',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        // first time stream value aane par controller fill karo
        if (!_initialized) {
          _bioCtrl.text = user.bio;
          _initialized = true;
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bio', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _bioCtrl,
                minLines: 3,
                maxLines: 6,
                maxLength: 280, // chahe to badha sakte ho
                decoration: InputDecoration(
                  hintText: 'Tell people about yourself…',
                  prefixIcon: const Icon(Icons.edit_outlined),
                  filled: true,
                  fillColor: cs.surfaceVariant.withOpacity(.35),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _saving ? null : _saveBio,

                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Save'),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_bioCtrl.text.length}/280',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Text('Visit', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: const [
                  _VisitChip(icon: Icons.camera_alt_outlined),
                  _VisitChip(icon: Icons.public),
                  _VisitChip(icon: Icons.link),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.mail_outline),
                label: const Text('Get in touch'),
                onPressed: () {},
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VisitChip extends StatelessWidget {
  final IconData icon;
  const _VisitChip({required this.icon});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(icon, size: 16, color: cs.onSurfaceVariant),
      label: const Text(''),
      backgroundColor: cs.surfaceVariant.withOpacity(.4),
      side: BorderSide(color: cs.outlineVariant),
    );
  }
}

class _LaunchedTab extends StatelessWidget {
  const _LaunchedTab();

  @override
  Widget build(BuildContext context) {
    // TODO: replace with your launched products query
    final q = FirebaseService.firestore
        .collection('products')
        .where('status', isEqualTo: 'launched')
        .orderBy('launchedAt', descending: true)
        .limit(50);

    return StreamBuilder<QuerySnapshot>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _ListSkeleton();
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No launches yet',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        final docs = snap.data!.docs;
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>? ?? {};
            final name = (data['name'] ?? 'Product name').toString();
            final likes = (data['likes'] is num)
                ? (data['likes'] as num).toInt()
                : 0;
            return _ProductCard(
              name: name,
              likes: likes,
              imageUrl: data['imageUrl'] as String?,
            );
          },
        );
      },
    );
  }
}

class CollectionsTab extends StatelessWidget {
  const CollectionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseService.currentUserId;
    if (uid == null) {
      return Center(
        child: Text(
          'Sign in to see your collections',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.firestore
          .collection('collections')
          .doc(uid)
          .collection('items')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ListSkeleton();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No Collections yet',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>? ?? {};
            final name = (data['name'] ?? 'Product name').toString();
            final likes = (data['likes'] is num)
                ? (data['likes'] as num).toInt()
                : 0;
            final imageUrl = data['imageUrl'] as String?;

            return Card(
              color: cs.surfaceVariant,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Image.network(imageUrl, fit: BoxFit.cover),
                          )
                        : Center(
                            child: Icon(
                              Icons.image,
                              size: 50,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                  ),
                  ListTile(
                    title: Text(
                      name,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite,
                          color: cs.onSurfaceVariant,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$likes',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// -------------------- Reusable bits --------------------

class _ProductCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final int likes;
  const _ProductCard({required this.name, this.imageUrl, required this.likes});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      color: cs.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(imageUrl!, fit: BoxFit.cover)
                : Center(
                    child: Icon(
                      Icons.image,
                      size: 40,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
          ),
          ListTile(
            dense: true,
            title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.rocket_launch_outlined,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text('$likes', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        height: 190,
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(.6),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// -------------------- Username dialog --------------------

class EditUsernameDialog extends StatefulWidget {
  final String initialUsername;
  const EditUsernameDialog({super.key, required this.initialUsername});

  @override
  State<EditUsernameDialog> createState() => _EditUsernameDialogState();
}

class _EditUsernameDialogState extends State<EditUsernameDialog> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.initialUsername;
  }

  Future<void> _save() async {
    final val = _ctrl.text.trim().toLowerCase();
    if (val.length < 4 || !RegExp(r'^[a-z0-9_]+$').hasMatch(val)) {
      setState(
        () => _error = 'Use lowercase letters, numbers, _ (min 4 chars)',
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await UserService.updateUsername(val);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change username'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'New username',
          prefixIcon: const Icon(Icons.alternate_email),
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
