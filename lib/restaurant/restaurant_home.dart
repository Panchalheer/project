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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,

        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Row(
            children: [
              const Text(
                "Zero",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Waste",
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  "Reduce Food Waste, Save the Planet 🌍",
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.7),
                  ),
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

            // 👤 Profile Avatar
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('restaurants')
                  .doc(uid)
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
                    data["name"] != null &&
                    data["name"].toString().isNotEmpty) {
                  initial = data["name"][0].toUpperCase();
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
                          builder: (context) => const RestaurantProfilePage(),
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

        // 🌟 Floating SpeedDial FAB
        floatingActionButton: SpeedDial(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          icon: Icons.add,
          activeIcon: Icons.close,
          children: [
            SpeedDialChild(
              backgroundColor: Color(0xFFA5D6A7),
              child: const Icon(Icons.fastfood),
              label: 'Add Listing',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddListingPage()),
              ),
            ),
            SpeedDialChild(
              backgroundColor: Color(0xFFA5D6A7),
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
