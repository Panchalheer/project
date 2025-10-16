import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _getCompletedPickups() {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection("listings")
        .where("ngoId", isEqualTo: userId)
        .where("status", isEqualTo: "Completed")
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "My Impact",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _getCompletedPickups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("No completed pickups yet."));
          }

          // Group pickups by month-year
          final Map<String, int> pickupsPerMonth = {};
          final Map<String, double> foodSavedPerMonth = {};

          for (var doc in docs) {
            final data = doc.data();
            final date = (data['createdAt'] as Timestamp).toDate();
            final qty = (data['quantity'] as num).toDouble();

            final key = "${date.year}-${date.month}"; // year-month key

            pickupsPerMonth[key] = (pickupsPerMonth[key] ?? 0) + 1;
            foodSavedPerMonth[key] =
                (foodSavedPerMonth[key] ?? 0) + qty;
          }

          // Sort keys (oldest → newest)
          final sortedKeys = foodSavedPerMonth.keys.toList()
            ..sort((a, b) {
              final partsA = a.split("-").map(int.parse).toList();
              final partsB = b.split("-").map(int.parse).toList();
              final dateA = DateTime(partsA[0], partsA[1]);
              final dateB = DateTime(partsB[0], partsB[1]);
              return dateA.compareTo(dateB);
            });

          // Build bar groups for pickups
          final barGroups = <BarChartGroupData>[];
          int xIndex = 0;
          for (final key in sortedKeys) {
            final count = pickupsPerMonth[key]?.toDouble() ?? 0;
            barGroups.add(
              BarChartGroupData(
                x: xIndex,
                barRods: [
                  BarChartRodData(toY: count, color: Colors.blue),
                ],
              ),
            );
            xIndex++;
          }

          // Build pie chart sections for food saved
          final totalFoodSaved =
          foodSavedPerMonth.values.fold<double>(0, (a, b) => a + b);

          final pieSections = <PieChartSectionData>[];
          int colorIndex = 0;
          final colors = [Colors.green, Colors.orange, Colors.blue, Colors.purple, Colors.red, Colors.teal];

          for (final key in sortedKeys) {
            final qty = foodSavedPerMonth[key]!;
            final percentage = (qty / totalFoodSaved) * 100;

            final parts = key.split("-").map(int.parse).toList();
            final monthLabel = "${_monthName(parts[1])} ${parts[0]}";

            pieSections.add(
              PieChartSectionData(
                color: colors[colorIndex % colors.length],
                value: qty,
                title: "${percentage.toStringAsFixed(1)}%",
                radius: 60,
              ),
            );
            colorIndex++;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 📊 Bar Chart - Pickups per month
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          "Pickups Per Month",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              barGroups: barGroups,
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: true),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value < 0 ||
                                          value >= sortedKeys.length) {
                                        return const Text("");
                                      }
                                      final key = sortedKeys[value.toInt()];
                                      final parts =
                                      key.split("-").map(int.parse).toList();
                                      return Text(
                                          "${_monthName(parts[1])}\n${parts[0]}",
                                          style: const TextStyle(fontSize: 10));
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 🥧 Pie Chart - Food saved distribution
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          "Food Saved Distribution",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 250,
                          child: PieChart(
                            PieChartData(
                              sections: pieSections,
                              centerSpaceRadius: 40,
                              sectionsSpace: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          children: [
                            for (int i = 0; i < sortedKeys.length; i++)
                              _LegendItem(
                                color: colors[i % colors.length],
                                label: sortedKeys[i],
                              ),
                          ],
                        ),
                      ],
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

  String _monthName(int month) {
    const months = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return (month >= 1 && month <= 12) ? months[month] : "";
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
