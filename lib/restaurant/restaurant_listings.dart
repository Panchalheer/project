import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class RestaurantListingsPage extends StatelessWidget {
  const RestaurantListingsPage({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _getListings() {
    final String restaurantId = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('listings')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            elevation: 1,
            bottom: const TabBar(
              indicatorColor: Colors.green,
              labelColor: Colors.green,
              unselectedLabelColor: Colors.black54,
              tabs: [
                Tab(text: "Active"),
                Tab(text: "Pending"),
                Tab(text: "Completed"),
              ],
            ),
          ),
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _getListings(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No listings found"));
            }

            final listings = snapshot.data!.docs;

            final active =
            listings.where((doc) => doc['status'] == "Active").toList();
            final pending =
            listings.where((doc) => doc['status'] == "Pending").toList();
            final completed =
            listings.where((doc) => doc['status'] == "Completed").toList();

            return TabBarView(
              children: [
                _buildList(context, active, "Active"),
                _buildList(context, pending, "Pending"),
                _buildList(context, completed, "Completed"),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List docs, String status) {
    if (docs.isEmpty) {
      return Center(child: Text("No $status listings"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];

        final pickupTime = (doc['pickupTime'] as Timestamp).toDate();
        final formattedDate =
        DateFormat('MMM dd, yyyy • hh:mm a').format(pickupTime);

        // Status colors
        Color statusColor;
        switch (status) {
          case "Active":
            statusColor = Colors.green;
            break;
          case "Pending":
            statusColor = Colors.orange;
            break;
          case "Completed":
            statusColor = Colors.grey;
            break;
          default:
            statusColor = Colors.blueGrey;
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading image/icon
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.orange.shade100,
                child: doc.data().containsKey('imageUrl') &&
                    (doc['imageUrl'] as String).isNotEmpty
                    ? ClipOval(
                  child: Image.network(
                    doc['imageUrl'],
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                )
                    : const Icon(Icons.fastfood,
                    color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 12),

              // Title + subtitle + pickup
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc['title'] ?? "Untitled",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${doc['quantity']} ${doc['unit']} • ${doc['location']}",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Pickup: $formattedDate",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Status chip
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}