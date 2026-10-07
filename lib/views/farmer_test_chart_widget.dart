import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/test_model.dart';

class FarmerTestChartWidget extends StatelessWidget {
  final List<FarmerTestSummaryModel> summaryList;

  const FarmerTestChartWidget({super.key, required this.summaryList});

  // สร้าง Label แกน X แสดงชื่อเกษตรกร[cite: 29, 30]
  Widget getBottomTitles(double value, TitleMeta meta) {
    int index = value.toInt();
    if (index >= 0 && index < summaryList.length) {
      return SideTitleWidget(
        meta: meta,
        space: 8,
        child: Text(
          summaryList[index].farmerName,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    return const Text('');
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: getBottomTitles, //[cite: 33]
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 40),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            // แมปข้อมูลลงแกน X (Index) และ แกน Y (ค่า DRC เฉลี่ย)[cite: 34, 35]
            barGroups: summaryList.asMap().entries.map((entry) {
              int index = entry.key;
              double avgDrc = entry.value.avgDrc;

              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: avgDrc,
                    color: const Color.fromARGB(255, 231, 156, 116),
                    width: 20,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}