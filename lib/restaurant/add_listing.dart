// lib/restaurant/add_listing_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class AddListingPage extends StatefulWidget {
  const AddListingPage({super.key});

  @override
  State<AddListingPage> createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  DateTime? _pickupTime;

  bool _isLoading = false;

  /// ✅ Save listing to Firestore
  Future<void> _saveListing() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickupTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a pickup time")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String restaurantId = FirebaseAuth.instance.currentUser!.uid;

      // 🔹 Get restaurant details
      final restaurantDoc = await FirebaseFirestore.instance
          .collection("restaurants")
          .doc(restaurantId)
          .get();
      final restaurantName = restaurantDoc.data()?["name"] ?? "Unknown Restaurant";

      // ✅ Get device location
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // ✅ Try to reverse geocode if user didn’t type a location
      String address = _locationController.text.trim();
      if (address.isEmpty) {
        try {
          List<Placemark> placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            address = "${place.subLocality}, ${place.locality}";
          }
        } catch (e) {
          debugPrint("Reverse geocoding failed: $e");
          address = "Unknown Location";
        }
      }

      // ✅ Add document to Firestore — triggers Cloud Function
      await FirebaseFirestore.instance.collection('listings').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'quantity': int.tryParse(_quantityController.text.trim()) ?? 0,
        'unit': _unitController.text.trim(),
        'location': address, // human-readable
        'geo': GeoPoint(pos.latitude, pos.longitude), // ✅ GeoPoint
        'status': 'Active',
        'ngoId': null,
        'createdAt': FieldValue.serverTimestamp(),
        'restaurantName': restaurantName,
        'restaurantId': restaurantId,
        'pickupTime': Timestamp.fromDate(_pickupTime!),
      });

      // ✅ UI feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Listing added successfully 🎉")),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint("❌ Error creating listing: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => _isLoading = false);
  }

  /// 🕒 Pick date and time for pickup
  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      _pickupTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final String pickupText = _pickupTime == null
        ? "No pickup time chosen"
        : "Pickup: ${DateFormat('EEE, MMM d • hh:mm a').format(_pickupTime!)}";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Listing"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: "Title"),
                  validator: (value) =>
                  value!.isEmpty ? "Enter a title" : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: "Description"),
                  validator: (value) =>
                  value!.isEmpty ? "Enter a description" : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        decoration:
                        const InputDecoration(labelText: "Quantity"),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                        value!.isEmpty ? "Enter quantity" : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(labelText: "Unit"),
                        validator: (value) =>
                        value!.isEmpty ? "Enter unit" : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText:
                    "Location (optional — auto-detect if left empty)",
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Text(pickupText)),
                    ElevatedButton(
                      onPressed: _pickDateTime,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text("Select Time"),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _saveListing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    "Post Listing",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}