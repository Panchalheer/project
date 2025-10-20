import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // ✅ added

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

/// 🌙 Global theme controller
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

/// ✅ Background message handler (required for FCM)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("🔔 Background message received: ${message.notification?.title}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Initialize Firebase Messaging
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // ✅ Request notification permissions (for iOS/web)
  await messaging.requestPermission();

  // ✅ Handle background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ Get and print device token
  String? token = await messaging.getToken();
  debugPrint("📱 FCM Token: $token");

  // ✅ Optional: Save token to Firestore if logged in NGO
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await FirebaseFirestore.instance.collection('ngos').doc(user.uid).set({
      'token': token,
    }, SetOptions(merge: true));
  }

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

          // ☀ LIGHT THEME
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: Colors.green,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 2,
            ),
            cardColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.green),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.black),
            ),
            switchTheme: SwitchThemeData(
              thumbColor: MaterialStateProperty.all(Colors.green),
              trackColor: MaterialStateProperty.all(Colors.greenAccent),
            ),
          ),

          // 🌙 DARK THEME
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF121212),
              foregroundColor: Colors.white,
              elevation: 2,
            ),
            cardColor: const Color(0xFF1E1E1E),
            iconTheme: const IconThemeData(color: Colors.tealAccent),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.white),
            ),
            switchTheme: SwitchThemeData(
              thumbColor: MaterialStateProperty.all(Colors.tealAccent),
              trackColor: MaterialStateProperty.all(Colors.teal),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                foregroundColor: Colors.black,
              ),
            ),
          ),

          initialRoute: '/',
          routes: {
            '/': (context) => const AuthGate(),
            '/adminLogin': (context) => AdminLoginPage(),
            '/adminDashboard': (context) => const AdminDashboardPage(),
            '/adminSetup': (context) => const AdminSetupPage(),
            '/ngoHome': (context) => const NgoHomePage(),
            '/ngoLogin': (context) => NGOLoginPage(),
            '/ngoRegister': (context) => NGORegistrationPage(),
            '/ngoProfile': (context) => const NGOProfilePage(),
            '/restaurantHome': (context) => const RestaurantHomePage(),
            '/restaurantLogin': (context) => RestaurantLoginPage(),
            '/restaurantRegister': (context) => RestaurantRegistrationPage(),
            '/postFood': (context) => const PostFoodPage(),
            '/myPosts': (context) => const MyPostsPage(),
            '/restaurantProfile': (context) => RestaurantProfilePage(),
            '/settings': (context) => const SettingsPage(),
          },
        );
      },
    );
  }
}

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