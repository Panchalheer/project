import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // ✅ for reverse geocoding

class PostFoodPage extends StatefulWidget {
  const PostFoodPage({super.key});

  @override
  State<PostFoodPage> createState() => _PostFoodPageState();
}

class _PostFoodPageState extends State<PostFoodPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  bool _loading = false;

  Future<void> _postFood() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // ✅ Get current position
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print("📍 Current Position: ${pos.latitude}, ${pos.longitude}");

      // ✅ Convert lat/lng into human-readable address
      String address = "Unknown Location";
      try {
        List<Placemark> placemarks =
        await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          address = "${place.subLocality}, ${place.locality}";
        }
      } catch (e) {
        print("⚠ Reverse geocoding failed: $e");
      }

      // ✅ Debug before saving
      print("📝 Saving listing with fields:");
      print("Title: ${_titleController.text}");
      print("Geo: ${pos.latitude}, ${pos.longitude}");
      print("Location (string): $address");

      // ✅ Save listing with both GeoPoint + readable string location
      await FirebaseFirestore.instance.collection('listings').add({
        'restaurantName': user.displayName ?? "Unknown Restaurant",
        'restaurantId': user.uid,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'quantity': int.tryParse(_quantityController.text) ?? 1,
        'pickupTime': Timestamp.now().toDate().add(const Duration(hours: 2)),
        'createdAt': Timestamp.now(),
        'geo': GeoPoint(pos.latitude, pos.longitude), // ✅ GeoPoint
        'location': address,                          // ✅ Readable name
        'status': 'Active',
      });

      print("✅ Food posted successfully!");

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Food posted successfully ✅")),
        );
      }
    } catch (e) {
      print("❌ Error posting food: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Post Surplus Food"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Food Title"),
                validator: (value) =>
                value == null || value.isEmpty ? "Enter food title" : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                validator: (value) =>
                value == null || value.isEmpty ? "Enter description" : null,
              ),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: "Quantity"),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value == null || value.isEmpty ? "Enter quantity" : null,
              ),
              const SizedBox(height: 20),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _postFood,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                ),
                child: const Text(
                  "Post Food",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}