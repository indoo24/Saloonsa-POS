import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/category.dart';

class CategoriesSection extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;
  final List<Category> categories;

  const CategoriesSection({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Add "الكل" (All) option at the beginning
    final allCategories = [Category(id: 0, name: 'الكل'), ...categories];

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: allCategories.length,
        itemBuilder: (context, index) {
          final category = allCategories[index];
          final isSelected = category.name == selectedCategory;

          return ChoiceChip(
            label: Text(category.name),
            selected: isSelected,
            onSelected: (_) {
              // Close keyboard when selecting category
              FocusScope.of(context).unfocus();
              onCategorySelected(category.name);
            },
            labelStyle: GoogleFonts.cairo(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            backgroundColor: theme.colorScheme.surface,
            selectedColor: theme.colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            showCheckmark: false,
            elevation: isSelected ? 4 : 2,
          );
        },
      ),
    );
  }
}
