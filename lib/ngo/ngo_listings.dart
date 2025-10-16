import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NgoListingsPage extends StatelessWidget {
  const NgoListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        fontFamily: 'Roboto', // ✅ Use built-in font (no fetching needed)
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: const Text(
            "Available Listings",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("listings")
              .where("status", isEqualTo: "Active")
              .orderBy("createdAt", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text("No active listings available right now."),
              );
            }

            final listings = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: listings.length,
              itemBuilder: (context, index) {
                final doc = listings[index];
                final data = doc.data() as Map<String, dynamic>;

                final pickupTime = (data['pickupTime'] as Timestamp).toDate();
                final formattedDate =
                DateFormat('MMM dd, yyyy • hh:mm a').format(pickupTime);

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        child: data.containsKey('imageUrl') &&
                            (data['imageUrl'] as String).isNotEmpty
                            ? ClipOval(
                          child: Image.network(
                            data['imageUrl'],
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        )
                            : const Icon(Icons.fastfood,
                            color: Colors.orange, size: 24),
                      ),
                      const SizedBox(width: 12),

                      // Food details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['title'] ?? "Food Item",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${data['quantity']} ${data['unit']} • ${data['location']}",
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
                            if (data['expiry'] != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                "Expires: ${data['expiry']}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Request Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection("listings")
                              .doc(doc.id)
                              .update({
                            "status": "Pending",
                            "ngoId":
                            "test_ngo", // TODO: replace with logged-in NGO ID
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  "You requested ${data['title'] ?? 'food'}"),
                            ),
                          );
                        },
                        child: const Text("Request"),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}