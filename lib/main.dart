// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:prodhunt/pages/add_product.dart';
import 'package:prodhunt/pages/advertise.dart';
import 'package:prodhunt/pages/notification_page.dart';
import 'package:prodhunt/pages/profile_page.dart';
import 'package:provider/provider.dart';

import 'package:prodhunt/Auth/auth.dart';
import 'package:prodhunt/pages/homepage.dart';
import 'package:prodhunt/services/firestore_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Run AdMob initialize only on Android/iOS
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Light theme (Orange accent)
  ThemeData _lightTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFEA580C), // deepOrange-ish
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Inter',
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
    );
  }

  // Dark theme (Purple + Black accent)
  ThemeData _darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      fontFamily: 'Inter',
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: Colors.black),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => FirestoreService())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Product Hunt',
        themeMode: ThemeMode.system, // auto light/dark
        theme: _lightTheme(),
        darkTheme: _darkTheme(),
        home: const _AuthGate(),
        routes: {
          '/auth': (_) => const AuthScreen(),
          '/home': (_) => HomePage(),
          '/profile': (_) => const ProfilePage(),
          '/addProduct': (_) => const AddProduct(),
          '/notification': (_) => const NotificationPage(),
          '/advertise': (_) => const AdvertisePage(),
        },
      ),
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
          // Logged-in → ensure profile loaded once
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

        // Not logged-in → Auth
        return const AuthScreen();
      },
    );
  }
}
