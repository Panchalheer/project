// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'splash_screen.dart';

// Restaurant pages
import 'restaurant/restaurant_home.dart';
import 'restaurant/restaurant_profile.dart';
import 'restaurant/restaurant_login.dart';
import 'restaurant/restaurant_registration.dart';
import 'restaurant/post_food_page.dart';
import 'restaurant/my_posts_page.dart';

// NGO pages
import 'ngo/ngo_home.dart';
import 'ngo/ngo_login.dart';
import 'ngo/ngo_profile.dart';
import 'ngo/ngo_registration.dart';
import 'ngo/chat_page.dart';

// Admin pages
import 'admin/admin_login_page.dart';
import 'admin/admin_dashboard.dart';
import 'admin/admin_setup_page.dart';

// Settings page
import 'settings/settings_page.dart';

/// 🌙 This controls light/dark theme across the whole app dynamically.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Load saved theme preference from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkMode') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(const ZeroWasteApp());
}

class ZeroWasteApp extends StatelessWidget {
  const ZeroWasteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'ZeroWaste',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            primarySwatch: Colors.green,
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 2,
            ),
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.green,
            brightness: Brightness.dark,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 2,
            ),
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const AuthGate(),

            // 🔑 Admin
            '/adminLogin': (context) => AdminLoginPage(),
            '/adminDashboard': (context) => const AdminDashboardPage(),
            '/adminSetup': (context) => const AdminSetupPage(),

            // NGO
            '/ngoHome': (context) => const NgoHomePage(),
            '/ngoLogin': (context) => NGOLoginPage(),
            '/ngoRegister': (context) => NGORegistrationPage(),
            '/ngoProfile': (context) => const NGOProfilePage(),

            // Restaurant
            '/restaurantHome': (context) => const RestaurantHomePage(),
            '/restaurantLogin': (context) => RestaurantLoginPage(),
            '/restaurantRegister': (context) => RestaurantRegistrationPage(),
            '/postFood': (context) => const PostFoodPage(),
            '/myPosts': (context) => const MyPostsPage(),
            '/restaurantProfile': (context) => RestaurantProfilePage(),

            // ⚙ Settings
            '/settings': (context) => const SettingsPage(),
          },
        );
      },
    );
  }
}

/// AuthGate decides which UI to show based on Firebase Auth + Firestore role
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<String?> _getUserRole(String uid) async {
    try {
      final adminDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (adminDoc.exists && adminDoc.data()?['role'] == 'admin') {
        return 'admin';
      }

      final restaurantDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(uid)
          .get();
      if (restaurantDoc.exists &&
          restaurantDoc.data()?['role'] == 'restaurant') {
        return 'restaurant';
      }

      final ngoDoc =
      await FirebaseFirestore.instance.collection('ngos').doc(uid).get();
      if (ngoDoc.exists && ngoDoc.data()?['role'] == 'ngo') {
        return 'ngo';
      }
    } catch (e) {
      debugPrint("❌ Error fetching role: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SplashScreen();

        final user = snapshot.data!;
        return FutureBuilder<String?>(
          future: _getUserRole(user.uid),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final role = snap.data;
            switch (role) {
              case "admin":
                return const AdminDashboardPage();
              case "ngo":
                return const NgoHomePage();
              case "restaurant":
                return const RestaurantHomePage();
              default:
                return const Scaffold(
                  body: Center(
                    child: Text(
                      "Unknown role. Contact support.",
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                  ),
                );
            }
          },
        );
      },
    );
  }
}