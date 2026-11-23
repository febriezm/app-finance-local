import 'package:flutter/material.dart';

class AppIcons {
  AppIcons._();

  static IconData getIcon(String? iconKey) {
    switch (iconKey) {
      // Wallets
      case 'wallet':
      case 'cash':
        return Icons.account_balance_wallet_rounded;
      case 'bank':
        return Icons.account_balance_rounded;
      case 'e_wallet':
      case 'e-wallet':
      case 'card':
        return Icons.credit_card_rounded;
      case 'savings':
        return Icons.savings_rounded;

      // Income Categories
      case 'briefcase':
        return Icons.work_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'trending-up':
      case 'investment':
        return Icons.trending_up_rounded;
      case 'plus-circle':
        return Icons.add_circle_outline_rounded;

      // Expense Categories
      case 'utensils':
      case 'food':
        return Icons.restaurant_rounded;
      case 'car':
      case 'transport':
        return Icons.directions_car_rounded;
      case 'file-text':
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'shopping-bag':
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'film':
      case 'entertainment':
        return Icons.movie_rounded;
      case 'heart':
      case 'health':
        return Icons.favorite_rounded;
      case 'more-horizontal':
      case 'other':
      default:
        return Icons.category_rounded;
    }
  }

  static Color parseColor(String? colorHex, {Color defaultColor = const Color(0xFF0E7A4A)}) {
    if (colorHex == null || colorHex.isEmpty) return defaultColor;
    try {
      final hex = colorHex.replaceAll('#', '').replaceAll('0x', '').replaceAll('0X', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return defaultColor;
  }
}
