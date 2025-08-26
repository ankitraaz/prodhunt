import 'package:flutter/material.dart';
import 'package:prodhunt/services/user_service.dart';

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
        () => _error = "Use lowercase letters, numbers, _ (min 4 chars)",
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
      Navigator.pop(context, true); // return success flag
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst("Exception: ", ""));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Change Username"),
      content: TextField(
        controller: _ctrl,
        decoration: InputDecoration(
          labelText: "New username",
          prefixIcon: const Icon(Icons.alternate_email),
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Save"),
        ),
      ],
    );
  }
}
