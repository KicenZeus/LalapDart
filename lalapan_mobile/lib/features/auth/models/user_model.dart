class UserModel {
  final String id;
  final String username;
  final String fullName;
  final String role;
  final String? institutionId;
  final String? institutionName;
  final String? email;
  final String? phone;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.institutionId,
    this.institutionName,
    this.email,
    this.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? json['full_name'] ?? '',
      role: json['role'] ?? 'OPERATOR_RS',
      institutionId: json['institutionId'] ?? json['institution_id'],
      institutionName: json['institutionName'] ?? json['institution_name'],
      email: json['email'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'role': role,
      'institutionId': institutionId,
      'institutionName': institutionName,
      'email': email,
      'phone': phone,
    };
  }

  bool get isOperatorRs => role == 'OPERATOR_RS';
  bool get isOperatorDukcapil => role == 'OPERATOR_DUKCAPIL';
  bool get isAdmin => role == 'ADMIN';
}
