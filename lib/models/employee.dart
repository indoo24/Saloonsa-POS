/// Employee model for API integration
/// Represents a salon employee/staff member
class Employee {
  final int id;
  final String name;
  final String? mobile;
  final double salary;
  final double daySalary;
  final int workingDays;
  final String type;
  final double percent;
  final int? managerId;
  final double target;
  final String? note;
  final bool isActive;
  final String? image;

  Employee({
    required this.id,
    required this.name,
    this.mobile,
    required this.salary,
    required this.daySalary,
    required this.workingDays,
    required this.type,
    required this.percent,
    this.managerId,
    required this.target,
    this.note,
    required this.isActive,
    this.image,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      name: json['name'],
      mobile: json['mobile'],
      salary: (json['salary'] ?? 0).toDouble(),
      daySalary: (json['day_salary'] ?? 0).toDouble(),
      workingDays: json['working_days'] ?? 0,
      type: json['type'] ?? 'normal',
      percent: (json['percent'] ?? 0).toDouble(),
      managerId: json['manager_id'],
      target: (json['target'] ?? 0).toDouble(),
      note: json['note'],
      isActive: json['is_active'] ?? true,
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'salary': salary,
      'day_salary': daySalary,
      'working_days': workingDays,
      'type': type,
      'percent': percent,
      'manager_id': managerId,
      'target': target,
      'note': note,
      'is_active': isActive,
      'image': image,
    };
  }
}
