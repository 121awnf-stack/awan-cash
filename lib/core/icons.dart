import 'package:flutter/material.dart';

/// Ikon disimpan di database sebagai kunci teks, lalu dipetakan ke ikon
/// konstan agar fitur tree-shaking ikon pada build rilis tetap berfungsi.
const Map<String, IconData> kCategoryIcons = {
  'restaurant': Icons.restaurant,
  'local_cafe': Icons.local_cafe,
  'shopping_bag': Icons.shopping_bag,
  'shopping_cart': Icons.shopping_cart,
  'directions_car': Icons.directions_car,
  'two_wheeler': Icons.two_wheeler,
  'local_gas_station': Icons.local_gas_station,
  'receipt_long': Icons.receipt_long,
  'bolt': Icons.bolt,
  'wifi': Icons.wifi,
  'phone_android': Icons.phone_android,
  'home': Icons.home,
  'movie': Icons.movie,
  'sports_esports': Icons.sports_esports,
  'local_hospital': Icons.local_hospital,
  'school': Icons.school,
  'volunteer_activism': Icons.volunteer_activism,
  'pets': Icons.pets,
  'child_care': Icons.child_care,
  'checkroom': Icons.checkroom,
  'flight': Icons.flight,
  'fitness_center': Icons.fitness_center,
  'payments': Icons.payments,
  'card_giftcard': Icons.card_giftcard,
  'trending_up': Icons.trending_up,
  'storefront': Icons.storefront,
  'redeem': Icons.redeem,
  'work': Icons.work,
  'savings': Icons.savings,
  'more_horiz': Icons.more_horiz,
};

IconData categoryIcon(String key) => kCategoryIcons[key] ?? Icons.category;

const List<int> kPalette = [
  0xFF0EA5E9, // biru langit
  0xFF3B82F6, // biru
  0xFF6366F1, // indigo
  0xFF8B5CF6, // violet
  0xFFA855F7, // ungu
  0xFFEC4899, // pink
  0xFFF43F5E, // merah koral
  0xFFF97316, // oranye
  0xFFF59E0B, // amber
  0xFFEAB308, // kuning
  0xFF84CC16, // lime
  0xFF10B981, // emerald
  0xFF14B8A6, // teal
  0xFF06B6D4, // cyan
  0xFF64748B, // slate
  0xFF78716C, // stone
];
