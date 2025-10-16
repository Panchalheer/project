import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyPostsPage extends StatelessWidget {
  const MyPostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Food Posts"),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('food_posts')
            .where('restaurantId', isEqualTo: user!.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // 🔴 Handle errors
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }

          // ⏳ Handle loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ✅ Got data
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No food posts yet"));
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final doc = posts[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.fastfood, color: Colors.deepPurple),
                  title: Text(data['title'] ?? "Food Item"),
                  subtitle: Text(
                    "Qty: ${data['quantity']} • Status: ${data['status']}",
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == "delete") {
                        FirebaseFirestore.instance
                            .collection('food_posts')
                            .doc(doc.id)
                            .delete();
                      } else if (value == "markClaimed") {
                        FirebaseFirestore.instance
                            .collection('food_posts')
                            .doc(doc.id)
                            .update({'status': 'claimed'});
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: "markClaimed",
                        child: Text("Mark as Claimed"),
                      ),
                      const PopupMenuItem(
                        value: "delete",
                        child: Text("Delete"),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
