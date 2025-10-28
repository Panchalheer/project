// lib/restaurant/restaurant_history.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class RestaurantHistoryPage extends StatefulWidget {
  const RestaurantHistoryPage({Key? key}) : super(key: key);

  @override
  State<RestaurantHistoryPage> createState() => _RestaurantHistoryPageState();
}

class _RestaurantHistoryPageState extends State<RestaurantHistoryPage> {
  /// Get current logged-in restaurant UID
  String get restaurantId => FirebaseAuth.instance.currentUser?.uid ?? "";

  /// Stream Firestore data for this restaurant
  Stream<QuerySnapshot> getDonationsStream() {
    if (restaurantId.isEmpty) {
      print("⚠️ No restaurant logged in");
      return const Stream.empty();
    }

    print("📡 Using restaurantId: $restaurantId");
    return FirebaseFirestore.instance
        .collection('listings')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('pickupTime', descending: true)
        .snapshots();
  }

  /// Color helper for status labels
  Color getStatusColor(String status) {
    switch (status) {
      case "Completed":
        return Colors.green;
      case "Pending":
        return Colors.orange;
      case "Cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Extract NGO name safely (handles both top-level and nested cases)
  String getNgoName(Map<String, dynamic> data) {
    // Case 1: top-level NGO name
    if (data['ngoName'] != null && data['ngoName'].toString().isNotEmpty) {
      return data['ngoName'];
    }

    // Case 2: nested inside pendingRequests[0]
    if (data['pendingRequests'] != null &&
        data['pendingRequests'] is List &&
        (data['pendingRequests'] as List).isNotEmpty) {
      final firstReq = (data['pendingRequests'] as List).first;
      if (firstReq is Map && firstReq['ngoName'] != null) {
        return firstReq['ngoName'];
      }
    }

    return "Unknown NGO";
  }

  @override
  Widget build(BuildContext context) {
    String? currentMonth;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Donation History"),
        backgroundColor: Colors.green[600],
      ),
      body: restaurantId.isEmpty
          ? const Center(
        child: Text(
          "Please log in to view your history.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : StreamBuilder<QuerySnapshot>(
        stream: getDonationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            print("📭 No donations found for restaurantId: $restaurantId");
            return const Center(
              child: Text(
                "No donation history yet.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final donations = snapshot.data!.docs;
          print(
              "✅ Found ${donations.length} donations for restaurantId: $restaurantId");

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: donations.length,
            itemBuilder: (context, index) {
              final data =
              donations[index].data() as Map<String, dynamic>;

              final pickupTime =
              (data['pickupTime'] as Timestamp?)?.toDate();
              final ngoName = getNgoName(data);
              final restaurantName =
                  data['restaurantName'] ?? "Unknown Restaurant";
              final title = data['title'] ?? "Unnamed Item";
              final quantity = data['quantity'] ?? 0;
              final unit = data['unit'] ?? "";
              final description = data['description'] ?? "";
              final status = data['status'] ?? "Pending";

              if (pickupTime == null) return const SizedBox.shrink();

              String month = DateFormat("MMMM yyyy").format(pickupTime);
              bool showMonthDivider = currentMonth != month;
              currentMonth = month;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showMonthDivider)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        month,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline dots
                      Column(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 2,
                            height:
                            index == donations.length - 1 ? 0 : 80,
                            color: Colors.grey[300],
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      // Donation Card
                      Expanded(
                        child: Card(
                          margin:
                          const EdgeInsets.symmetric(vertical: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('dd MMM, hh:mm a')
                                      .format(pickupTime),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$restaurantName → $ngoName",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Chip(
                                  label:
                                  Text("$title ($quantity $unit)"),
                                  backgroundColor: Colors.green[50],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Status: $status",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: getStatusColor(status),
                                  ),
                                ),
                                if (description.isNotEmpty)
                                  Padding(
                                    padding:
                                    const EdgeInsets.only(top: 4),
                                    child: Text(
                                      "Notes: $description",
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
