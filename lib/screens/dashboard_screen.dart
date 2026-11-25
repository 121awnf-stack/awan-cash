import 'package:flutter/material.dart';
import '../core/dates.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/category.dart';
import '../models/transaction_entry.dart';
import '../state/app_state.dart';
import '../widgets/donut_chart.dart';
import '../widgets/bar_trend_chart.dart';
import '../widgets/wallet_card.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';
import 'wallets_screen.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onSeeAllTransactions;

  const DashboardScreen({
    super.key,
    required this.onSeeAllTransactions,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final wallets = state.wallets;
        final balances = state.walletBalances;
        final transactions = state.transactions;
        final categories = state.categories;

        // Siapkan data slice kategori pengeluaran bulan ini
        final spendingMap = state.categoryMonthlyExpense;
        final totalExp = state.monthlyExpense;
        final categoryMap = {for (var c in categories) c.id!: c};

        final slices = <CategorySlice>[];
        if (totalExp > 0) {
          spendingMap.forEach((catId, amount) {
            final cat = categoryMap[catId];
            if (cat != null && amount > 0) {
              slices.add(CategorySlice(
                name: cat.name,
                amount: amount,
                color: Color(cat.color),
                percentage: amount / totalExp,
              ));
            }
          });
          slices.sort((a, b) => b.amount.compareTo(a.amount));
        }

        // Siapkan tren 7 hari terakhir
        final now = DateTime.now();
        final dailyData = <DailySpending>[];
        for (int i = 6; i >= 0; i--) {
          final targetDate = now.subtract(Duration(days: i));
          final range = dayRange(targetDate);
          final daySpent = transactions
              .where((t) => t.type == TransactionType.expense && range.contains(t.dateTime))
              .fold(0, (sum, t) => sum + t.amount);
          dailyData.add(DailySpending(fmtWeekdayShort(targetDate), daySpent));
        }

        // 5 transaksi terakhir
        final recentTransactions = transactions.take(5).toList();

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_queue, color: Color(0xFF0EA5E9), size: 22),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Awan Cash',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.account_balance_wallet_outlined),
                tooltip: 'Kelola Dompet',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WalletsScreen()),
                  );
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => state.refreshAllData(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                // 1. KARTU HERO TOTAL KEKAYAAN BERSIH
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.cloudGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0EA5E9).withAlpha(80),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Kekayaan Bersih',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(Icons.shield_outlined, color: Colors.white70, size: 18),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formatRupiah(state.totalNetWorth),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Ringkasan Pemasukan & Pengeluaran Bulan Ini
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(30),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(40),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.arrow_downward,
                                          color: Colors.white, size: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Pemasukan',
                                            style: TextStyle(
                                                color: Colors.white70, fontSize: 11),
                                          ),
                                          Text(
                                            formatRupiah(state.monthlyIncome),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(width: 1, height: 32, color: Colors.white24),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(40),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.arrow_upward,
                                            color: Colors.white, size: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Pengeluaran',
                                              style: TextStyle(
                                                  color: Colors.white70, fontSize: 11),
                                            ),
                                            Text(
                                              formatRupiah(state.monthlyExpense),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. DAFTAR DOMPET (HORIZONTAL)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Dompet & Rekening',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const WalletsScreen()),
                          );
                        },
                        child: const Text('Atur'),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: wallets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final w = wallets[index];
                      final bal = balances[w.id!] ?? w.initialBalance;
                      return WalletCard(wallet: w, balance: bal);
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // 3. ANALISIS PENGELUARAN (DONUT CHART)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: Theme.of(context).dividerColor.withAlpha(40),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Proporsi ${fmtMonthYear(state.selectedMonth)}',
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const Icon(Icons.pie_chart, color: Color(0xFF0EA5E9), size: 20),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DonutChart(slices: slices, totalExpense: totalExp),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 4. TREN 7 HARI TERAKHIR (BAR CHART)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: Theme.of(context).dividerColor.withAlpha(40),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: BarTrendChart(dailyData: dailyData),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 5. TRANSAKSI TERAKHIR
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Transaksi Terakhir',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: onSeeAllTransactions,
                        child: const Text('Lihat Semua'),
                      ),
                    ],
                  ),
                ),
                if (recentTransactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Belum ada transaksi tercatat.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  )
                else
                  ...recentTransactions.map((tx) {
                    final cat = tx.categoryId != null ? categoryMap[tx.categoryId] : null;
                    final wMap = {for (var w in wallets) w.id!: w};
                    return TransactionTile(
                      transaction: tx,
                      category: cat,
                      wallet: wMap[tx.walletId],
                      toWallet: tx.toWalletId != null ? wMap[tx.toWalletId] : null,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddTransactionScreen(existingTransaction: tx),
                          ),
                        );
                      },
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}
