import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ngo_login.dart'; // ✅ import NGO login screen

class NGOProfilePage extends StatefulWidget {
  const NGOProfilePage({super.key});

  @override
  State<NGOProfilePage> createState() => _NGOProfilePageState();
}

class _NGOProfilePageState extends State<NGOProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _yearController = TextEditingController();

  bool _isEditing = false;
  bool _loading = true;
  bool _hasChanges = false;
  String? _initialLetter;

  @override
  void dispose() {
    _nameController.dispose();
    _regNumberController.dispose();
    _addressController.dispose();
    _contactPersonController.dispose();
    _fatherNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc =
    await FirebaseFirestore.instance.collection('ngos').doc(uid).get();

    final data = doc.data() ?? {};
    _nameController.text = data['name'] ?? '';
    _regNumberController.text = data['regNumber'] ?? '';
    _addressController.text = data['address'] ?? '';
    _contactPersonController.text = data['contactPerson'] ?? '';
    _fatherNameController.text = data['fatherName'] ?? '';
    _emailController.text = data['email'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _yearController.text = data['year'] ?? '';

    setState(() {
      if (_nameController.text.isNotEmpty) {
        _initialLetter = _nameController.text[0].toUpperCase();
      } else if (_emailController.text.isNotEmpty) {
        _initialLetter = _emailController.text[0].toUpperCase();
      } else {
        _initialLetter = "U";
      }
      _loading = false;
    });
  }

  Future<void> _confirmAndSave() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Save Changes?"),
        content:
        const Text("Do you want to save your updated profile details?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (confirm == true) await _saveData();
  }

  Future<void> _confirmDiscard() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Discard Changes?"),
        content: const Text(
            "You have unsaved changes. Do you really want to discard them?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Discard"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isEditing = false;
        _hasChanges = false;
      });
    }
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('ngos').doc(uid).set({
      'name': _nameController.text.trim(),
      'regNumber': _regNumberController.text.trim(),
      'address': _addressController.text.trim(),
      'contactPerson': _contactPersonController.text.trim(),
      'fatherName': _fatherNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'year': _yearController.text.trim(),
    }, SetOptions(merge: true));

    setState(() {
      _loading = false;
      _isEditing = false;
      _hasChanges = false;
      _initialLetter = _nameController.text.isNotEmpty
          ? _nameController.text[0].toUpperCase()
          : (_emailController.text.isNotEmpty
          ? _emailController.text[0].toUpperCase()
          : "U");
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully ✅")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();

    _nameController.addListener(() => setState(() => _hasChanges = true));
    _regNumberController.addListener(() => setState(() => _hasChanges = true));
    _addressController.addListener(() => setState(() => _hasChanges = true));
    _contactPersonController
        .addListener(() => setState(() => _hasChanges = true));
    _fatherNameController
        .addListener(() => setState(() => _hasChanges = true));
    _phoneController.addListener(() => setState(() => _hasChanges = true));
    _yearController.addListener(() => setState(() => _hasChanges = true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              if (_isEditing && _hasChanges) {
                _confirmDiscard();
              } else {
                setState(() {
                  _isEditing = !_isEditing;
                  _hasChanges = false;
                });
              }
            },
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.green,
                child: Text(
                  _initialLetter ?? "U",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _buildTextField("Organization Name", _nameController),
              const SizedBox(height: 12),
              _buildTextField("Registration Number", _regNumberController),
              const SizedBox(height: 12),
              _buildTextField("Address", _addressController),
              const SizedBox(height: 12),
              _buildTextField("Contact Person", _contactPersonController),
              const SizedBox(height: 12),
              _buildTextField("Father Name", _fatherNameController),
              const SizedBox(height: 12),
              _buildTextField("Email", _emailController, readOnly: true),
              const SizedBox(height: 12),
              _buildTextField("Phone", _phoneController),
              const SizedBox(height: 12),
              _buildTextField("Year of Establishment", _yearController),
              const SizedBox(height: 30),

              if (_isEditing && _hasChanges)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _confirmAndSave,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    "Save Changes",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 20),

              // ✅ LOGOUT BUTTON
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NGOLoginPage()),
                        (Route<dynamic> route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Helper Text Field Builder
  Widget _buildTextField(String label, TextEditingController controller,
      {bool readOnly = false}) {
    return TextFormField(
      controller: controller,
      readOnly: !_isEditing || readOnly,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black87),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.green, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "$label cannot be empty";
        }
        return null;
      },
    );
  }
}
