import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_haptics.dart';
import '../../features/categories/domain/entities/category.dart';

/// Pemilih kategori (*Category Selector*) yang minimalis, flat, dan rapi.
class CategorySelector extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<Category> onSelected;
  final bool isHorizontal;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
    this.isHorizontal = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isHorizontal) {
      return SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isSelected = cat.id == selectedCategoryId;
            return _buildChip(context, cat, isSelected, isDark);
          },
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = cat.id == selectedCategoryId;
        return _buildChip(context, cat, isSelected, isDark);
      }).toList(),
    );
  }

  Widget _buildChip(BuildContext context, Category cat, bool isSelected, bool isDark) {
    final activeBg = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final activeFg = isDark ? AppColors.backgroundDark : Colors.white;
    const inactiveBg = Colors.transparent;
    final inactiveFg = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isSelected
        ? activeBg
        : (isDark ? AppColors.borderDark : AppColors.borderLight);

    return InkWell(
      onTap: () {
        AppHaptics.selection();
        onSelected(cat);
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.getIcon(cat.iconKey),
              size: 15,
              color: isSelected ? activeFg : inactiveFg,
            ),
            const SizedBox(width: 6),
            Text(
              cat.name,
              style: AppTypography.caption.copyWith(
                color: isSelected ? activeFg : inactiveFg,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
