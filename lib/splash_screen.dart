import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'role_selection.dart';
import 'role_selection_login.dart';
import 'admin/admin_login_page.dart';
import 'ngo/ngo_home.dart';
import 'restaurant/restaurant_home.dart';
import 'pending_approval.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _adminTapCount = 0;
  DateTime? _firstTapTime;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  // ✅ Check user login + approval status
  Future<void> _checkUserStatus() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return; // stay on splash if logged out

    try {
      // Determine role by checking collections
      final ngoDoc = await FirebaseFirestore.instance
          .collection('ngos')
          .doc(user.uid)
          .get();
      final restaurantDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(user.uid)
          .get();

      // NGO
      if (ngoDoc.exists) {
        final isApproved = ngoDoc.data()?['isApproved'] ?? false;
        if (isApproved) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const NgoHomePage()),
            );
          }
        } else {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const PendingApprovalPage()),
            );
          }
        }
        return;
      }

      // RESTAURANT
      if (restaurantDoc.exists) {
        final isApproved = restaurantDoc.data()?['isApproved'] ?? false;
        if (isApproved) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RestaurantHomePage()),
            );
          }
        } else {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const PendingApprovalPage()),
            );
          }
        }
        return;
      }
    } catch (e) {
      debugPrint("Error checking user status: $e");
    }
  }

  void _handleAdminTap() {
    final now = DateTime.now();

    if (_firstTapTime == null ||
        now.difference(_firstTapTime!) > const Duration(seconds: 3)) {
      _firstTapTime = now;
      _adminTapCount = 1;
    } else {
      _adminTapCount++;
    }

    if (_adminTapCount >= 7) {
      _adminTapCount = 0;
      _firstTapTime = null;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminLoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _handleAdminTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    "Zero",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    "Waste",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Nourish Communities,\nNot Landfills.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Image.asset("assets/tree.png", fit: BoxFit.contain),
              ),
            ),
            const Text(
              "Connecting Restaurants & NGOs\n to Share Surplus Food",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RoleSelectionPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Get Started",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RoleSelectionLoginPage(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "I Already Have An Account",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}