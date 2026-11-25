import 'package:flutter/material.dart';
import '../core/dates.dart';
import '../core/format.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../state/app_state.dart';
import '../widgets/budget_progress_card.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  void _showSetBudgetDialog(
    BuildContext context, {
    Budget? existingBudget,
    Category? initialCategory,
  }) {
    final state = AppState.instance;
    final expenseCategories =
        state.categories.where((c) => c.type == TransactionType.expense).toList();

    int selectedCatId = existingBudget?.categoryId ??
        initialCategory?.id ??
        (expenseCategories.isNotEmpty ? expenseCategories.first.id! : 0);

    final amountController = TextEditingController(
      text: existingBudget != null ? formatThousands(existingBudget.monthlyLimit) : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existingBudget != null ? 'Ubah Anggaran' : 'Atur Anggaran Baru',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (existingBudget != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await state.deleteBudget(existingBudget.id!);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (existingBudget == null) ...[
                    const Text('Kategori Pengeluaran',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: selectedCatId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: expenseCategories.map((c) {
                        return DropdownMenuItem(value: c.id, child: Text(c.name));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCatId = val);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text('Batas Anggaran Bulanan (Rp)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsInputFormatter()],
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      hintText: 'Misal: 1.000.000',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Simpan Anggaran', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final limit = parseAmount(amountController.text);
                        if (limit <= 0) return;

                        await state.setBudget(selectedCatId, limit);
                        if (context.mounted) Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final budgets = state.budgets;
        final categories = state.categories;
        final spendingMap = state.categoryMonthlyExpense;

        final categoryMap = {for (var c in categories) c.id!: c};

        int totalBudgetLimit = budgets.fold(0, (sum, b) => sum + b.monthlyLimit);
        int totalBudgetSpent = budgets.fold(0, (sum, b) => sum + (spendingMap[b.categoryId] ?? 0));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Anggaran Bulanan', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Tambah Anggaran',
                onPressed: () => _showSetBudgetDialog(context),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              // Pengatur Bulan
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        state.setSelectedMonth(
                          DateTime(state.selectedMonth.year, state.selectedMonth.month - 1),
                        );
                      },
                    ),
                    Text(
                      fmtMonthYear(state.selectedMonth),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        state.setSelectedMonth(
                          DateTime(state.selectedMonth.year, state.selectedMonth.month + 1),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Kartu Ringkasan Total Anggaran
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Theme.of(context).dividerColor.withAlpha(40)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Anggaran',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formatRupiah(totalBudgetLimit),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Total Terpakai',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formatRupiah(totalBudgetSpent),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: totalBudgetSpent > totalBudgetLimit && totalBudgetLimit > 0
                                      ? Colors.red
                                      : const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: totalBudgetLimit > 0
                              ? (totalBudgetSpent / totalBudgetLimit).clamp(0.0, 1.0)
                              : 0.0,
                          minHeight: 6,
                          backgroundColor: Colors.grey.withAlpha(40),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            totalBudgetSpent > totalBudgetLimit && totalBudgetLimit > 0
                                ? Colors.red
                                : const Color(0xFF0EA5E9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              if (budgets.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.savings_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum ada anggaran untuk bulan ini',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tetapkan batas pengeluaran untuk setiap kategori agar keuangan terkontrol.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Buat Anggaran'),
                          onPressed: () => _showSetBudgetDialog(context),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...budgets.map((b) {
                  final cat = categoryMap[b.categoryId];
                  final spent = spendingMap[b.categoryId] ?? 0;

                  return BudgetProgressCard(
                    budget: b,
                    category: cat,
                    spentAmount: spent,
                    onEdit: () => _showSetBudgetDialog(
                      context,
                      existingBudget: b,
                      initialCategory: cat,
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
