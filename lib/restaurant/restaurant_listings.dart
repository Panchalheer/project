// lib/restaurant/restaurant_listings_page.dart
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
        final data = doc.data() as Map<String, dynamic>;

        final pickupTime = (data['pickupTime'] as Timestamp).toDate();
        final formattedDate =
        DateFormat('MMM dd, yyyy • hh:mm a').format(pickupTime);

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['title'] ?? "Untitled",
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
                      ],
                    ),
                  ),

                  // Status & actions
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
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
                      if (status == "Active") ...[
                        const SizedBox(height: 4),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20),
                          onSelected: (value) async {
                            if (value == 'edit') {
                              _editListing(context, doc.id, data);
                            } else if (value == 'delete') {
                              _deleteListing(context, doc.id);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // NGO Info
              if (data['ngoId'] == null)
                const Text(
                  "No NGO requests yet.",
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                )
              else
                FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance
                      .collection('ngos')
                      .doc(data['ngoId'])
                      .get(),
                  builder: (context, ngoSnapshot) {
                    if (ngoSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: LinearProgressIndicator(minHeight: 2),
                      );
                    }

                    if (!ngoSnapshot.hasData || !ngoSnapshot.data!.exists) {
                      return const Text(
                        "NGO details not found.",
                        style: TextStyle(color: Colors.redAccent, fontSize: 13),
                      );
                    }

                    final ngoData =
                    ngoSnapshot.data!.data() as Map<String, dynamic>;

                    return Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.volunteer_activism,
                              color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "${ngoData['name'] ?? 'NGO'} • ${ngoData['email'] ?? ''}",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (data['requestedQuantity'] != null)
                            Text(
                              "Req: ${data['requestedQuantity']} ${data['unit']}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // Delete listing
  Future<void> _deleteListing(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text('Are you sure you want to delete this listing?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
              const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('listings')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing deleted successfully')),
      );
    }
  }

  // Edit listing
  Future<void> _editListing(
      BuildContext context, String docId, Map<String, dynamic> data) async {
    final titleController = TextEditingController(text: data['title']);
    final quantityController =
    TextEditingController(text: data['quantity'].toString());
    final unitController = TextEditingController(text: data['unit']);
    final locationController = TextEditingController(text: data['location']);
    DateTime selectedTime = (data['pickupTime'] as Timestamp).toDate();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Listing'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: unitController,
                    decoration: const InputDecoration(labelText: 'Unit'),
                  ),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        "Pickup: ${DateFormat('MMM dd, yyyy • hh:mm a').format(selectedTime)}",
                        style: const TextStyle(fontSize: 13),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.calendar_today, size: 20),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedTime,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime:
                              TimeOfDay.fromDateTime(selectedTime),
                            );
                            if (time != null) {
                              setState(() {
                                selectedTime = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('listings')
                      .doc(docId)
                      .update({
                    'title': titleController.text.trim(),
                    'quantity': int.tryParse(quantityController.text.trim()) ??
                        data['quantity'],
                    'unit': unitController.text.trim(),
                    'location': locationController.text.trim(),
                    'pickupTime': Timestamp.fromDate(selectedTime),
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Listing updated successfully')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }
}