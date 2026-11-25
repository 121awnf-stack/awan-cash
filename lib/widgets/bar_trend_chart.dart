import 'package:flutter/material.dart';
import '../core/format.dart';

class DailySpending {
  final String label; // misal 'Sen', 'Sel', 'Rab'
  final int amount;

  const DailySpending(this.label, this.amount);
}

class BarTrendChart extends StatelessWidget {
  final List<DailySpending> dailyData;

  const BarTrendChart({super.key, required this.dailyData});

  @override
  Widget build(BuildContext context) {
    if (dailyData.isEmpty) return const SizedBox.shrink();

    final maxVal = dailyData.fold<int>(0, (prev, e) => e.amount > prev ? e.amount : prev);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tren 7 Hari Terakhir',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            if (maxVal > 0)
              Text(
                'Maks: ${formatCompactRupiah(maxVal)}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: dailyData.map((d) {
              final ratio = maxVal > 0 ? (d.amount / maxVal).clamp(0.05, 1.0) : 0.05;
              final isToday = d == dailyData.last;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (d.amount > 0)
                        Text(
                          formatCompactRupiah(d.amount),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isToday ? const Color(0xFF0EA5E9) : Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: ratio,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isToday
                                    ? const Color(0xFF0EA5E9)
                                    : (isDark
                                        ? Colors.blueGrey.shade800
                                        : Colors.blue.shade100),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        d.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday
                              ? const Color(0xFF0EA5E9)
                              : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
