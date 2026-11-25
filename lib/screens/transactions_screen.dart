import 'package:flutter/material.dart';
import '../core/dates.dart';
import '../models/transaction_entry.dart';
import '../state/app_state.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _searchQuery = '';
  TransactionType? _typeFilter;
  int? _walletFilter;
  String _dateRangeFilter = 'month'; // 'all', 'today', 'week', 'month'

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final allTransactions = state.transactions;
        final wallets = state.wallets;
        final categories = state.categories;

        final categoryMap = {for (var c in categories) c.id!: c};
        final walletMap = {for (var w in wallets) w.id!: w};

        // Filter Transaksi
        final filtered = allTransactions.where((tx) {
          // Filter tipe
          if (_typeFilter != null && tx.type != _typeFilter) return false;

          // Filter dompet
          if (_walletFilter != null &&
              tx.walletId != _walletFilter &&
              tx.toWalletId != _walletFilter) {
            return false;
          }

          // Filter rentang tanggal
          final now = DateTime.now();
          if (_dateRangeFilter == 'today') {
            if (!dayRange(now).contains(tx.dateTime)) return false;
          } else if (_dateRangeFilter == 'week') {
            if (!weekRange(now).contains(tx.dateTime)) return false;
          } else if (_dateRangeFilter == 'month') {
            if (!monthRange(state.selectedMonth).contains(tx.dateTime)) return false;
          }

          // Filter pencarian
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final catName =
                tx.categoryId != null ? (categoryMap[tx.categoryId]?.name.toLowerCase() ?? '') : '';
            final notes = tx.notes?.toLowerCase() ?? '';
            final amountStr = tx.amount.toString();
            final walletName = walletMap[tx.walletId]?.name.toLowerCase() ?? '';

            if (!catName.contains(q) &&
                !notes.contains(q) &&
                !amountStr.contains(q) &&
                !walletName.contains(q)) {
              return false;
            }
          }

          return true;
        }).toList();

        // Kelompokkan per tanggal
        final grouped = <String, List<TransactionEntry>>{};
        for (var tx in filtered) {
          final dayKey = fmtDayHeader(tx.dateTime);
          grouped.putIfAbsent(dayKey, () => []).add(tx);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Riwayat Transaksi',
                style: TextStyle(fontWeight: FontWeight.bold)),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(105),
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SearchBar(
                      hintText: 'Cari catatan, kategori, nominal...',
                      leading: const Icon(Icons.search, size: 20),
                      elevation: const WidgetStatePropertyAll(0),
                      backgroundColor: WidgetStatePropertyAll(
                        Theme.of(context).cardColor,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Rentang Waktu
                        PopupMenuButton<String>(
                          initialValue: _dateRangeFilter,
                          onSelected: (val) => setState(() => _dateRangeFilter = val),
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'month', child: Text('Bulan Ini')),
                            const PopupMenuItem(value: 'week', child: Text('Minggu Ini')),
                            const PopupMenuItem(value: 'today', child: Text('Hari Ini')),
                            const PopupMenuItem(value: 'all', child: Text('Semua Waktu')),
                          ],
                          child: Chip(
                            avatar: const Icon(Icons.calendar_today, size: 16),
                            label: Text(_dateRangeFilter == 'month'
                                ? 'Bulan Ini'
                                : (_dateRangeFilter == 'week'
                                    ? 'Minggu Ini'
                                    : (_dateRangeFilter == 'today' ? 'Hari Ini' : 'Semua Waktu'))),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Tipe Transaksi
                        PopupMenuButton<TransactionType?>(
                          initialValue: _typeFilter,
                          onSelected: (val) => setState(() => _typeFilter = val),
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: null, child: Text('Semua Tipe')),
                            const PopupMenuItem(
                                value: TransactionType.expense, child: Text('Pengeluaran')),
                            const PopupMenuItem(
                                value: TransactionType.income, child: Text('Pemasukan')),
                            const PopupMenuItem(
                                value: TransactionType.transfer, child: Text('Transfer')),
                          ],
                          child: Chip(
                            avatar: const Icon(Icons.filter_list, size: 16),
                            label: Text(_typeFilter == null
                                ? 'Tipe: Semua'
                                : (_typeFilter == TransactionType.expense
                                    ? 'Pengeluaran'
                                    : (_typeFilter == TransactionType.income
                                        ? 'Pemasukan'
                                        : 'Transfer'))),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Dompet
                        PopupMenuButton<int?>(
                          initialValue: _walletFilter,
                          onSelected: (val) => setState(() => _walletFilter = val),
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: null, child: Text('Semua Dompet')),
                            ...wallets.map((w) => PopupMenuItem(
                                  value: w.id,
                                  child: Text(w.name),
                                )),
                          ],
                          child: Chip(
                            avatar: const Icon(Icons.account_balance_wallet, size: 16),
                            label: Text(_walletFilter == null
                                ? 'Dompet: Semua'
                                : (walletMap[_walletFilter]?.name ?? 'Dompet')),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
          body: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'Tidak ada transaksi yang cocok.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final dayHeader = grouped.keys.elementAt(index);
                    final dayTxs = grouped[dayHeader]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                          child: Text(
                            dayHeader,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        ...dayTxs.map((tx) {
                          return TransactionTile(
                            transaction: tx,
                            category: tx.categoryId != null ? categoryMap[tx.categoryId] : null,
                            wallet: walletMap[tx.walletId],
                            toWallet: tx.toWalletId != null ? walletMap[tx.toWalletId] : null,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AddTransactionScreen(existingTransaction: tx),
                                ),
                              );
                            },
                          );
                        }),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }
}
