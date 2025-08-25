// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:prodhunt/Auth/auth.dart';
import 'package:prodhunt/pages/homepage.dart';
import 'package:prodhunt/services/firestore_service.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Add FirestoreService for profile management
        ChangeNotifierProvider(create: (_) => FirestoreService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Product Hunt',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
          fontFamily: 'Inter',
        ),
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.deepOrange),
                      SizedBox(height: 16),
                      Text(
                        'Loading Product Hunt...',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Something went wrong!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Force rebuild
                          (context as Element).markNeedsBuild();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.hasData) {
              // 🔁 Logged-in user: Load profile and show adaptive shell
              return Consumer<FirestoreService>(
                builder: (context, firestoreService, child) {
                  // Auto-load user profile when logged in
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (firestoreService.currentUser == null &&
                        !firestoreService.isLoading) {
                      firestoreService.getCurrentUserProfile();
                    }
                  });

                  return const HomePage();
                },
              );
            }

            // 🚪 Not logged-in: show auth
            return const AuthScreen();
          },
        ),
        // Add route handling for navigation
        routes: {
          '/auth': (context) => const AuthScreen(),
          '/home': (context) => const HomePage(),
        },
      ),
    );
  }
}
