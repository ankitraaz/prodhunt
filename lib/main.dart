// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:prodhunt/pages/activity_page.dart';
import 'package:prodhunt/pages/add_product.dart';
import 'package:prodhunt/pages/admin_panel.dart';

import 'package:prodhunt/pages/advertise.dart';
import 'package:prodhunt/pages/news_page.dart';
import 'package:prodhunt/pages/notification_page.dart';
import 'package:prodhunt/pages/profile_page.dart';
import 'package:prodhunt/pages/settings_page.dart';
import 'package:prodhunt/pages/upvote_page.dart';
import 'package:prodhunt/provider/theme_provider.dart';

import 'package:prodhunt/utils/app_theme.dart';
import 'package:provider/provider.dart';

import 'package:prodhunt/Auth/auth.dart';
import 'package:prodhunt/pages/homepage.dart';
import 'package:prodhunt/services/firestore_service.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FirestoreService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Product Hunt',
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      home: const _AuthGate(),
      routes: {
        '/auth': (_) => const AuthScreen(),
        '/home': (_) => HomePage(),
        '/profile': (_) => const ProfilePage(),
        '/addProduct': (_) => const AddProduct(),
        '/notification': (_) => const NotificationPage(),
        '/advertise': (_) => const AdvertisePage(),
        '/settings': (_) => const SettingsPage(),
        '/upvotes': (_) => const UpvotePage(),
        '/homepage': (_) => const HomePage(),
        '/news': (_) => const NewsPage(),
        '/activity': (context) => const ActivityPage(),
        '/admin': (context) => const AdminDashboardPage(),
      },
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.6),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Loading Product Hunt...',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        }

        if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: Card(
                elevation: 0,
                color: cs.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 56, color: cs.error),
                        const SizedBox(height: 12),
                        Text(
                          'Something went wrong!',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snap.error}',
                          style: TextStyle(color: cs.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: () =>
                              (context as Element).markNeedsBuild(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        if (snap.hasData) {
          return Consumer<FirestoreService>(
            builder: (_, fs, __) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (fs.currentUser == null && !fs.isLoading) {
                  fs.getCurrentUserProfile();
                }
              });
              return HomePage();
            },
          );
        }

        return const AuthScreen();
      },
    );
  }
}
