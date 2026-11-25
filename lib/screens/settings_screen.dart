import 'package:flutter/material.dart';
import '../services/export_service.dart';
import '../state/app_state.dart';
import 'categories_screen.dart';
import 'wallets_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showSetPinDialog(BuildContext context) {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat PIN Keamanan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukkan 4-6 angka untuk mengunci aplikasi.'),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'PIN (4-6 Digit)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            child: const Text('Aktifkan'),
            onPressed: () async {
              final pin = pinController.text.trim();
              if (pin.length < 4) return;

              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(ctx);

              await AppState.instance.setPin(pin);
              if (!context.mounted || !ctx.mounted) return;
              nav.pop();
              messenger.showSnackBar(
                const SnackBar(content: Text('PIN keamanan berhasil diaktifkan')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmRemovePin(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nonaktifkan Kunci Aplikasi?'),
        content: const Text('Aplikasi tidak akan meminta PIN atau biometrik saat dibuka.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Nonaktifkan'),
            onPressed: () async {
              Navigator.pop(ctx);
              await AppState.instance.removePin();
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

        return Scaffold(
          appBar: AppBar(
            title: const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              // 1. TAMPILAN & TEMA
              _buildSectionHeader('Tampilan'),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Tema Aplikasi'),
                subtitle: Text(
                  state.themeMode == ThemeMode.system
                      ? 'Mengikuti Sistem'
                      : (state.themeMode == ThemeMode.dark ? 'Mode Gelap' : 'Mode Terang'),
                ),
                trailing: PopupMenuButton<ThemeMode>(
                  initialValue: state.themeMode,
                  onSelected: (mode) => state.setThemeMode(mode),
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(value: ThemeMode.system, child: Text('Mengikuti Sistem')),
                    PopupMenuItem(value: ThemeMode.light, child: Text('Mode Terang')),
                    PopupMenuItem(value: ThemeMode.dark, child: Text('Mode Gelap')),
                  ],
                ),
              ),

              const Divider(),

              // 2. KEAMANAN & PRIVASI
              _buildSectionHeader('Keamanan & Privasi'),
              SwitchListTile(
                secondary: const Icon(Icons.lock_outline),
                title: const Text('Kunci PIN'),
                subtitle: Text(state.isPinSet ? 'PIN Aktif' : 'Nonaktif'),
                value: state.isPinSet,
                onChanged: (val) {
                  if (val) {
                    _showSetPinDialog(context);
                  } else {
                    _confirmRemovePin(context);
                  }
                },
              ),
              if (state.isPinSet)
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint),
                  title: const Text('Buka dengan Sidik Jari / Wajah'),
                  subtitle: const Text('Gunakan sensor biometrik perangkat'),
                  value: state.isBiometricEnabled,
                  onChanged: (val) => state.setBiometricEnabled(val),
                ),

              const Divider(),

              // 3. MASTER DATA
              _buildSectionHeader('Kelola Data Keuangan'),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Dompet & Rekening'),
                subtitle: Text('${state.wallets.length} dompet terdaftar'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WalletsScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text('Kategori Transaksi'),
                subtitle: Text('${state.categories.length} kategori tersedia'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                  );
                },
              ),

              const Divider(),

              // 4. EKSPOR & PENCADANGAN
              _buildSectionHeader('Ekspor & Cadangan'),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined, color: Colors.green),
                title: const Text('Ekspor ke Excel (.xlsx)'),
                subtitle: const Text('Simpan riwayat transaksi dalam format spreadsheet'),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await ExportService.instance.exportToExcel(
                    transactions: state.transactions,
                    wallets: state.wallets,
                    categories: state.categories,
                  );
                  if (!context.mounted) return;
                  if (!ok) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Gagal mengekspor data ke Excel')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined, color: Colors.blue),
                title: const Text('Ekspor ke CSV (.csv)'),
                subtitle: const Text('Format teks terpisah titik koma'),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await ExportService.instance.exportToCsv(
                    transactions: state.transactions,
                    wallets: state.wallets,
                    categories: state.categories,
                  );
                  if (!context.mounted) return;
                  if (!ok) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Gagal mengekspor data ke CSV')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud_download_outlined, color: Color(0xFF0EA5E9)),
                title: const Text('Cadangkan Data (.json)'),
                subtitle: const Text('Buat file cadangan lengkap dari semua data'),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await ExportService.instance.createBackupFile();
                  if (!context.mounted) return;
                  if (!ok) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Gagal membuat file cadangan')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.restore_outlined, color: Colors.orange),
                title: const Text('Pulihkan Data dari Cadangan'),
                subtitle: const Text('Pilih file .json cadangan sebelumnya'),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await ExportService.instance.restoreFromBackupFile();
                  if (!context.mounted) return;
                  if (ok) {
                    await state.refreshAllData();
                    if (!context.mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Data berhasil dipulihkan!')),
                    );
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Pemulihan data dibatalkan atau gagal')),
                    );
                  }
                },
              ),

              const Divider(),

              // 5. TENTANG AWAN CASH
              _buildSectionHeader('Tentang'),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Awan Cash'),
                subtitle: const Text('Versi 1.0.0 • 100% Offline • Bebas Iklan'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Privasi Aman',
                    style: TextStyle(
                      color: Color(0xFF0EA5E9),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Awan Cash dirancang untuk kecepatan dan privasi. Semua catatan transaksi, saldo, dan bukti foto Anda tersimpan secara eksklusif di dalam memori smartphone tanpa dikirimkan ke server mana pun.',
                  style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0EA5E9),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
