import 'package:flutter/material.dart';
import 'role_selection_base.dart';
import 'restaurant/restaurant_registration.dart';
import 'ngo/ngo_registration.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleSelectionBase(
      title: "Join as a...",
      onRestaurantTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RestaurantRegistrationPage()),
        );
      },
      onNgoTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NGORegistrationPage()),
        );
      },
    );
  }
}