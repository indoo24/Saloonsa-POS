import '../models/service-model.dart';

final List<ServiceModel> allServices = [
  // فئة قص الشعر
  ServiceModel(name: "قص شعر رجالي", price: 50, category: "قص الشعر"),
  ServiceModel(name: "تدريج جانبي", price: 30, category: "قص الشعر"),
  ServiceModel(name: "تحديد اللحية", price: 25, category: "قص الشعر"),

  // فئة العناية بالبشرة
  ServiceModel(name: "ماسك تنظيف", price: 80, category: "العناية بالبشرة"),
  ServiceModel(name: "تقشير البشرة", price: 60, category: "العناية بالبشرة"),

  // فئة الصبغات
  ServiceModel(name: "صبغة شعر كاملة", price: 100, category: "الصبغات"),
  ServiceModel(name: "هايلايت", price: 120, category: "الصبغات"),
];
