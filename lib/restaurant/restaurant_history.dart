import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RestaurantHistoryPage extends StatelessWidget {
  const RestaurantHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            _ChartCard(title: "Daily Orders (Last 7 Days)", child: _DailyOrdersBarChart()),
            SizedBox(height: 16),
            _ChartCard(title: "Order Status Breakdown (Last 30 Days)", child: _BreakdownDonutChart()),
          ],
        ),
      ),
    );
  }
}

/// 🔹 Reusable card wrapper
class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(height: 260, child: child),
          ],
        ),
      ),
    );
  }
}

//
// 📊 Stacked Bar Chart: Daily orders by status (last 7 days)
//
class _DailyOrdersBarChart extends StatelessWidget {
  const _DailyOrdersBarChart();

  Stream<List<BarChartGroupData>> _getData() {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 6));
    final currentRestaurantId = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection("listings")
        .where("restaurantId", isEqualTo: currentRestaurantId)
        .where("createdAt", isGreaterThanOrEqualTo: start)
        .snapshots()
        .map((query) {
      // Initialize day buckets
      Map<int, Map<String, int>> dayBuckets = {
        for (int i = 0; i < 7; i++)
          i: {"active": 0, "pending": 0, "completed": 0}
      };

      for (var doc in query.docs) {
        final ts = (doc['createdAt'] as Timestamp).toDate().toLocal(); // ✅ FIX
        final diff = ts.difference(start).inDays;
        if (diff >= 0 && diff < 7) {
          final status = (doc['status'] ?? "pending").toString().toLowerCase();
          if (dayBuckets[diff]!.containsKey(status)) {
            dayBuckets[diff]![status] = (dayBuckets[diff]![status]! + 1);
          }
        }
      }

      // Build stacked bars
      return List.generate(7, (i) {
        final dayData = dayBuckets[i]!;
        final active = (dayData["active"] ?? 0).toDouble();
        final pending = (dayData["pending"] ?? 0).toDouble();
        final completed = (dayData["completed"] ?? 0).toDouble();

        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: active + pending + completed,
              rodStackItems: [
                BarChartRodStackItem(0, active, Colors.green),
                BarChartRodStackItem(active, active + pending, Colors.orange),
                BarChartRodStackItem(active + pending, active + pending + completed, Colors.blue),
              ],
              width: 20,
            ),
          ],
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<BarChartGroupData>>(
            stream: _getData(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final groups = snapshot.data!;

              return BarChart(
                BarChartData(
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  barGroups: groups,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final day = DateFormat('E').format(
                            DateTime.now().subtract(Duration(days: 6 - value.toInt())),
                          );
                          return Text(day, style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // 🔹 Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _LegendItem(color: Colors.green, label: "Active"),
            SizedBox(width: 12),
            _LegendItem(color: Colors.orange, label: "Pending"),
            SizedBox(width: 12),
            _LegendItem(color: Colors.blue, label: "Completed"),
          ],
        ),
      ],
    );
  }
}

//
// 🍩 Donut Chart: Percentage breakdown (last 30 days)
//
class _BreakdownDonutChart extends StatelessWidget {
  const _BreakdownDonutChart();

  Stream<Map<String, int>> _getData() {
    final lastMonth = DateTime.now().subtract(const Duration(days: 30));
    final currentRestaurantId = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection("listings")
        .where("restaurantId", isEqualTo: currentRestaurantId)
        .where("createdAt", isGreaterThanOrEqualTo: lastMonth)
        .snapshots()
        .map((query) {
      Map<String, int> counts = {"active": 0, "pending": 0, "completed": 0};
      for (var doc in query.docs) {
        final status = (doc['status'] ?? "pending").toString().toLowerCase();
        if (counts.containsKey(status)) counts[status] = counts[status]! + 1;
      }
      return counts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, int>>(
      stream: _getData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final counts = snapshot.data!;
        final total = counts.values.fold<int>(0, (sum, v) => sum + v);
        if (total == 0) return const Center(child: Text("No data in last 30 days"));

        return Column(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(color: Colors.green, value: counts["active"]!.toDouble(), title: "${((counts["active"]! / total) * 100).round()}%"),
                    PieChartSectionData(color: Colors.orange, value: counts["pending"]!.toDouble(), title: "${((counts["pending"]! / total) * 100).round()}%"),
                    PieChartSectionData(color: Colors.blue, value: counts["completed"]!.toDouble(), title: "${((counts["completed"]! / total) * 100).round()}%"),
                  ],
                  centerSpaceRadius: 50,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              children: [
                _LegendItem(color: Colors.green, label: "Active (${counts["active"]})"),
                _LegendItem(color: Colors.orange, label: "Pending (${counts["pending"]})"),
                _LegendItem(color: Colors.blue, label: "Completed (${counts["completed"]})"),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// 🔹 Legend widget
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
