import 'package:flutter/material.dart';
import '../core/format.dart';
import '../core/icons.dart';
import '../models/wallet.dart';
import '../state/app_state.dart';

class WalletsScreen extends StatelessWidget {
  const WalletsScreen({super.key});

  void _showAddEditWalletDialog(BuildContext context, {Wallet? existingWallet}) {
    final nameController = TextEditingController(text: existingWallet?.name ?? '');
    final balanceController = TextEditingController(
      text: existingWallet != null ? formatThousands(existingWallet.initialBalance) : '',
    );
    WalletType selectedType = existingWallet?.type ?? WalletType.cash;
    int selectedColor = existingWallet?.color ?? kPalette.first;
    String selectedIcon = existingWallet?.icon ?? 'payments';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(existingWallet != null ? 'Ubah Dompet' : 'Tambah Dompet Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Dompet / Rekening',
                        hintText: 'Misal: BCA, GoPay, Dompet Saku',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<WalletType>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Tipe Dompet'),
                      items: const [
                        DropdownMenuItem(value: WalletType.cash, child: Text('Uang Tunai')),
                        DropdownMenuItem(value: WalletType.bank, child: Text('Rekening Bank')),
                        DropdownMenuItem(value: WalletType.ewallet, child: Text('Dompet Digital (E-Wallet)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedType = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: balanceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [ThousandsInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Saldo Awal (Rp)',
                        prefixText: 'Rp ',
                        hintText: '0',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Warna Kartu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kPalette.take(8).map((colorInt) {
                        final isSelected = selectedColor == colorInt;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = colorInt),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Color(colorInt),
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.black, width: 2.5)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  child: const Text('Simpan'),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final initBal = parseAmount(balanceController.text);
                    final wallet = Wallet(
                      id: existingWallet?.id,
                      name: name,
                      type: selectedType,
                      initialBalance: initBal,
                      color: selectedColor,
                      icon: selectedIcon,
                    );

                    if (existingWallet != null) {
                      await AppState.instance.updateWallet(wallet);
                    } else {
                      await AppState.instance.addWallet(wallet);
                    }

                    if (context.mounted) Navigator.pop(ctx);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteWallet(BuildContext context, Wallet wallet) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus ${wallet.name}?'),
        content: const Text(
          'Menghapus dompet akan menghapus mutasi dan transaksi yang tertaut dengan dompet ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
            onPressed: () async {
              Navigator.pop(ctx);
              await AppState.instance.deleteWallet(wallet.id!);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final wallets = state.wallets;
        final balances = state.walletBalances;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Kelola Dompet', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Tambah Dompet',
                onPressed: () => _showAddEditWalletDialog(context),
              ),
            ],
          ),
          body: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: wallets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final w = wallets[index];
              final currentBal = balances[w.id!] ?? w.initialBalance;
              final color = Color(w.color);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor.withAlpha(40)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withAlpha(35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(categoryIcon(w.icon), color: color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w.name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Saldo Awal: ${formatRupiah(w.initialBalance)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          Text(
                            'Saldo Sekarang: ${formatRupiah(currentBal)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0EA5E9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _showAddEditWalletDialog(context, existingWallet: w),
                    ),
                    if (wallets.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        onPressed: () => _confirmDeleteWallet(context, w),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
