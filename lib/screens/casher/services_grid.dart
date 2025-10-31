import 'package:flutter/material.dart';
import 'models/service-model.dart';

class ServicesGrid extends StatelessWidget {
  final Function(ServiceModel) onAddService;

  const ServicesGrid({super.key, required this.onAddService});

  @override
  Widget build(BuildContext context) {
    final services = [
      ServiceModel(name: "تصفيف وقص الشعر", price: 20, category: ''),
      ServiceModel(name: "تنعيم وتجميد الشعر", price: 44, category: ''),
      ServiceModel(name: "قص الشعر", price: 15, category: ''),
      ServiceModel(name: "صبغ وتلوين الشعر", price: 18, category: ''),
      ServiceModel(name: "تسريحة حفلات", price: 30, category: ''),
      ServiceModel(name: "تنظيف وجه", price: 25, category: ''),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return InkWell(
          onTap: () => onAddService(service),
          child: Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cut, size: 40, color: Colors.blueGrey),
                  const SizedBox(height: 10),
                  Text(
                    service.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text("${service.price} ر.س",
                      style: const TextStyle(
                          color: Colors.teal, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
