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
  final TextEditingController _locationController = TextEditingController();
  DateTime? _pickupTime;

  bool _isLoading = false;

  final List<String> _units = ['kg', 'litres', 'pieces', 'packs', 'boxes', 'plates'];
  String? _selectedUnit;

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
      final restaurantDoc = await FirebaseFirestore.instance
          .collection("restaurants")
          .doc(restaurantId)
          .get();
      final restaurantName = restaurantDoc.data()?["name"] ?? "Unknown Restaurant";

      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

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

      await FirebaseFirestore.instance.collection('listings').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'quantity': int.tryParse(_quantityController.text.trim()) ?? 0,
        'unit': _selectedUnit ?? '',
        'location': address,
        'geo': GeoPoint(pos.latitude, pos.longitude),
        'status': 'Active',
        'ngoId': null,
        'createdAt': FieldValue.serverTimestamp(),
        'restaurantName': restaurantName,
        'restaurantId': restaurantId,
        'pickupTime': Timestamp.fromDate(_pickupTime!),
      });

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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.green, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String pickupText = _pickupTime == null
        ? "No pickup time chosen"
        : "Pickup: ${DateFormat('EEE, MMM d • hh:mm a').format(_pickupTime!)}";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Listing"),
        backgroundColor: Colors.green,
        centerTitle: true,
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
                  decoration: _inputDecoration("Title"),
                  validator: (value) =>
                  value!.isEmpty ? "Please enter a title" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: _inputDecoration("Description"),
                  validator: (value) =>
                  value!.isEmpty ? "Please enter a description" : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: _inputDecoration("Quantity"),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                        value!.isEmpty ? "Enter quantity" : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedUnit,
                        decoration: _inputDecoration("Unit"),
                        items: _units
                            .map((unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit),
                        ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedUnit = value);
                        },
                        validator: (value) =>
                        value == null ? "Select unit" : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration:
                  _inputDecoration("Location (optional — auto-detect)"),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pickupText,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _pickDateTime,
                      icon: const Icon(Icons.access_time),
                      label: const Text("Select Time"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _saveListing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Post Listing",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
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
