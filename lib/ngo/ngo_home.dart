// lib/ngo/ngo_home.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// ✅ Import Settings Page
import '../settings/settings_page.dart';

import 'ngo_dashboard.dart';
import 'ngo_listings.dart';
import 'ngo_history.dart';
import 'ngo_profile.dart';

class NgoHomePage extends StatefulWidget {
  const NgoHomePage({super.key});

  @override
  State<NgoHomePage> createState() => _NgoHomePageState();
}

class _NgoHomePageState extends State<NgoHomePage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    saveFcmToken();
    setupFirebaseMessagingListeners();
  }

  /// ✅ Save the current user's FCM token to Firestore
  Future<void> saveFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': fcmToken});
        debugPrint('✅ FCM Token saved for NGO: $fcmToken');
      }

      // Handle token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': newToken});
        debugPrint('🔁 Token refreshed and updated for NGO');
      });
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  /// 🔔 Listen for incoming push notifications
  void setupFirebaseMessagingListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${notification.title ?? "New Notification"}: ${notification.body ?? ""}',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final postId = message.data['postId'];
      debugPrint('🔔 NGO opened notification for post ID: $postId');
      // TODO: Navigate to post details if needed
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: _currentIndex,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Row(
            children: const [
              Text(
                "Zero",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Waste",
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            // ⚙ Settings Button
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.black87),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),

            // 🔔 Notifications Button
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.black87),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔔 Notifications are automatically received!'),
                  ),
                );
              },
            ),

            // 👤 Profile Avatar (AppBar)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ngos')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: CircleAvatar(
                      backgroundColor: Colors.grey,
                      child: Text("?", style: TextStyle(color: Colors.white)),
                    ),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>?;
                String initial = "U";

                if (data != null &&
                    data["orgName"] != null &&
                    data["orgName"].toString().isNotEmpty) {
                  initial = data["orgName"][0].toUpperCase();
                } else if (FirebaseAuth.instance.currentUser!.email != null &&
                    FirebaseAuth.instance.currentUser!.email!.isNotEmpty) {
                  initial =
                      FirebaseAuth.instance.currentUser!.email![0].toUpperCase();
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NGOProfilePage(),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          bottom: TabBar(
            indicatorColor: Colors.green,
            labelColor: Colors.green,
            unselectedLabelColor: Colors.black54,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            tabs: const [
              Tab(text: 'Dashboard'),
              Tab(text: 'Listings'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            NgoDashboardPage(),
            NgoListingsPage(),
            HistoryPage(),
          ],
        ),
      ),
    );
  }
}