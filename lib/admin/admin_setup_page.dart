import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSetupPage extends StatefulWidget {
  const AdminSetupPage({super.key});

  @override
  State<AdminSetupPage> createState() => _AdminSetupPageState();
}

class _AdminSetupPageState extends State<AdminSetupPage> {
  final TextEditingController emailController =
  TextEditingController(text: "admin@gmail.com");
  final TextEditingController passwordController =
  TextEditingController(text: "Admin@12345"); // change after setup
  final TextEditingController nameController =
  TextEditingController(text: "Super Admin");

  bool _loading = false;
  String _message = "";

  Future<void> createAdmin() async {
    setState(() {
      _loading = true;
      _message = "";
    });

    try {
      // Step 1: Create admin in Firebase Auth
      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      // Step 2: Save admin details in Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        "email": emailController.text.trim(),
        "name": nameController.text.trim(),
        "role": "admin",
        "createdAt": FieldValue.serverTimestamp(),
      });

      setState(() {
        _message = "✅ Admin created successfully!";
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        setState(() {
          _message = "⚠️ Admin already exists!";
        });
      } else {
        setState(() {
          _message = "❌ FirebaseAuth error: ${e.message}";
        });
      }
    } catch (e) {
      setState(() {
        _message = "❌ Unexpected error: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Setup")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Create Admin Account",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Admin Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Admin Name"),
            ),
            const SizedBox(height: 20),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: createAdmin,
              child: const Text("Create Admin"),
            ),
            const SizedBox(height: 20),
            if (_message.isNotEmpty)
              Text(
                _message,
                style: TextStyle(
                  color: _message.startsWith("✅")
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
