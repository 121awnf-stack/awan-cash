import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final NumberFormat _rupiah =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
final NumberFormat _thousand = NumberFormat.decimalPattern('id_ID');
final NumberFormat _compactRupiah =
    NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp ');

/// Rp 1.500.000
String formatRupiah(int value) => _rupiah.format(value);

/// 1.500.000
String formatThousands(int value) => _thousand.format(value);

/// Rp 1,5 jt
String formatCompactRupiah(int value) => _compactRupiah.format(value);

/// Mengambil nilai rupiah dari teks berformat ("1.500.000" -> 1500000).
int parseAmount(String text) =>
    int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

/// Memformat input nominal secara langsung dengan pemisah ribuan.
class ThousandsInputFormatter extends TextInputFormatter {
  static const int maxDigits = 15;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    if (digits.length > maxDigits) digits = digits.substring(0, maxDigits);
    final text = _thousand.format(int.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
