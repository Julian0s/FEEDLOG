import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final spots = [
      const FlSpot(0, 82),
      const FlSpot(1, 81.5),
      const FlSpot(2, 81.2),
      const FlSpot(3, 80.9),
      const FlSpot(4, 80.7),
      const FlSpot(5, 80.3),
      const FlSpot(6, 80.0),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weight Progress', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1.7,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('AI Insights', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Card(
              child: ListTile(
                leading: Icon(Icons.thumb_up, color: Colors.green),
                title: Text('Great job maintaining protein intake!'),
              ),
            ),
            const Card(
              child: ListTile(
                leading: Icon(Icons.warning_amber, color: Colors.orange),
                title: Text("You've been consuming high sodium levels."),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
