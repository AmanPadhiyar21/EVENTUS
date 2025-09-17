class UserModel {
  final String name;
  final String email;
  final List<String> interests;

  UserModel({required this.name, required this.email, required this.interests});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'],
      email: json['email'],
      interests: List<String>.from(json['interests'] ?? []),
    );
  }
}
