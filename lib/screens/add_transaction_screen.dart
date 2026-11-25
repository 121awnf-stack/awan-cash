import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/dates.dart';
import '../core/format.dart';
import '../core/icons.dart';
import '../models/transaction_entry.dart';
import '../state/app_state.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionEntry? existingTransaction;

  const AddTransactionScreen({super.key, this.existingTransaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late TransactionType _selectedType;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  int? _selectedWalletId;
  int? _selectedToWalletId;
  int? _selectedCategoryId;
  DateTime _selectedDateTime = DateTime.now();
  String? _receiptImagePath;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTransaction;
    if (existing != null) {
      _selectedType = existing.type;
      _amountController.text = formatThousands(existing.amount);
      _selectedWalletId = existing.walletId;
      _selectedToWalletId = existing.toWalletId;
      _selectedCategoryId = existing.categoryId;
      _selectedDateTime = existing.dateTime;
      _notesController.text = existing.notes ?? '';
      _receiptImagePath = existing.receiptPath;
    } else {
      _selectedType = TransactionType.expense;
      final wallets = AppState.instance.wallets;
      if (wallets.isNotEmpty) {
        _selectedWalletId = wallets.first.id;
        if (wallets.length > 1) {
          _selectedToWalletId = wallets[1].id;
        }
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addQuickAmount(int value) {
    final current = parseAmount(_amountController.text);
    final next = current + value;
    _amountController.text = formatThousands(next);
  }

  Future<void> _pickReceipt(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() {
          _receiptImagePath = picked.path;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _saveTransaction() async {
    final amount = parseAmount(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal transaksi harus lebih dari 0')),
      );
      return;
    }

    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih dompet terlebih dahulu')),
      );
      return;
    }

    if (_selectedType == TransactionType.transfer) {
      if (_selectedToWalletId == null || _selectedToWalletId == _selectedWalletId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih dompet tujuan yang berbeda')),
        );
        return;
      }
    } else {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
        );
        return;
      }
    }

    final entry = TransactionEntry(
      id: widget.existingTransaction?.id,
      type: _selectedType,
      amount: amount,
      walletId: _selectedWalletId!,
      toWalletId: _selectedType == TransactionType.transfer ? _selectedToWalletId : null,
      categoryId: _selectedType == TransactionType.transfer ? null : _selectedCategoryId,
      dateTime: _selectedDateTime,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      receiptPath: _receiptImagePath,
    );

    if (widget.existingTransaction != null) {
      await AppState.instance.updateTransaction(entry);
    } else {
      await AppState.instance.addTransaction(entry);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: const Text('Apakah Anda yakin ingin menghapus catatan transaksi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && widget.existingTransaction?.id != null) {
      await AppState.instance.deleteTransaction(widget.existingTransaction!.id!);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final wallets = state.wallets;
    final categories = state.categories
        .where((c) =>
            _selectedType == TransactionType.income
                ? c.type == TransactionType.income
                : c.type == TransactionType.expense)
        .toList();

    // Pastikan selected category valid untuk tipe saat ini
    if (_selectedType != TransactionType.transfer &&
        _selectedCategoryId != null &&
        !categories.any((c) => c.id == _selectedCategoryId)) {
      _selectedCategoryId = categories.isNotEmpty ? categories.first.id : null;
    }

    final isExpense = _selectedType == TransactionType.expense;
    final isIncome = _selectedType == TransactionType.income;
    final activeColor = isExpense
        ? const Color(0xFFF43F5E)
        : (isIncome ? const Color(0xFF10B981) : const Color(0xFF6366F1));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTransaction != null
            ? 'Ubah Catatan'
            : 'Catat Transaksi'),
        actions: [
          if (widget.existingTransaction != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _confirmDelete,
              tooltip: 'Hapus',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. SELECTOR TIPE TRANSAKSI
          SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(
                value: TransactionType.expense,
                label: Text('Pengeluaran'),
                icon: Icon(Icons.arrow_upward),
              ),
              ButtonSegment(
                value: TransactionType.income,
                label: Text('Pemasukan'),
                icon: Icon(Icons.arrow_downward),
              ),
              ButtonSegment(
                value: TransactionType.transfer,
                label: Text('Transfer'),
                icon: Icon(Icons.swap_horiz),
              ),
            ],
            selected: {_selectedType},
            onSelectionChanged: (set) {
              setState(() {
                _selectedType = set.first;
              });
            },
          ),

          const SizedBox(height: 20),

          // 2. INPUT NOMINAL DENGAN FORMAT IDR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: activeColor.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: activeColor.withAlpha(80), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nominal Transaksi (Rp)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: activeColor,
                  ),
                ),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsInputFormatter()],
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: activeColor,
                  ),
                  decoration: const InputDecoration(
                    prefixText: 'Rp ',
                    border: InputBorder.none,
                    hintText: '0',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Tombol cepat nominal (+10k, +50k, +100k, +500k)
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('+10 rb'),
                onPressed: () => _addQuickAmount(10000),
              ),
              ActionChip(
                label: const Text('+20 rb'),
                onPressed: () => _addQuickAmount(20000),
              ),
              ActionChip(
                label: const Text('+50 rb'),
                onPressed: () => _addQuickAmount(50000),
              ),
              ActionChip(
                label: const Text('+100 rb'),
                onPressed: () => _addQuickAmount(100000),
              ),
              ActionChip(
                label: const Text('+500 rb'),
                onPressed: () => _addQuickAmount(500000),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 3. KATEGORI (KHUSUS PEMASUKAN & PENGELUARAN)
          if (_selectedType != TransactionType.transfer) ...[
            const Text(
              'Pilih Kategori',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final isSelected = _selectedCategoryId == cat.id;
                final catColor = Color(cat.color);

                return ChoiceChip(
                  avatar: Icon(
                    categoryIcon(cat.icon),
                    size: 18,
                    color: isSelected ? Colors.white : catColor,
                  ),
                  label: Text(cat.name),
                  selected: isSelected,
                  selectedColor: catColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedCategoryId = cat.id);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // 4. PILIH DOMPET
          if (_selectedType == TransactionType.transfer) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dari Dompet',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        value: _selectedWalletId,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: wallets.map((w) {
                          return DropdownMenuItem(value: w.id, child: Text(w.name));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedWalletId = val),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, color: Colors.grey),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ke Dompet',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        value: _selectedToWalletId,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: wallets.map((w) {
                          return DropdownMenuItem(value: w.id, child: Text(w.name));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedToWalletId = val),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            const Text('Sumber Dompet',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedWalletId,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: wallets.map((w) {
                return DropdownMenuItem(
                  value: w.id,
                  child: Row(
                    children: [
                      Icon(categoryIcon(w.icon), color: Color(w.color), size: 20),
                      const SizedBox(width: 10),
                      Text(w.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedWalletId = val),
            ),
          ],

          const SizedBox(height: 16),

          // 5. TANGGAL & WAKTU
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_month, color: Color(0xFF0EA5E9)),
            title: Text(fmtDate(_selectedDateTime)),
            subtitle: Text('Pukul ${fmtTime(_selectedDateTime)}'),
            trailing: const Icon(Icons.edit_calendar, size: 20),
            onTap: _pickDateTime,
          ),

          const Divider(),

          // 6. CATATAN / KETERANGAN
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Catatan (opsional)',
              hintText: 'Misal: Nasi Padang, Bensin Pertamax...',
              prefixIcon: const Icon(Icons.edit_note),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 16),

          // 7. FOTO STRUK / BUKTI
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Kamera'),
                  onPressed: () => _pickReceipt(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeri'),
                  onPressed: () => _pickReceipt(ImageSource.gallery),
                ),
              ),
            ],
          ),

          if (_receiptImagePath != null) ...[
            const SizedBox(height: 12),
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_receiptImagePath!),
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                IconButton.filled(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _receiptImagePath = null),
                ),
              ],
            ),
          ],

          const SizedBox(height: 28),

          // 8. TOMBOL SIMPAN
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              backgroundColor: activeColor,
            ),
            icon: const Icon(Icons.check),
            label: const Text(
              'Simpan Catatan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: _saveTransaction,
          ),
        ],
      ),
    );
  }
}
