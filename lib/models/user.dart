/// User model representing authenticated user
class User {
  final int id;
  final String name;
  final String email;
  final String? mobile;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.mobile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      mobile: json['mobile'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'mobile': mobile};
  }

  @override
  String toString() => 'User(id: $id, name: $name, email: $email)';
}
