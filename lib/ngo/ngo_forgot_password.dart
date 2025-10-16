import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NGOForgotPasswordPage extends StatefulWidget {
  const NGOForgotPasswordPage({super.key});

  @override
  State<NGOForgotPasswordPage> createState() => _NGOForgotPasswordPageState();
}

class _NGOForgotPasswordPageState extends State<NGOForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController fatherNameController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    fatherNameController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final email = emailController.text.trim();
    final fatherName = fatherNameController.text.trim();

    if (email.isEmpty || fatherName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Step 1: Verify in Firestore (public read allowed by rules)
      final query = await FirebaseFirestore.instance
          .collection('ngos')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No NGO found with this email.")),
        );
        return;
      }

      final ngoData = query.docs.first.data();
      final storedFatherName = (ngoData['fatherName'] ?? '').toString().trim();

      if (storedFatherName.toLowerCase() != fatherName.toLowerCase()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Father’s name does not match.")),
        );
        return;
      }

      // Step 2: Send Firebase reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Reset link sent to your email")),
      );

      // Optionally navigate back or to a confirmation screen
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Authentication error")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("NGO - Forgot Password"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Enter your registered NGO email and father's name to reset your password.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: fatherNameController,
              decoration: const InputDecoration(
                labelText: "Father's Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
                  : const Text("Send Reset Link"),
            ),
          ],
        ),
      ),
    );
  }
}