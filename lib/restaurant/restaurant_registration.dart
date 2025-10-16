import 'package:flutter/material.dart';
import 'restaurant_login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zero/pending_approval.dart';

class RestaurantRegistrationPage extends StatefulWidget {
  @override
  _RestaurantRegistrationPageState createState() =>
      _RestaurantRegistrationPageState();
}

class _RestaurantRegistrationPageState
    extends State<RestaurantRegistrationPage> {
  final TextEditingController orgNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController fatherNameController = TextEditingController();

  bool isLoading = false;

  Future<void> _registerRestaurant() async {
    if (orgNameController.text.isEmpty ||
        addressController.text.isEmpty ||
        cityController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        fatherNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // ✅ Create Firebase Auth user
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // ✅ Store data in Firestore with status = Pending + role = restaurant
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(userCredential.user!.uid)
          .set({
        'name': orgNameController.text.trim(),
        'address': addressController.text.trim(),
        'city': cityController.text.trim(),
        'fatherName': fatherNameController.text.trim(),
        'email': emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'Pending', // 👈 admin approval needed
        'role': 'restaurant', // 👈 added role field
      });

      // ✅ Sign out right after registration
      await FirebaseAuth.instance.signOut();

      // ✅ Navigate to “Pending Approval” page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PendingApprovalPage(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMsg = "Error: ${e.message}";
      if (e.code == 'weak-password') {
        errorMsg = "Password should be at least 6 characters.";
      } else if (e.code == 'email-already-in-use') {
        errorMsg = "This email is already registered.";
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMsg)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // ⚠ UI is untouched
    return Scaffold(
      appBar: AppBar(
        title: Text("Register your Restaurant"),
        backgroundColor: Colors.green[400],
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Join our mission to reduce food waste and help communities in need.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              SizedBox(height: 20),
              TextField(
                controller: orgNameController,
                decoration: InputDecoration(
                  labelText: "Organization Name",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: fatherNameController,
                decoration: InputDecoration(
                  labelText: "Father's Name",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: "Restaurant Address",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 15),
              TextField(
                controller: cityController,
                decoration: InputDecoration(
                  labelText: "City",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email Address",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : _registerRestaurant,
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Register Restaurant"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => RestaurantLoginPage()),
                    );
                  },
                  child: Text.rich(
                    TextSpan(
                      text: "Already registered? ",
                      style: TextStyle(color: Colors.black87),
                      children: [
                        TextSpan(
                          text: "Sign In",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}