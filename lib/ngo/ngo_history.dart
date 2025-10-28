// lib/ngo/ngo_history.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class NgoHistoryPage extends StatefulWidget {
  const NgoHistoryPage({super.key});

  @override
  State<NgoHistoryPage> createState() => _NgoHistoryPageState();
}

class _NgoHistoryPageState extends State<NgoHistoryPage> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Donation History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('listings')
            .where('ngoEmail', isEqualTo: user?.email)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No donation history found yet.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            );
          }

          final listings = snapshot.data!.docs;

          // --- Extract correct statuses ---
          int active = 0;
          int pending = 0;
          int completed = 0;

          Map<String, int> weeklyCompleted = {};

          for (var doc in listings) {
            final data = doc.data() as Map<String, dynamic>;

            // Read top-level status
            String mainStatus =
            (data['status'] ?? '').toString().toLowerCase();

            // Check if nested pendingRequests[0]['status'] exists
            String? nestedStatus;
            if (data['pendingRequests'] != null &&
                data['pendingRequests'] is List &&
                (data['pendingRequests'] as List).isNotEmpty) {
              final firstRequest = (data['pendingRequests'] as List).first;
              if (firstRequest is Map<String, dynamic>) {
                nestedStatus =
                    (firstRequest['status'] ?? '').toString().toLowerCase();
              }
            }

            // Determine final effective status
            String effectiveStatus = nestedStatus ?? mainStatus;

            if (effectiveStatus == 'active') {
              active++;
            } else if (effectiveStatus == 'pending') {
              pending++;
            } else if (effectiveStatus == 'completed') {
              completed++;

              // --- Weekly bar chart calculation ---
              if (data['createdAt'] is Timestamp) {
                DateTime created = (data['createdAt'] as Timestamp).toDate();
                String weekLabel =
                    "Week ${DateFormat('w').format(created)}"; // week number
                weeklyCompleted[weekLabel] =
                    (weeklyCompleted[weekLabel] ?? 0) + 1;
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // --- PIE CHART ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Donation Status Overview',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 250,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 4,
                            centerSpaceRadius: 50,
                            sections: [
                              PieChartSectionData(
                                color: Colors.green,
                                value: completed.toDouble(),
                                title: 'Completed\n$completed',
                                radius: 70,
                                titleStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              PieChartSectionData(
                                color: Colors.orange,
                                value: pending.toDouble(),
                                title: 'Pending\n$pending',
                                radius: 70,
                                titleStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              PieChartSectionData(
                                color: Colors.blue,
                                value: active.toDouble(),
                                title: 'Active\n$active',
                                radius: 70,
                                titleStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- BAR CHART ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Completed Donations per Week',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: BarChart(
                          BarChartData(
                            barGroups: weeklyCompleted.entries
                                .map(
                                  (e) => BarChartGroupData(
                                x: weeklyCompleted.keys
                                    .toList()
                                    .indexOf(e.key),
                                barRods: [
                                  BarChartRodData(
                                    toY: e.value.toDouble(),
                                    color: Colors.green,
                                    width: 22,
                                    borderRadius:
                                    BorderRadius.circular(6),
                                  ),
                                ],
                              ),
                            )
                                .toList(),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index >= weeklyCompleted.keys.length) {
                                      return const SizedBox();
                                    }
                                    final label =
                                    weeklyCompleted.keys.elementAt(index);
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        label,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: true),
                              ),
                            ),
                            gridData: FlGridData(show: true),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
