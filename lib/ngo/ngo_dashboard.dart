import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

class NgoDashboardPage extends StatefulWidget {
  const NgoDashboardPage({super.key});

  @override
  State<NgoDashboardPage> createState() => _NgoDashboardPageState();
}

class _NgoDashboardPageState extends State<NgoDashboardPage> {
  Position? _ngoPosition;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) return;

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() => _ngoPosition = position);
    } catch (e) {
      debugPrint("Location Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final String ngoId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== NGO STATS SECTION =====
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
                      _buildStatCard("Top Donor", stats['topDonor'],
                          Icons.apartment, Colors.purple),
                      _buildStatCard("Most Collected", stats['mostCollected'],
                          Icons.fastfood, Colors.orange),
                      _buildStatCard(
                          "Pickup Streak",
                          "${stats['pickupStreak']} Days",
                          Icons.local_fire_department,
                          Colors.green),
                    ],
                  );
                },
              ),
            ),

            // ===== ACTIVE LISTINGS =====
            _buildSectionTitle("Available Food", Icons.fastfood, Colors.green),
            _buildListingsStream(status: "Active", allowRequest: true),

            // ===== NGO'S PENDING REQUESTS =====
            _buildSectionTitle(
                "Pending Requests", Icons.hourglass_top, Colors.orange),
            _buildNgoRequestStream(ngoId, "Pending"),

            // ===== NGO'S COMPLETED REQUESTS =====
            _buildSectionTitle(
                "Completed Pickups", Icons.done_all, Colors.blue),
            _buildNgoRequestStream(ngoId, "Completed"),
          ],
        ),
      ),
    );
  }

  // ===== STATS SECTION =====
  Future<Map<String, dynamic>> _fetchNgoStats(String ngoId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("listings")
        .where("status", isEqualTo: "Completed")
        .get();

    final docs = snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final requests = (data["pendingRequests"] ?? []) as List;
      return requests.any(
              (r) => r["ngoId"] == ngoId && r["status"] == "Completed");
    }).toList();

    if (docs.isEmpty) {
      return {
        "topDonor": "N/A",
        "mostCollected": "N/A",
        "pickupStreak": 0,
      };
    }

    final Map<String, int> donorCounts = {};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final donor = (data["restaurantName"] ?? "Unknown").toString();
      donorCounts[donor] = (donorCounts[donor] ?? 0) + 1;
    }

    String topDonor = donorCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    final Map<String, int> itemCounts = {};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final item = data["title"] ?? "Unknown";
      itemCounts[item] = (itemCounts[item] ?? 0) + 1;
    }

    String mostCollected = itemCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return {
      "topDonor": topDonor,
      "mostCollected": mostCollected,
      "pickupStreak": docs.length,
    };
  }

  // ===== UPDATE LISTING STATUS WHEN NGO REQUESTS =====
  Future<void> updateListingStatus(
      String listingId, String newStatus, int requestedQuantity) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ngoId = user.uid;
    final ngoDoc =
    await FirebaseFirestore.instance.collection('ngos').doc(ngoId).get();
    final ngoData = ngoDoc.exists ? ngoDoc.data() as Map<String, dynamic> : {};

    final ngoName = ngoData['name'] ?? "Unknown NGO";
    final ngoEmail = ngoData['email'] ?? "";

    final listingRef =
    FirebaseFirestore.instance.collection("listings").doc(listingId);
    final listingDoc = await listingRef.get();
    if (!listingDoc.exists) return;

    final data = listingDoc.data()!;
    final int totalQuantity = data['quantity'] ?? 0;
    final int currentRemaining = data['remainingQuantity'] ?? totalQuantity;
    final List<dynamic> pendingRequests = data['pendingRequests'] ?? [];

    // Prevent duplicate pending request
    final existingRequestIndex = pendingRequests.indexWhere(
          (r) => r['ngoId'] == ngoId && r['status'] == "Pending",
    );

    if (existingRequestIndex != -1) {
      debugPrint("NGO already has a pending request for this item.");
      return;
    }

    // Subtract quantity once at request creation
    final int newRemaining = max(0, currentRemaining - requestedQuantity);

    final newRequest = {
      "ngoId": ngoId,
      "ngoName": ngoName,
      "ngoEmail": ngoEmail,
      "requestedQuantity": requestedQuantity,
      "requestedAt": Timestamp.now(),
      "status": "Pending"
    };

    pendingRequests.add(newRequest);

    await listingRef.update({
      "remainingQuantity": newRemaining,
      "pendingRequests": pendingRequests,
      "status": newRemaining <= 0 ? "Pending" : "Active",
    });
  }

  // ===== STAT CARD =====
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
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
              Text(value,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Text(title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  // ===== SECTION TITLE =====
  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  // ===== LISTINGS STREAM =====
  Widget _buildListingsStream(
      {required String status, bool allowRequest = false}) {
    Query query = FirebaseFirestore.instance
        .collection("listings")
        .where("status", isEqualTo: status);

    return StreamBuilder<QuerySnapshot>(
      stream: query.orderBy("createdAt", descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator()));
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final remaining = data['remainingQuantity'] ?? data['quantity'];
          return status != "Active" || (remaining != null && remaining > 0);
        }).toList();

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text("No $status listings available.",
                style: GoogleFonts.poppins(color: Colors.black54)),
          );
        }

        return _buildListingListFromDocs(docs, status, allowRequest);
      },
    );
  }

  // ===== NGO REQUEST STREAM (Pending/Completed) =====
  Widget _buildNgoRequestStream(String ngoId, String requestStatus) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("listings")
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data!.docs;

        // ✅ FIX: also include completed listings where remainingQuantity == 0
        final filtered = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final pendingRequests = (data['pendingRequests'] ?? []) as List;
          final bool hasCompletedRequest = pendingRequests.any(
                (r) => r['ngoId'] == ngoId && r['status'] == requestStatus,
          );

          if (requestStatus == "Completed") {
            return hasCompletedRequest &&
                ((data['status'] == "Completed") ||
                    (data['remainingQuantity'] == 0));
          }
          return hasCompletedRequest;
        }).toList();

        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text("No $requestStatus requests yet.",
                style: GoogleFonts.poppins(color: Colors.black54)),
          );
        }

        return _buildListingListFromDocs(filtered, requestStatus, false);
      },
    );
  }

  // ===== CARD BUILDER =====
  Widget _buildListingListFromDocs(
      List<QueryDocumentSnapshot> docs, String status, bool allowRequest) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        final remaining = data['remainingQuantity'] ?? data['quantity'];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: const Icon(Icons.restaurant, color: Colors.green),
            ),
            title: Text(data['title'] ?? "Food Item",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            subtitle: Text(
              "${data['quantity']} ${data['unit']} • ${data['location'] ?? ''} • Remaining: $remaining",
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            trailing: allowRequest
                ? ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: remaining <= 0
                  ? null
                  : () async {
                final controller = TextEditingController();
                final quantity = await showDialog<int>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title:
                    const Text("Request Food Quantity"),
                    content: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText:
                          "Enter quantity (max $remaining)"),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, null),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          int val =
                              int.tryParse(controller.text) ?? 0;
                          val = min(val, remaining);
                          Navigator.pop(context, val);
                        },
                        child: const Text("Confirm"),
                      ),
                    ],
                  ),
                );

                if (quantity != null && quantity > 0) {
                  await updateListingStatus(
                      doc.id, "Pending", quantity);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                        Text('Request sent successfully!')),
                  );
                }
              },
              child: const Text("Request"),
            )
                : Chip(
              label: Text(
                status,
                style: const TextStyle(color: Colors.white, fontSize: 12),
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
  }
}
