// lib/ngo/ngo_dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class NgoDashboardPage extends StatelessWidget {
  const NgoDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String ngoId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Dynamic Stats Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _fetchNgoStats(ngoId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final stats = snapshot.data ?? {
                    "topDonor": "N/A",
                    "mostCollected": "N/A",
                    "pickupStreak": 0,
                  };

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        "Top Donor",
                        stats['topDonor'],
                        Icons.apartment,
                        Colors.purple,
                      ),
                      _buildStatCard(
                        "Most Collected",
                        stats['mostCollected'],
                        Icons.fastfood,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        "Pickup Streak",
                        "${stats['pickupStreak']} Days",
                        Icons.local_fire_department,
                        Colors.green,
                      ),
                    ],
                  );
                },
              ),
            ),

            _buildSectionTitle("Available Food", Icons.fastfood, Colors.green),
            _buildListingsStream(status: "Active", allowRequest: true),

            _buildSectionTitle("Pending Requests", Icons.hourglass_top, Colors.orange),
            _buildListingsStream(status: "Pending"),

            _buildSectionTitle("Completed Pickups", Icons.done_all, Colors.blue),
            _buildListingsStream(status: "Completed"),
          ],
        ),
      ),
    );
  }

  // 🔹 Fetch NGO Stats
  Future<Map<String, dynamic>> _fetchNgoStats(String ngoId) async {
    Query query = FirebaseFirestore.instance
        .collection("listings")
        .where("status", isEqualTo: "Completed");

    if (ngoId.isNotEmpty) {
      query = query.where("ngoId", isEqualTo: ngoId);
    }

    final snapshot = await query.get();
    final docs = snapshot.docs;

    if (docs.isEmpty) {
      return {
        "topDonor": "N/A",
        "mostCollected": "N/A",
        "pickupStreak": 0,
      };
    }

    // 1️⃣ Top Donor (with fallback)
    final Map<String, int> donorCounts = {};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      final donor = (data["restaurantName"] != null &&
          data["restaurantName"].toString().trim().isNotEmpty)
          ? data["restaurantName"]
          : data["restaurantId"] ?? "Unknown";

      donorCounts[donor] = (donorCounts[donor] ?? 0) + 1;
    }
    String topDonor = donorCounts.isNotEmpty
        ? donorCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : "N/A";

    // 2️⃣ Most Collected Item
    final Map<String, int> itemCounts = {};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final item = data["title"] ?? "Unknown";
      itemCounts[item] = (itemCounts[item] ?? 0) + 1;
    }
    String mostCollected = itemCounts.isNotEmpty
        ? itemCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : "N/A";

    // 3️⃣ Pickup Streak
    final dates = docs
        .map((d) {
      final ts = d["createdAt"];
      if (ts is Timestamp) return ts.toDate();
      return null;
    })
        .where((d) => d != null)
        .cast<DateTime>()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 1;
    int longestStreak = 1;
    for (int i = 1; i < dates.length; i++) {
      final diff = dates[i - 1].difference(dates[i]).inDays;
      if (diff == 1) {
        streak++;
        longestStreak = streak > longestStreak ? streak : longestStreak;
      } else {
        streak = 1;
      }
    }

    return {
      "topDonor": topDonor,
      "mostCollected": mostCollected,
      "pickupStreak": longestStreak,
    };
  }

  // 🔹 Helper: Update Listing Status
  Future<void> updateListingStatus(String listingId, String newStatus) async {
    final ngoId = FirebaseAuth.instance.currentUser?.uid;
    if (ngoId == null) return;

    await FirebaseFirestore.instance
        .collection("listings")
        .doc(listingId)
        .update({
      "status": newStatus,
      "ngoId": ngoId,
    });
  }

  // 🔹 Gradient Stat Card Widget
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Section Title with icon
  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Listings Stream Widget
  Widget _buildListingsStream({required String status, bool allowRequest = false}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("listings")
          .where("status", isEqualTo: status)
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "No $status listings available.",
              style: GoogleFonts.poppins(color: Colors.black54),
            ),
          );
        }

        final listings = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: listings.length,
          itemBuilder: (context, index) {
            final doc = listings[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: ListTile(
                leading: data['imageUrl'] != null &&
                    data['imageUrl'].toString().isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    data['imageUrl'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
                    : CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: const Icon(Icons.restaurant, color: Colors.green),
                ),
                title: Text(
                  data['title'] ?? "Food Item",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  "${data['quantity']} ${data['unit']} • ${data['location']}",
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                trailing: allowRequest
                    ? ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    await updateListingStatus(doc.id, "Pending");
                  },
                  child: const Text("Request"),
                )
                    : Chip(
                  label: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: status == "Active"
                      ? Colors.green
                      : status == "Pending"
                      ? Colors.orange
                      : Colors.blue,
                ),
              ),
            );
          },
        );
      },
    );
  }
}