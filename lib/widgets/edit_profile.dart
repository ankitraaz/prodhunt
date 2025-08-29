import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:prodhunt/services/firebase_service.dart';
import 'package:prodhunt/services/user_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _form = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController(); // displayName
  final _usernameCtrl = TextEditingController(); // username
  final _headlineCtrl = TextEditingController(); // free text
  final _aboutCtrl = TextEditingController(); // bio
  final _launchedCtrl = TextEditingController(); // launched (free)
  final _collectionCtrl = TextEditingController(); // collection (free)

  bool _saving = false;
  bool _initOnce = false;
  String _avatarUrl = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _headlineCtrl.dispose();
    _aboutCtrl.dispose();
    _launchedCtrl.dispose();
    _collectionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final uid = FirebaseService.currentUserId;
    if (uid == null) return;

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 95,
    );
    if (picked == null) return;

    setState(() => _saving = true);
    try {
      // compress to jpeg (~1MB) to avoid iOS "message too long"
      Uint8List? jpeg = await FlutterImageCompress.compressWithFile(
        picked.path,
        quality: 82,
        minWidth: 1024,
        keepExif: false,
        format: CompressFormat.jpeg,
      );
      jpeg ??= await picked.readAsBytes();

      final ref = FirebaseStorage.instance.ref('users/$uid/avatar.jpg');
      await ref.putData(jpeg, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();

      await FirebaseService.usersRef.doc(uid).update({
        'profilePicture': url,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => _avatarUrl = url);
      _snack('Photo updated');
    } catch (e) {
      _snack('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removeAvatar() async {
    final uid = FirebaseService.currentUserId;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      try {
        await FirebaseStorage.instance.ref('users/$uid/avatar.jpg').delete();
      } catch (_) {}
      await FirebaseService.usersRef.doc(uid).update({
        'profilePicture': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => _avatarUrl = '');
      _snack('Photo removed');
    } catch (e) {
      _snack('Failed to remove photo: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;

    final uid = FirebaseService.currentUserId;
    if (uid == null) return;

    final name = _nameCtrl.text.trim();
    final username = _usernameCtrl.text.trim().toLowerCase();
    final headline = _headlineCtrl.text.trim();
    final bio = _aboutCtrl.text.trim();
    final launched = _launchedCtrl.text.trim();
    final collection = _collectionCtrl.text.trim();

    setState(() => _saving = true);

    try {
      // if username changed -> go via service (validates + uniqueness + auth sync)
      final snap = await FirebaseService.usersRef.doc(uid).get();
      final data = (snap.data() as Map<String, dynamic>?) ?? {};
      final currentUsername = (data['username'] ?? '').toString();

      if (username != currentUsername) {
        await UserService.updateUsername(username);
      }

      // other fields (do NOT touch role/isAdmin/createdAt)
      final patch = <String, dynamic>{
        'displayName': name,
        'bio': bio,
        'headline': headline,
        'launched': launched,
        'collection': collection,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await FirebaseService.usersRef.doc(uid).update(patch);

      if (!mounted) return;
      _snack('Profile saved');
      Navigator.pop(context);
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final uid = FirebaseService.currentUserId;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: cs.onSurface),
        title: const Text('Edit profile'),
      ),
      body: uid == null
          ? const Center(child: Text('Not signed in'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseService.usersRef
                  .doc(uid)
                  .snapshots()
                  .cast<DocumentSnapshot<Map<String, dynamic>>>(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snap.data?.data() ?? {};

                if (!_initOnce) {
                  _nameCtrl.text = (data['displayName'] ?? '').toString();
                  _usernameCtrl.text = (data['username'] ?? '').toString();
                  _headlineCtrl.text = (data['headline'] ?? '').toString();
                  _aboutCtrl.text = (data['bio'] ?? '').toString();
                  _launchedCtrl.text = (data['launched'] ?? '').toString();
                  _collectionCtrl.text = (data['collection'] ?? '').toString();
                  _avatarUrl = (data['profilePicture'] ?? '').toString();
                  _initOnce = true;
                }

                return Form(
                  key: _form,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: cs.surfaceVariant,
                          backgroundImage: _avatarUrl.isNotEmpty
                              ? NetworkImage(_avatarUrl)
                              : null,
                          child: _avatarUrl.isEmpty
                              ? Icon(
                                  Icons.person,
                                  color: cs.onSurfaceVariant,
                                  size: 36,
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton(
                              onPressed: _saving ? null : _removeAvatar,
                              child: const Text('Remove photo'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: _saving ? null : _pickAndUploadAvatar,
                              child: const Text('Change photo'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        _LabeledField(
                          label: 'Name',
                          child: TextFormField(
                            controller: _nameCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'Your name',
                            ),
                            validator: (v) => (v?.trim().length ?? 0) > 60
                                ? 'Keep it under 60 characters'
                                : null,
                          ),
                        ),
                        _LabeledField(
                          label: 'Username',
                          child: TextFormField(
                            controller: _usernameCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'lowercase, 4+ chars',
                            ),
                            validator: (v) {
                              final val = (v ?? '').trim().toLowerCase();
                              if (val.length < 4) return 'Min 4 characters';
                              if (!RegExp(r'^[a-z0-9_]+$').hasMatch(val)) {
                                return 'Only lowercase, numbers, _';
                              }
                              return null;
                            },
                          ),
                        ),
                        _LabeledField(
                          label: 'Headline',
                          child: TextFormField(
                            controller: _headlineCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'e.g., Indie maker at X',
                            ),
                            validator: (v) => (v?.trim().length ?? 0) > 100
                                ? 'Max 100 characters'
                                : null,
                          ),
                        ),
                        _LabeledField(
                          label: 'About',
                          child: TextFormField(
                            controller: _aboutCtrl,
                            minLines: 3,
                            maxLines: 6,
                            maxLength: 280,
                            textInputAction: TextInputAction.newline,
                            decoration: const InputDecoration(
                              hintText: 'Tell people about yourself…',
                            ),
                          ),
                        ),
                        _LabeledField(
                          label: 'Launched',
                          child: TextFormField(controller: _launchedCtrl),
                        ),
                        _LabeledField(
                          label: 'Collection',
                          child: TextFormField(controller: _collectionCtrl),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _saving ? null : _save,
                            child: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
