import 'package:flutter/material.dart';

class HeaderSection extends StatelessWidget {

  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDarkMode = theme.brightness == Brightness.dark;
    return Card(
      color: isDarkMode ? Colors.grey[900] :  Colors.white,
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText: "العميل", border: OutlineInputBorder()),
                value: "عميل كاش",
                items: const [
                  DropdownMenuItem(value: "عميل كاش", child: Text("عميل كاش")),
                  DropdownMenuItem(value: "عميل مسجل", child: Text("عميل مسجل")),
                  DropdownMenuItem(value: "محمد عماد", child: Text("محمد عماد")),
                  DropdownMenuItem(value: "احمد سامي", child: Text("احمد سامي")),
                ],
                onChanged: (_) {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText: "طريقة الدفع", border: OutlineInputBorder()),
                value: "الدفع نقدي",
                items: const [
                  DropdownMenuItem(value: "الدفع نقدي", child: Text("الدفع نقدي")),
                  DropdownMenuItem(value: "بطاقة", child: Text("بطاقة")),
                  DropdownMenuItem(value: "تحويل", child: Text("تحويل")),
                ],
                onChanged: (_) {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
