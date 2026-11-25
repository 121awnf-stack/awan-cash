import 'package:flutter/material.dart';
import '../core/format.dart';
import '../core/icons.dart';
import '../models/category.dart';
import '../models/budget.dart';

class BudgetProgressCard extends StatelessWidget {
  final Budget budget;
  final Category? category;
  final int spentAmount;
  final VoidCallback? onEdit;

  const BudgetProgressCard({
    super.key,
    required this.budget,
    this.category,
    required this.spentAmount,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final limit = budget.monthlyLimit;
    final ratio = limit > 0 ? (spentAmount / limit).clamp(0.0, 1.0) : 0.0;
    final isOver = spentAmount > limit;
    final percentage = limit > 0 ? ((spentAmount / limit) * 100).toInt() : 0;

    Color progressColor;
    if (isOver) {
      progressColor = const Color(0xFFEF4444); // Merah
    } else if (ratio > 0.75) {
      progressColor = const Color(0xFFF59E0B); // Kuning
    } else {
      progressColor = const Color(0xFF10B981); // Hijau
    }

    final catColor = category != null ? Color(category!.color) : Colors.blue;
    final icon = category != null ? categoryIcon(category!.icon) : Icons.category;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOver
              ? Colors.red.withAlpha(100)
              : Theme.of(context).dividerColor.withAlpha(40),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: catColor.withAlpha(35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: catColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category?.name ?? 'Kategori #${budget.categoryId}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isOver
                            ? 'Melebihi anggaran sebesar ${formatRupiah(spentAmount - limit)}'
                            : 'Tersisa ${formatRupiah(limit - spentAmount)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOver ? Colors.red : Colors.grey.shade600,
                          fontWeight: isOver ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                  tooltip: 'Ubah Anggaran',
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: Colors.grey.withAlpha(40),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Terpakai: ${formatRupiah(spentAmount)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  '$percentage% dari ${formatRupiah(limit)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: progressColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
