// lib/restaurant/restaurant_home.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:google_fonts/google_fonts.dart';

// ✅ Import Settings Page
import '../settings/settings_page.dart';

import 'restaurant_dashboard.dart';
import 'restaurant_listings.dart';
import 'restaurant_history.dart';
import 'add_listing.dart';
import 'restaurant_profile.dart';

class RestaurantHomePage extends StatefulWidget {
  const RestaurantHomePage({super.key});

  @override
  State<RestaurantHomePage> createState() => _RestaurantHomePageState();
}

class _RestaurantHomePageState extends State<RestaurantHomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return DefaultTabController(
      length: 3,
      initialIndex: _currentIndex,
      child: Scaffold(
        appBar: AppBar(
          elevation: 2,
          backgroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ZeroWaste",
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Reduce Food Waste, Save the Planet 🌍",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black54,
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

            // 👤 CircleAvatar with Initial
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('restaurants')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final data =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final name = data['name']?.toString() ?? "U";
                final initial =
                name.isNotEmpty ? name[0].toUpperCase() : "U";

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RestaurantProfilePage(),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 16,
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
            indicator: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(25),
            ),
            labelColor: Colors.green,
            unselectedLabelColor: Colors.black54,
            labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            tabs: const [
              Tab(text: 'Dashboard'),
              Tab(text: 'My Listings'),
              Tab(text: 'History'),
            ],
          ),
        ),

        body: const TabBarView(
          children: [
            RestaurantDashboardPage(),
            RestaurantListingsPage(),
            RestaurantHistoryPage(),
          ],
        ),

        // 🌟 Floating SpeedDial FAB (bottom-right instead of docked)
        floatingActionButton: SpeedDial(
          backgroundColor: Colors.green,
          icon: Icons.add,
          activeIcon: Icons.close,
          children: [
            SpeedDialChild(
              child: const Icon(Icons.fastfood),
              label: 'Add Listing',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddListingPage()),
              ),
            ),
            SpeedDialChild(
              child: const Icon(Icons.bar_chart),
              label: 'Analytics',
              onTap: () {
                // TODO: Open analytics page
              },
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}