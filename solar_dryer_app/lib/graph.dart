import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class GraphPage extends StatefulWidget {
  @override
  _GraphPageState createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  final DatabaseReference historyRef =
      FirebaseDatabase.instance.ref("/solarDryer/history");

  Map<String, dynamic>? historyData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  void fetchHistory() async {
    final snapshot = await historyRef.get();
    if (snapshot.exists) {
      setState(() {
        historyData = Map<String, dynamic>.from(snapshot.value as Map);
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  // Extract line series for a parameter index
  Map<String, List<FlSpot>> extractSeries(int index) {
    Map<String, List<FlSpot>> series = {};

    historyData?.forEach((shape, entries) {
      List<FlSpot> spots = [];
      int i = 0;
      (entries as Map).forEach((ts, arr) {
        double x = i.toDouble();
        double y = (arr[index] as num).toDouble();
        spots.add(FlSpot(x, y));
        i++;
      });
      series[shape] = spots;
    });

    return series;
  }

  Widget buildGraph(String title, int arrayIndex) {
    final series = extractSeries(arrayIndex);
    return SingleChildScrollView(
    child: Card(
      margin: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
    AspectRatio(
      aspectRatio: 1.6,
      child: LineChart(
        LineChartData(
          lineBarsData: series.entries.map((entry) {
            return LineChartBarData(
              spots: entry.value,
              isCurved: true,
              barWidth: 1,
              dotData: FlDotData(show: false),
              color: Colors.primaries[
                  entry.key.hashCode % Colors.primaries.length],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30, // ✅ gives space for 2–3 digit numbers
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 12, height: 1), // height=1 avoids wrapping
                    textAlign: TextAlign.right,
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false), // 🔥 hide right side labels
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: true),
          gridData: FlGridData(show: true),
        ),
      ),
    ),
            // Legend
            Wrap(
              spacing: 12,
              children: series.keys.map((shape) {
                final color = Colors.primaries[
                    shape.hashCode % Colors.primaries.length];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, color: color),
                    SizedBox(width: 4),
                    Text(shape),
                  ],
                );
              }).toList(),
            )
          ],
        ),
      ),
    ));
  }
  

  @override
Widget build(BuildContext context) {
  if (loading) {
    return Center(child: CircularProgressIndicator());
  }

  if (historyData == null) {
    return Center(child: Text("No history data found."));
  }

  return ListView(
    children: [
      buildGraph("Temperature Comparison", 0),
      buildGraph("Humidity Comparison", 1),
      buildGraph("Collector Temperature", 2),
      buildGraph("Collector Humidity", 3),
    ],
  );
}

}

