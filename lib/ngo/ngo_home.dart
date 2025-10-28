// lib/ngo/ngo_home.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

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

            // 👤 Profile Avatar (AppBar)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ngos')
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
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            NgoDashboardPage(),
            NgoListingsPage(),
            NgoHistoryPage(),
          ],
        ),
      ),
    );
  }
}
