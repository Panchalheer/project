import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'layout/side_menu.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  String selectedMenu = "Dashboard";
  final TextEditingController _searchController = TextEditingController();
  bool _isCheckingAccess = true;

  final _firestore = FirebaseFirestore.instance;
  String selectedRestaurantFilter = "All";
  String selectedNgoFilter = "All";

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists || doc.data()?['role'] != 'admin') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access denied: Admins only')),
        );
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying access: $e')),
      );
      Navigator.pushReplacementNamed(context, '/');
    } finally {
      setState(() => _isCheckingAccess = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  void _onMenuTap(String menu) {
    setState(() => selectedMenu = menu);
    Navigator.pop(context);
  }

  // 📄 Page Router
  Widget _getPageContent() {
    switch (selectedMenu) {
      case "Dashboard":
        return _buildDashboard();
      case "Restaurant Verification":
        return _buildRestaurantVerification();
      case "NGO Verification":
        return _buildNgoVerification();
      default:
        return Center(child: Text("$selectedMenu page coming soon"));
    }
  }

  // 🌟 MAIN DASHBOARD
  Widget _buildDashboard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('restaurants').snapshots(),
      builder: (context, restaurantSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('ngos').snapshots(),
          builder: (context, ngoSnapshot) {
            if (!restaurantSnapshot.hasData || !ngoSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final restaurants = restaurantSnapshot.data!.docs;
            final ngos = ngoSnapshot.data!.docs;

            final pendingRestaurants =
                restaurants.where((d) => d['status'] == 'Pending').length;
            final approvedRestaurants =
                restaurants.where((d) => d['status'] == 'Approved').length;
            final pendingNgos =
                ngos.where((d) => d['status'] == 'Pending').length;
            final approvedNgos =
                ngos.where((d) => d['status'] == 'Approved').length;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome, Admin 👋",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // 💠 Stats Cards
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildStatCard(
                        "Pending Restaurants",
                        pendingRestaurants,
                        Colors.orange,
                        Icons.restaurant,
                      ),
                      _buildStatCard(
                        "Approved Restaurants",
                        approvedRestaurants,
                        Colors.green,
                        Icons.check_circle,
                      ),
                      _buildStatCard(
                        "Pending NGOs",
                        pendingNgos,
                        Colors.blue,
                        Icons.volunteer_activism,
                      ),
                      _buildStatCard(
                        "Approved NGOs",
                        approvedNgos,
                        Colors.purple,
                        Icons.verified,
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    "Recent Activity",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  _buildRecentActivity(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 📊 Stats Card (compact)
  Widget _buildStatCard(String title, int value, Color color, IconData icon) {
    return Container(
      width: MediaQuery.of(context).size.width / 2 - 24,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.85), color.withOpacity(0.55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(2, 3))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                  const TextStyle(color: Colors.white70, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "$value",
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🕒 Recent Activity (with NGO/Restaurant names)
  Widget _buildRecentActivity() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('activityLogs')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("No recent activity yet.");
        }

        final docs = snapshot.data!.docs;
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final type = data['type'] ?? 'Unknown';
            final name = data['name'] ?? 'Unnamed';
            final status = data['status'] ?? '';
            final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

            Color msgColor = Colors.grey;
            IconData icon = Icons.info_outline;
            if (type == 'NGO') icon = Icons.volunteer_activism;
            if (type == 'Restaurant') icon = Icons.restaurant;
            if (status == 'Approved') msgColor = Colors.green;
            if (status == 'Rejected') msgColor = Colors.red;

            final timeStr = timestamp != null
                ? "${timestamp.day.toString().padLeft(2, '0')}/"
                "${timestamp.month.toString().padLeft(2, '0')} "
                "${timestamp.hour.toString().padLeft(2, '0')}:"
                "${timestamp.minute.toString().padLeft(2, '0')}"
                : 'Unknown time';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: Icon(icon, color: msgColor),
                title: Text(
                  "$status $type",
                  style: TextStyle(
                    color: msgColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(name),
                trailing: Text(timeStr,
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // 🍴 RESTAURANT VERIFICATION (unchanged)
  Widget _buildRestaurantVerification() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search restaurants...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              _buildRestaurantFilterChip("All"),
              _buildRestaurantFilterChip("Pending"),
              _buildRestaurantFilterChip("Approved"),
              _buildRestaurantFilterChip("Rejected"),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('restaurants').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filtered = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name =
                  (data['name'] ?? '').toString().toLowerCase();
                  final status = (data['status'] ?? 'Pending');
                  final matchesFilter = selectedRestaurantFilter == "All" ||
                      status == selectedRestaurantFilter;
                  final matchesSearch = name
                      .contains(_searchController.text.toLowerCase());
                  return matchesFilter && matchesSearch;
                }).toList();

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'Pending';

                    Color statusColor = switch (status) {
                      'Approved' => Colors.green,
                      'Rejected' => Colors.red,
                      _ => Colors.orange
                    };

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(data['name'] ?? 'Unnamed',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Contact: ${data['contactPerson'] ?? 'N/A'}"),
                            Text("Email: ${data['email'] ?? 'N/A'}"),
                            Row(
                              children: [
                                Icon(Icons.circle,
                                    size: 12, color: statusColor),
                                const SizedBox(width: 6),
                                Text("Status: $status"),
                              ],
                            ),
                          ],
                        ),
                        trailing: status == "Pending"
                            ? Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check,
                                  color: Colors.green),
                              onPressed: () => _updateStatus(
                                  "restaurants", doc.id, "Approved", data['name']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.red),
                              onPressed: () => _updateStatus(
                                  "restaurants", doc.id, "Rejected", data['name']),
                            ),
                          ],
                        )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🏢 NGO VERIFICATION (unchanged)
  Widget _buildNgoVerification() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search NGOs...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              _buildNgoFilterChip("All"),
              _buildNgoFilterChip("Pending"),
              _buildNgoFilterChip("Approved"),
              _buildNgoFilterChip("Rejected"),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('ngos').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filtered = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name =
                  (data['name'] ?? '').toString().toLowerCase();
                  final status = (data['status'] ?? 'Pending');
                  final matchesFilter =
                      selectedNgoFilter == "All" || status == selectedNgoFilter;
                  final matchesSearch =
                  name.contains(_searchController.text.toLowerCase());
                  return matchesFilter && matchesSearch;
                }).toList();

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'Pending';

                    Color statusColor = switch (status) {
                      'Approved' => Colors.green,
                      'Rejected' => Colors.red,
                      _ => Colors.orange,
                    };

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(data['name'] ?? 'Unnamed',
                            style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Contact: ${data['contactPerson'] ?? 'N/A'}"),
                            Text("Email: ${data['email'] ?? 'N/A'}"),
                            Row(
                              children: [
                                Icon(Icons.circle,
                                    size: 12, color: statusColor),
                                const SizedBox(width: 6),
                                Text("Status: $status"),
                              ],
                            ),
                          ],
                        ),
                        trailing: status == "Pending"
                            ? Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check,
                                  color: Colors.green),
                              onPressed: () => _updateStatus(
                                  "ngos", doc.id, "Approved", data['name']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.red),
                              onPressed: () => _updateStatus(
                                  "ngos", doc.id, "Rejected", data['name']),
                            ),
                          ],
                        )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🔄 Update Status + Log Activity
  Future<void> _updateStatus(
      String collection, String docId, String newStatus, String? name) async {
    await _firestore.collection(collection).doc(docId).update({
      'status': newStatus,
      'verifiedAt': FieldValue.serverTimestamp(),
    });

    final type = collection == "ngos" ? "NGO" : "Restaurant";
    await _firestore.collection('activityLogs').add({
      'type': type,
      'name': name ?? 'Unknown',
      'status': newStatus,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Widget _buildRestaurantFilterChip(String label) => ChoiceChip(
    label: Text(label),
    selected: selectedRestaurantFilter == label,
    onSelected: (_) => setState(() => selectedRestaurantFilter = label),
  );

  Widget _buildNgoFilterChip(String label) => ChoiceChip(
    label: Text(label),
    selected: selectedNgoFilter == label,
    onSelected: (_) => setState(() => selectedNgoFilter = label),
  );

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAccess) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(selectedMenu),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
      ),
      drawer: SideMenu(
        selected: selectedMenu,
        onMenuTap: _onMenuTap,
      ),
      body: _getPageContent(),
    );
  }
}