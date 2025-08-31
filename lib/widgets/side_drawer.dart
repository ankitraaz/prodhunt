// lib/widgets/animated_side_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:prodhunt/services/firestore_service.dart';
import 'package:prodhunt/model/user_model.dart';

class AnimatedSideDrawer extends StatefulWidget {
  final Widget child;
  const AnimatedSideDrawer({Key? key, required this.child}) : super(key: key);

  @override
  AnimatedSideDrawerState createState() => AnimatedSideDrawerState();
}

class AnimatedSideDrawerState extends State<AnimatedSideDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(-1.0, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
        );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void toggle() {
    if (_isOpen) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() => _isOpen = !_isOpen);
  }

  void close() {
    if (_isOpen) {
      _controller.reverse();
      setState(() => _isOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // main content + swipe
        GestureDetector(
          onHorizontalDragEnd: (details) {
            final v = details.primaryVelocity ?? 0;
            if (v > 300 && !_isOpen) toggle(); // swipe right -> open
            if (v < -300 && _isOpen) toggle(); // swipe left  -> close
          },
          child: widget.child,
        ),

        // overlay
        if (_isOpen)
          FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: close,
              child: Container(color: Colors.black),
            ),
          ),

        // drawer
        SlideTransition(
          position: _slideAnimation,
          child: _buildDrawerContent(),
        ),
      ],
    );
  }

  /// Drawer content with local theme override.
  /// Light: seed = deepOrange
  /// Dark : primary colors overridden to deepPurple family
  Widget _buildDrawerContent() {
    final baseTheme = Theme.of(context);
    final cs = baseTheme.colorScheme;
    final isDark = baseTheme.brightness == Brightness.dark;

    // Color scheme override for drawer (dark => purple)
    final drawerScheme = isDark
        ? cs.copyWith(
            primary: Colors.deepPurple,
            onPrimary: Colors.white,
            primaryContainer: Colors.deepPurple.shade700,
            onPrimaryContainer: Colors.white,
          )
        : cs.copyWith(
            primary: Colors.deepOrange,
            onPrimary: Colors.white,
            primaryContainer: Colors.deepOrange.shade600,
            onPrimaryContainer: Colors.white,
          );

    final drawerTheme = baseTheme.copyWith(
      colorScheme: drawerScheme,
      // surfaces
      canvasColor: cs.surface,
      scaffoldBackgroundColor: cs.surface,
      // tiles
      listTileTheme: ListTileThemeData(
        iconColor: cs.onSurface,
        textColor: cs.onSurface,
        selectedColor: drawerScheme.primary,
        selectedTileColor: drawerScheme.primary.withOpacity(0.10),
      ),
      iconTheme: IconThemeData(color: cs.onSurface),
      dividerColor: cs.outlineVariant,
      splashColor: drawerScheme.primary.withOpacity(0.12),
      highlightColor: drawerScheme.primary.withOpacity(0.08),
    );

    return Theme(
      data: drawerTheme,
      child: Material(
        // <- important for ListTile/InkWell
        color: cs.surface,
        child: Container(
          width: 280,
          height: double.infinity,
          decoration: BoxDecoration(
            color: cs.surface,
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.40) : Colors.black26,
                blurRadius: 20,
                offset: const Offset(5, 0),
              ),
            ],
            border: Border(right: BorderSide(color: cs.outlineVariant)),
          ),
          child: SafeArea(
            child: Consumer<FirestoreService>(
              builder: (_, firestoreService, __) {
                final user = firestoreService.currentUser;
                return Column(
                  children: [
                    _buildDrawerHeader(user, drawerScheme, isDark),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        children: [
                          _buildMenuItem(
                            icon: Icons.rocket_launch_outlined,
                            title: 'Launches',
                            onTap: () => _navigateToPage('/launches'),
                          ),
                          _buildMenuItem(
                            icon: Icons.category_outlined,
                            title: 'Categories',
                            onTap: () => _navigateToPage('/categories'),
                          ),
                          _buildMenuItem(
                            icon: Icons.newspaper_outlined,
                            title: 'News',
                            onTap: () => _navigateToPage('/news'),
                          ),
                          _buildMenuItem(
                            icon: Icons.forum_outlined,
                            title: 'Forums',
                            onTap: () => _navigateToPage('/forums'),
                          ),
                          _buildMenuItem(
                            icon: Icons.campaign_outlined,
                            title: 'Advertise',
                            onTap: () => _navigateToPage('/advertise'),
                          ),
                          _buildMenuItem(
                            icon: Icons.add_circle_outline,
                            title: 'Add Product',
                            onTap: () => _navigateToPage('/addProduct'),
                            isHighlighted: true,
                          ),
                          _buildMenuItem(
                            icon: Icons.notifications_outlined,
                            title: 'Notification',
                            onTap: () => _navigateToPage('/notification'),
                          ),
                          _buildMenuItem(
                            icon: Icons.keyboard_arrow_up_outlined,
                            title: 'Upvotes',
                            onTap: () => _navigateToPage('/upvotes'),
                          ),
                          _buildMenuItem(
                            icon: Icons.layers_outlined,
                            title: 'Stacks',
                            onTap: () => _navigateToPage('/stacks'),
                          ),
                          _buildMenuItem(
                            icon: Icons.timeline_outlined,
                            title: 'Activity',
                            onTap: () => _navigateToPage('/activity'),
                          ),
                          _buildMenuItem(
                            icon: Icons.person_outline,
                            title: 'Profile',
                            onTap: () =>
                                Navigator.pushNamed(context, '/profile'),
                          ),
                          const SizedBox(height: 16),
                          Divider(color: cs.outlineVariant),
                          const SizedBox(height: 8),
                          _buildMenuItem(
                            icon: Icons.settings_outlined,
                            title: 'Settings',
                            onTap: () => _navigateToPage('/settings'),
                          ),
                          _buildMenuItem(
                            icon: Icons.logout_outlined,
                            title: 'Logout',
                            onTap: _logout,
                            isDestructive: true,
                          ),
                        ],
                      ),
                    ),
                    _buildDrawerFooter(drawerScheme),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // HEADER (gradient uses drawerScheme primary / primaryContainer)
  Widget _buildDrawerHeader(
    UserModel? user,
    ColorScheme drawerScheme,
    bool isDark,
  ) {
    final photoUrl = (user?.profilePicture ?? '').trim();
    final hasPhoto = photoUrl.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [drawerScheme.primary, drawerScheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: DefaultTextStyle(
        style: TextStyle(color: drawerScheme.onPrimary),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: drawerScheme.onPrimary.withOpacity(0.15),
                  child: hasPhoto
                      ? ClipOval(
                          child: CachedNetworkImage(
                            key: ValueKey(
                              photoUrl,
                            ), // 👈 URL badle to image reload
                            imageUrl:
                                photoUrl, // (EditProfile me ?t=timestamp laga rahe ho)
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (_, __, ___) => Icon(
                              Icons.person,
                              size: 30,
                              color: drawerScheme.onPrimary,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 30,
                          color: drawerScheme.onPrimary,
                        ),
                ),

                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.username ?? 'User',
                        style: TextStyle(
                          color: drawerScheme.onPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'user@example.com',
                        style: TextStyle(
                          color: drawerScheme.onPrimary.withOpacity(0.9),
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatItem(
                  '${user?.followers.length ?? 0}',
                  'Followers',
                  drawerScheme,
                ),
                const SizedBox(width: 24),
                _buildStatItem(
                  '${user?.following.length ?? 0}',
                  'Following',
                  drawerScheme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String count, String label, ColorScheme drawerScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count,
          style: TextStyle(
            color: drawerScheme.onPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: drawerScheme.onPrimary.withOpacity(0.85),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // MENU ITEM (dark => purple accents)
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool isHighlighted = false,
    bool isActive = false,
  }) {
    final cs = Theme.of(context).colorScheme;

    final Color fg = isDestructive
        ? Colors.red
        : (isHighlighted || isActive)
        ? cs.primary
        : cs.onSurface;

    final Color? bg = (isHighlighted || isActive)
        ? cs.primary.withOpacity(0.08)
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: fg, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: fg,
            fontSize: 16,
            fontWeight: (isHighlighted || isActive)
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  Widget _buildDrawerFooter(ColorScheme drawerScheme) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Divider(color: cs.outlineVariant),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // small brand tile
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: drawerScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    'PH',
                    style: TextStyle(
                      color: drawerScheme.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Product Hunt Clone',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _navigateToPage(String route) {
    close();
    Navigator.pushNamed(context, route);
  }

  Future<void> _logout() async {
    close();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      Provider.of<FirestoreService>(context, listen: false).clearUserData();
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }
}

// Extension: control drawer from anywhere
extension DrawerExtension on BuildContext {
  void openDrawer() =>
      findAncestorStateOfType<AnimatedSideDrawerState>()?.toggle();
  void closeDrawer() =>
      findAncestorStateOfType<AnimatedSideDrawerState>()?.close();
}
