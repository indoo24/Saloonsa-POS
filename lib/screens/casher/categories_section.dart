import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoriesSection extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategoriesSection({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  static const List<String> categories = [
    "تصفيف وقص الشعر",
    "خدمات العناية بالبشرة",
    "خدمات الأظافر",
    "الشعر",
    "استشوار",
    "تسريحة",
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (_) => onCategorySelected(category),
            labelStyle: GoogleFonts.cairo(
              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            backgroundColor: theme.colorScheme.surface,
            selectedColor: theme.colorScheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            showCheckmark: false,
            elevation: isSelected ? 4 : 2,
          );
        },
      ),
    );
  }
}
