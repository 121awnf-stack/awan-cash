import 'package:flutter/material.dart';
import '../core/icons.dart';
import '../models/category.dart';
import '../state/app_state.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddEditCategoryDialog({Category? existingCategory, TransactionType? defaultType}) {
    final nameController = TextEditingController(text: existingCategory?.name ?? '');
    TransactionType selectedType = existingCategory?.type ?? defaultType ?? TransactionType.expense;
    String selectedIcon = existingCategory?.icon ?? 'restaurant';
    int selectedColor = existingCategory?.color ?? kPalette.first;

    final availableIcons = kCategoryIcons.keys.toList();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(existingCategory != null ? 'Ubah Kategori' : 'Tambah Kategori'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nama Kategori'),
                    ),
                    const SizedBox(height: 12),
                    if (existingCategory == null)
                      DropdownButtonFormField<TransactionType>(
                        value: selectedType,
                        decoration: const InputDecoration(labelText: 'Tipe'),
                        items: const [
                          DropdownMenuItem(value: TransactionType.expense, child: Text('Pengeluaran')),
                          DropdownMenuItem(value: TransactionType.income, child: Text('Pemasukan')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedType = val);
                        },
                      ),
                    const SizedBox(height: 14),
                    const Text('Pilih Ikon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      width: double.maxFinite,
                      child: GridView.builder(
                        itemCount: availableIcons.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                        ),
                        itemBuilder: (ctx, i) {
                          final iconKey = availableIcons[i];
                          final isSelected = selectedIcon == iconKey;
                          return InkWell(
                            onTap: () => setDialogState(() => selectedIcon = iconKey),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF0EA5E9).withAlpha(50)
                                    : Colors.grey.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected
                                    ? Border.all(color: const Color(0xFF0EA5E9), width: 2)
                                    : null,
                              ),
                              child: Icon(categoryIcon(iconKey), size: 22),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Pilih Warna', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kPalette.map((colorInt) {
                        final isSelected = selectedColor == colorInt;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = colorInt),
                          child: Container(
                            width: 28,
                            height: 28,
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

                    final category = Category(
                      id: existingCategory?.id,
                      name: name,
                      type: selectedType,
                      icon: selectedIcon,
                      color: selectedColor,
                    );

                    if (existingCategory != null) {
                      await AppState.instance.updateCategory(category);
                    } else {
                      await AppState.instance.addCategory(category);
                    }

                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteCategory(Category cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus ${cat.name}?'),
        content: const Text('Kategori ini akan dihapus dari daftar.'),
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
              await AppState.instance.deleteCategory(cat.id!);
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
        final expenseCategories =
            state.categories.where((c) => c.type == TransactionType.expense).toList();
        final incomeCategories =
            state.categories.where((c) => c.type == TransactionType.income).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Kategori Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Pengeluaran'),
                Tab(text: 'Pemasukan'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () {
              final activeType = _tabController.index == 0
                  ? TransactionType.expense
                  : TransactionType.income;
              _showAddEditCategoryDialog(defaultType: activeType);
            },
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryList(expenseCategories),
              _buildCategoryList(incomeCategories),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryList(List<Category> list) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final cat = list[index];
        final color = Color(cat.color);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor.withAlpha(40)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(categoryIcon(cat.icon), color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  cat.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => _showAddEditCategoryDialog(existingCategory: cat),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                onPressed: () => _confirmDeleteCategory(cat),
              ),
            ],
          ),
        );
      },
    );
  }
}
