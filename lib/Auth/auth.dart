import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prodhunt/model/user_model.dart';

import 'package:prodhunt/pages/homepage.dart';
import 'package:prodhunt/services/firebase_service.dart';
import 'package:prodhunt/services/user_service.dart';

final _auth = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
      _emailCtrl.clear();
      _passwordCtrl.clear();
      _usernameCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text; // keep as-is
    final username = _usernameCtrl.text.trim().toLowerCase();

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (!mounted) return;
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => HomePage()));
      } else {
        // 1) Username uniqueness
        final exists = await UserService.checkUsernameExists(username);
        if (exists) {
          _showSnack('This username is already taken. Try another one.');
          setState(() => _isLoading = false);
          return;
        }

        // 2) Create auth user
        final cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // 3) Keep FirebaseAuth displayName in sync (optional but nice)
        await cred.user?.updateDisplayName(username);

        // 4) Create Firestore user via service (handles arrays, counts, timestamps)
        final model = UserModel(
          userId: cred.user!.uid,
          username: username,
          email: email,
          displayName: username,
        );
        await UserService.createUserProfile(model);

        // 5) Navigate to app
        if (!mounted) return;
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => HomePage()));
      }
    } on FirebaseAuthException catch (e) {
      _showSnack(_friendlyError(e));
    } catch (e) {
      _showSnack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Use a stronger password (6+ characters).';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Subtle gradient background (auto adapts to theme)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [cs.surface, cs.surfaceVariant.withOpacity(.6)]
                    : [cs.surface, cs.primaryContainer.withOpacity(.4)],
              ),
            ),
          ),

          // Decorative blob + blur for modern look
          Positioned(
            top: -80,
            right: -60,
            child: _Blob(color: cs.primary.withOpacity(.25), size: 220),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: _Blob(color: cs.secondary.withOpacity(.20), size: 180),
          ),

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  elevation: 0,
                  color: cs.surface.withOpacity(isDark ? .6 : .7),
                  shadowColor: cs.shadow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Logo / Title
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: cs.primaryContainer,
                                    child: Icon(
                                      Icons.rocket_launch,
                                      color: cs.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _isLogin
                                        ? 'Welcome back'
                                        : 'Create your account',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Email
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Email address',
                                  prefixIcon: Icon(Icons.mail_outline),
                                ),
                                validator: (v) {
                                  final val = (v ?? '').trim();
                                  if (val.isEmpty || !val.contains('@')) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Username (signup only)
                              if (!_isLogin) ...[
                                TextFormField(
                                  controller: _usernameCtrl,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Username',
                                    prefixIcon: Icon(Icons.alternate_email),
                                    hintText: 'lowercase, 4+ chars',
                                  ),
                                  validator: (v) {
                                    final val = (v ?? '').trim();
                                    if (val.length < 4)
                                      return 'Minimum 4 characters';
                                    final ok = RegExp(
                                      r'^[a-z0-9_]+$',
                                    ).hasMatch(val.toLowerCase());
                                    if (!ok)
                                      return 'Use lowercase letters, numbers, _ only';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Password
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                  ),
                                ),
                                validator: (v) {
                                  final val = (v ?? '');
                                  if (val.trim().length < 6)
                                    return 'At least 6 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),

                              // Submit
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: _isLoading ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(_isLogin ? 'Login' : 'Sign up'),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Toggle
                              TextButton(
                                onPressed: _isLoading ? null : _toggleMode,
                                child: Text(
                                  _isLogin
                                      ? "Don't have an account? Create one"
                                      : "Already have an account? Sign in",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.25),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}
