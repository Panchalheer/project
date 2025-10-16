import 'package:flutter/material.dart';
import 'role_selection_base.dart';
import 'restaurant/restaurant_login.dart';
import 'ngo/ngo_login.dart';

class RoleSelectionLoginPage extends StatelessWidget {
  const RoleSelectionLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleSelectionBase(
      title: "Login as a...",
      onRestaurantTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RestaurantLoginPage()),
        );
      },
      onNgoTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NGOLoginPage()),
        );
      },
    );
  }
}