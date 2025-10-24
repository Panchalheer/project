// lib/ngo/ngo_history.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class NgoHistoryPage extends StatefulWidget {
  const NgoHistoryPage({super.key});

  @override
  State<NgoHistoryPage> createState() => _NgoHistoryPageState();
}

class _NgoHistoryPageState extends State<NgoHistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("NGO History & Analytics"),
        backgroundColor: Colors.green.shade700,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('ngos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No NGO data found",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final ngos = snapshot.data!.docs;

          // Count Approved vs Pending
          int approvedCount = ngos
              .where((doc) => (doc['status'] ?? '').toString().toLowerCase() == 'approved')
              .length;
          int pendingCount = ngos
              .where((doc) => (doc['status'] ?? '').toString().toLowerCase() == 'pending')
              .length;

          // Count NGOs by year
          final Map<String, int> yearCount = {};
          for (var doc in ngos) {
            final year = (doc['year'] ?? 'Unknown').toString();
            yearCount[year] = (yearCount[year] ?? 0) + 1;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "NGO Status Overview",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          color: Colors.green,
                          value: approvedCount.toDouble(),
                          title: "Approved ($approvedCount)",
                          radius: 60,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PieChartSectionData(
                          color: Colors.orange,
                          value: pendingCount.toDouble(),
                          title: "Pending ($pendingCount)",
                          radius: 60,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  "NGO Registrations by Year",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final yearKeys = yearCount.keys.toList();
                              if (value.toInt() >= 0 &&
                                  value.toInt() < yearKeys.length) {
                                return Text(yearKeys[value.toInt()]);
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(
                        yearCount.length,
                            (index) {
                          final key = yearCount.keys.elementAt(index);
                          final count = yearCount[key]!;
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: count.toDouble(),
                                width: 18,
                                color: Colors.teal,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
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
