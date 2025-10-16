import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  final Function(String) onMenuTap;
  final String selected;

  const SideMenu({super.key, required this.onMenuTap, required this.selected});

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      "Dashboard",
      "Restaurant Verification",
      "NGO Verification",
      "Settings",
    ];

    return Container(
      width: 240,
      color: const Color(0xFF1F2937),
      child: Column(
        children: [
          DrawerHeader(
            child: Row(
              children: const [
                Icon(Icons.eco, color: Colors.green),
                SizedBox(width: 8),
                Text("ZeroWaste Admin",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
          ),
          ...menuItems.map((item) {
            final isActive = selected == item;
            return ListTile(
              leading: Icon(Icons.circle,
                  size: 12, color: isActive ? Colors.green : Colors.white54),
              title: Text(item,
                  style: TextStyle(
                      color: isActive ? Colors.green : Colors.white70)),
              selected: isActive,
              onTap: () => onMenuTap(item),
            );
          }),
        ],
      ),
    );
  }
}
