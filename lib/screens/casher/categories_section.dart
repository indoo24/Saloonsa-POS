import 'package:flutter/material.dart';

class CategoriesSection extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategoriesSection({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final categories = [
      "تصفيف وقص الشعر",
      "العناية بالبشرة",
      "الاظافر",
      "الصبغات",
      "بدكير ومنكير",
      "التسريحات",
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      height: 55,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final selected = cat == selectedCategory;
          return ChoiceChip(
            label: Text(cat),
            labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.blueGrey.shade800),
            selectedColor: Colors.blueGrey,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            selected: selected,
            onSelected: (_) => onCategorySelected(cat),
          );
        },
      ),
    );
  }
}
