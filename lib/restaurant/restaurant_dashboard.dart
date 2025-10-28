import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RestaurantDashboardPage extends StatelessWidget {
  const RestaurantDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Stats Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _fetchDashboardStats(uid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final stats = snapshot.data!;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        "Donation Streak",
                        "${stats['donationStreak']} Days",
                        Icons.local_fire_department,
                        Colors.red,
                      ),
                      _buildStatCard(
                        "Top Donated",
                        stats['topDonated'] ?? "N/A",
                        Icons.fastfood,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        "NGOs Served",
                        "${stats['ngosServed']}",
                        Icons.volunteer_activism,
                        Colors.green,
                      ),
                    ],
                  );
                },
              ),
            ),

            _buildSectionTitle("Active Listings", Icons.check_circle, Colors.green),
            _buildListingsStream(uid: uid, status: "Active"),

            _buildSectionTitle("Pending Requests", Icons.hourglass_top, Colors.orange),
            _buildPendingRequestsStream(uid),

            _buildSectionTitle("Completed Donations", Icons.done_all, Colors.blue),
            _buildListingsStream(uid: uid, status: "Completed"),
          ],
        ),
      ),
    );
  }

  // 🔹 Dashboard Stats
  Future<Map<String, dynamic>> _fetchDashboardStats(String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("listings")
        .where("restaurantId", isEqualTo: uid)
        .where("status", isEqualTo: "Completed")
        .get();

    final docs = snapshot.docs;
    if (docs.isEmpty) {
      return {
        "donationStreak": 0,
        "topDonated": "N/A",
        "ngosServed": 0,
      };
    }

    final dates = docs
        .map((d) => (d["createdAt"] as Timestamp).toDate())
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 1;
    for (int i = 1; i < dates.length; i++) {
      final diff = dates[i - 1].difference(dates[i]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }

    final Map<String, int> itemCounts = {};
    for (var doc in docs) {
      final title = doc["title"] ?? "Unknown";
      itemCounts[title] = (itemCounts[title] ?? 0) + 1;
    }

    String topDonated = itemCounts.entries.isNotEmpty
        ? itemCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : "N/A";

    final ngoIds = docs.map((d) => d["ngoId"]).toSet();
    int ngosServed = ngoIds.length;

    return {
      "donationStreak": streak,
      "topDonated": topDonated,
      "ngosServed": ngosServed,
    };
  }

  // 🔹 Stat Card
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
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Section Title
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

  // 🔹 Active/Completed Listings Stream
  Widget _buildListingsStream({required String uid, required String status}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("listings")
          .where("restaurantId", isEqualTo: uid)
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
            child: Text("No $status listings available.",
                style: GoogleFonts.poppins(color: Colors.black54)),
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
            final remaining = data['remainingQuantity'] ?? data['quantity'];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.shade100,
                  child: const Icon(Icons.fastfood, color: Colors.orange),
                ),
                title: Text(data['title'] ?? "Food Item",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  "${data['quantity']} ${data['unit']} • ${data['location']} • Remaining: $remaining",
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                trailing: Chip(
                  label: Text(
                    status,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: status == "Active"
                      ? Colors.green
                      : Colors.blue,
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 🔹 Pending Requests Stream (with fixed logic)
  Widget _buildPendingRequestsStream(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("listings")
          .where("restaurantId", isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final allDocs = snapshot.data!.docs;
        final pendingDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final pending = data["pendingRequests"];
          if (pending == null) return false;
          final pendingList = List<Map<String, dynamic>>.from(
              (pending as List).map((e) => Map<String, dynamic>.from(e)));
          return pendingList.any((r) => r['status'] != "Completed");
        }).toList();

        if (pendingDocs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text("No pending requests.",
                style: GoogleFonts.poppins(color: Colors.black54)),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pendingDocs.length,
          itemBuilder: (context, index) {
            final doc = pendingDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final pendingList = List<Map<String, dynamic>>.from(
                (data["pendingRequests"] ?? [])
                    .map((e) => Map<String, dynamic>.from(e)));

            final activeRequests =
            pendingList.where((r) => r['status'] != "Completed").toList();

            return Column(
              children: activeRequests.map((req) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade100,
                      child: const Icon(Icons.volunteer_activism,
                          color: Colors.orange),
                    ),
                    title: Text(
                      "${req['ngoName']} requested ${req['requestedQuantity']} ${data['unit']}",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(data['title'] ?? "Food Item",
                        style: GoogleFonts.poppins(fontSize: 13)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        final listingRef = FirebaseFirestore.instance
                            .collection("listings")
                            .doc(doc.id);

                        final updatedRequests =
                        List<Map<String, dynamic>>.from(pendingList);

                        // 🔹 Mark this NGO request completed
                        final indexToUpdate = updatedRequests
                            .indexWhere((r) => r['ngoId'] == req['ngoId']);
                        if (indexToUpdate != -1) {
                          updatedRequests[indexToUpdate]['status'] = "Completed";
                        }

                        // 🔹 Calculate new remaining quantity
                        final totalRequested = updatedRequests.fold<num>(
                          0,
                              (sum, r) => sum + (r['status'] == "Completed"
                              ? (r['requestedQuantity'] ?? 0)
                              : 0),
                        );
                        final totalQuantity = (data['quantity'] ?? 0) as num;
                        final remaining = (totalQuantity - totalRequested).clamp(0, totalQuantity);

                        // 🔹 Determine status
                        final newStatus =
                        remaining == 0 ? "Completed" : "Active";

                        await listingRef.update({
                          "pendingRequests": updatedRequests,
                          "remainingQuantity": remaining,
                          "status": newStatus,
                        });
                      },
                      child: const Text("Complete"),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
