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

  // فئة حلاقة ذقن
  ServiceModel(name: "حلاقة ذقن كلاسيكية", price: 40, category: "حلاقة ذقن"),
  ServiceModel(name: "تحديد ذقن بالموس", price: 35, category: "حلاقة ذقن"),
  ServiceModel(name: "تنظيف الذقن بالبخار", price: 45, category: "حلاقة ذقن"),
  ServiceModel(name: "صبغة ذقن", price: 55, category: "حلاقة ذقن"),

  // فئة الاستشوار
  ServiceModel(name: "استشوار عادي", price: 25, category: "استشوار"),
  ServiceModel(name: "استشوار مع كريم حماية", price: 35, category: "استشوار"),
  ServiceModel(name: "استشوار بعد الحلاقة", price: 30, category: "استشوار"),
  ServiceModel(name: "استشوار مع تسريحة سريعة", price: 40, category: "استشوار"),

  // فئة التسريحة
  ServiceModel(name: "تسريحة كلاسيكية", price: 45, category: "تسريحة"),
  ServiceModel(name: "تسريحة عصرية", price: 50, category: "تسريحة"),
  ServiceModel(name: "تسريحة بح gel", price: 35, category: "تسريحة"),
  ServiceModel(name: "تسريحة خاصة للمناسبات", price: 60, category: "تسريحة"),
];
