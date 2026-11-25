import 'dart:io';
import 'package:flutter/material.dart';
import '../core/dates.dart';
import '../core/format.dart';
import '../core/icons.dart';
import '../models/transaction_entry.dart';
import '../models/category.dart';
import '../models/wallet.dart';

class TransactionTile extends StatelessWidget {
  final TransactionEntry transaction;
  final Category? category;
  final Wallet? wallet;
  final Wallet? toWallet;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.category,
    this.wallet,
    this.toWallet,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;

    final Color amountColor = isIncome
        ? const Color(0xFF10B981)
        : (isExpense ? const Color(0xFFF43F5E) : const Color(0xFF6366F1));

    final String prefix = isIncome ? '+ ' : (isExpense ? '- ' : '');

    String title;
    IconData icon;
    Color iconBgColor;

    if (isTransfer) {
      title = 'Transfer: ${wallet?.name ?? "..."} → ${toWallet?.name ?? "..."}';
      icon = Icons.swap_horiz;
      iconBgColor = const Color(0xFF6366F1);
    } else {
      title = category?.name ?? (isExpense ? 'Pengeluaran' : 'Pemasukan');
      icon = category != null ? categoryIcon(category!.icon) : Icons.category;
      iconBgColor = category != null ? Color(category!.color) : Colors.grey;
    }

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconBgColor.withAlpha(35),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconBgColor, size: 24),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (transaction.receiptPath != null &&
              File(transaction.receiptPath!).existsSync())
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.receipt_long, size: 16, color: Colors.grey),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Text(
            fmtTime(transaction.dateTime),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          if (wallet != null && !isTransfer) ...[
            Text(' • ', style: TextStyle(color: Colors.grey.shade400)),
            Text(
              wallet!.name,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
          if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
            Text(' • ', style: TextStyle(color: Colors.grey.shade400)),
            Expanded(
              child: Text(
                transaction.notes!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
      trailing: Text(
        '$prefix${formatRupiah(transaction.amount)}',
        style: TextStyle(
          color: amountColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
