enum UserRole {
  student,
  teacher,
  admin,
  unknown;

  factory UserRole.fromValue(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'STUDENT':
        return UserRole.student;
      case 'TEACHER':
        return UserRole.teacher;
      case 'ADMIN':
        return UserRole.admin;
      default:
        return UserRole.unknown;
    }
  }

  String get apiValue {
    switch (this) {
      case UserRole.student:
        return 'STUDENT';
      case UserRole.teacher:
        return 'TEACHER';
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.unknown:
        return 'UNKNOWN';
    }
  }

  String get label {
    switch (this) {
      case UserRole.student:
        return 'Học sinh';
      case UserRole.teacher:
        return 'Giáo viên';
      case UserRole.admin:
        return 'Quản trị viên';
      case UserRole.unknown:
        return 'Người dùng';
    }
  }
}

class User {
  final int id;
  final String name;
  final String phoneNumber;
  final String? className;
  final String? email;
  final String? dateOfBirth;
  final String? address;
  final String? parentName;
  final String? parentPhone;
  final String? subject;
  final String? employeeCode;
  final List<UserRole> roles;
  final String? createdAt;
  final String? updatedAt;

  const User({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.roles,
    this.className,
    this.email,
    this.dateOfBirth,
    this.address,
    this.parentName,
    this.parentPhone,
    this.subject,
    this.employeeCode,
    this.createdAt,
    this.updatedAt,
  });

  bool get isStudent => roles.contains(UserRole.student);

  bool get isTeacher => roles.contains(UserRole.teacher);

  bool get isAdmin => roles.contains(UserRole.admin);

  String get roleLabel => roles.isEmpty ? 'Người dùng' : roles.first.label;

  String get headlineInfo {
    if (isTeacher) {
      if ((subject ?? '').isNotEmpty) {
        return 'Bộ môn: $subject';
      }
      return roleLabel;
    }
    if ((className ?? '').isNotEmpty) {
      return 'Lớp: $className';
    }
    return roleLabel;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    var rolesNode = json['roles'];
    List<UserRole> rolesList = [];

    if (rolesNode is List) {
      rolesList = rolesNode.map((r) {
        if (r is Map) return UserRole.fromValue(r['name']?.toString());
        return UserRole.fromValue(r.toString());
      }).toList();
    } else if (json['role'] != null) {
      // Fallback for single role if needed
      final dynamic roleData = json['role'];
      final String? roleName = roleData is Map<String, dynamic>
          ? roleData['name']?.toString()
          : roleData?.toString();
      rolesList = [UserRole.fromValue(roleName)];
    }

    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      className: json['className']?.toString(),
      email: json['email']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      address: json['address']?.toString(),
      parentName: json['parentName']?.toString(),
      parentPhone: json['parentPhone']?.toString(),
      subject: json['subject']?.toString(),
      employeeCode: json['employeeCode']?.toString(),
      roles: rolesList,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'className': className,
      'email': email,
      'dateOfBirth': dateOfBirth,
      'address': address,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'subject': subject,
      'employeeCode': employeeCode,
      'roles': roles.map((r) => {'name': r.apiValue}).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}