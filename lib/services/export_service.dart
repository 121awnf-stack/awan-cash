import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/dates.dart';
import '../models/transaction_entry.dart';
import '../models/wallet.dart';
import '../models/category.dart';
import 'database_helper.dart';

class ExportService {
  static final ExportService instance = ExportService._internal();

  ExportService._internal();

  /// Ekspor riwayat transaksi ke Excel (.xlsx) dan buka dialog berbagi
  Future<bool> exportToExcel({
    required List<TransactionEntry> transactions,
    required List<Wallet> wallets,
    required List<Category> categories,
  }) async {
    try {
      final walletMap = {for (var w in wallets) w.id!: w.name};
      final categoryMap = {for (var c in categories) c.id!: c.name};

      final excel = Excel.createExcel();
      // Ganti nama sheet default
      final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
      excel.rename(defaultSheet, 'Transaksi');
      final sheet = excel['Transaksi'];

      // Header Kolom
      sheet.appendRow([
        TextCellValue('ID'),
        TextCellValue('Tanggal'),
        TextCellValue('Waktu'),
        TextCellValue('Tipe'),
        TextCellValue('Kategori'),
        TextCellValue('Dompet Asal'),
        TextCellValue('Dompet Tujuan'),
        TextCellValue('Nominal (Rp)'),
        TextCellValue('Catatan'),
      ]);

      for (var tx in transactions) {
        String typeLabel;
        switch (tx.type) {
          case TransactionType.expense:
            typeLabel = 'Pengeluaran';
            break;
          case TransactionType.income:
            typeLabel = 'Pemasukan';
            break;
          case TransactionType.transfer:
            typeLabel = 'Transfer';
            break;
        }

        final categoryName = tx.categoryId != null
            ? (categoryMap[tx.categoryId] ?? '-')
            : (tx.type == TransactionType.transfer ? 'Transfer Saldo' : '-');

        final walletName = walletMap[tx.walletId] ?? 'Dompet #${tx.walletId}';
        final toWalletName = tx.toWalletId != null
            ? (walletMap[tx.toWalletId] ?? 'Dompet #${tx.toWalletId}')
            : '-';

        sheet.appendRow([
          IntCellValue(tx.id ?? 0),
          TextCellValue(fmtDate(tx.dateTime)),
          TextCellValue(fmtTime(tx.dateTime)),
          TextCellValue(typeLabel),
          TextCellValue(categoryName),
          TextCellValue(walletName),
          TextCellValue(toWalletName),
          IntCellValue(tx.amount),
          TextCellValue(tx.notes ?? ''),
        ]);
      }

      final bytes = excel.save();
      if (bytes == null) return false;

      final tempDir = await getTemporaryDirectory();
      final stamp = fmtFileStamp(DateTime.now());
      final filePath = '${tempDir.path}/AwanCash_Transaksi_$stamp.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          text: 'Laporan Keuangan Awan Cash ($stamp)',
          subject: 'Laporan Keuangan Awan Cash',
        ),
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Menghasilkan representasi string CSV dari data transaksi
  String generateCsvString({
    required List<TransactionEntry> transactions,
    required List<Wallet> wallets,
    required List<Category> categories,
  }) {
    final walletMap = {for (var w in wallets) w.id!: w.name};
    final categoryMap = {for (var c in categories) c.id!: c.name};

    final buffer = StringBuffer();
    // UTF-8 BOM untuk membuka otomatis dengan benar di Microsoft Excel
    buffer.write('\uFEFF');
    buffer.writeln('ID;Tanggal;Waktu;Tipe;Kategori;Dompet Asal;Dompet Tujuan;Nominal;Catatan');

    for (var tx in transactions) {
      String typeLabel = tx.type == TransactionType.expense
          ? 'Pengeluaran'
          : (tx.type == TransactionType.income ? 'Pemasukan' : 'Transfer');

      final categoryName = tx.categoryId != null
          ? (categoryMap[tx.categoryId] ?? '-')
          : (tx.type == TransactionType.transfer ? 'Transfer Saldo' : '-');

      final walletName = walletMap[tx.walletId] ?? 'Dompet #${tx.walletId}';
      final toWalletName = tx.toWalletId != null
          ? (walletMap[tx.toWalletId] ?? '-')
          : '-';

      final safeNotes = (tx.notes ?? '').replaceAll(';', ',');

      buffer.writeln(
        '${tx.id};"${fmtDate(tx.dateTime)}";"${fmtTime(tx.dateTime)}";"$typeLabel";"$categoryName";"$walletName";"$toWalletName";${tx.amount};"$safeNotes"',
      );
    }

    return buffer.toString();
  }

  /// Ekspor riwayat transaksi ke file CSV dan bagikan
  Future<bool> exportToCsv({
    required List<TransactionEntry> transactions,
    required List<Wallet> wallets,
    required List<Category> categories,
  }) async {
    try {
      final csvString = generateCsvString(
        transactions: transactions,
        wallets: wallets,
        categories: categories,
      );

      final tempDir = await getTemporaryDirectory();
      final stamp = fmtFileStamp(DateTime.now());
      final filePath = '${tempDir.path}/AwanCash_Transaksi_$stamp.csv';
      final file = File(filePath);
      await file.writeAsString(csvString, encoding: utf8, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          text: 'Laporan Keuangan Awan Cash CSV ($stamp)',
        ),
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Cadangkan seluruh basis data ke file JSON terstruktur
  Future<bool> createBackupFile() async {
    try {
      final data = await DatabaseHelper.instance.exportAllData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      final tempDir = await getTemporaryDirectory();
      final stamp = fmtFileStamp(DateTime.now());
      final filePath = '${tempDir.path}/AwanCash_Backup_$stamp.json';
      final file = File(filePath);
      await file.writeAsString(jsonString, encoding: utf8, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          text: 'File Cadangan Basis Data Awan Cash ($stamp)',
        ),
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Memulihkan basis data dari file JSON cadangan
  Future<bool> restoreFromBackupFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return false;
      final path = result.files.first.path;
      if (path == null) return false;

      final file = File(path);
      final jsonString = await file.readAsString();
      return await DatabaseHelper.instance.importData(jsonString);
    } catch (e) {
      return false;
    }
  }
}
