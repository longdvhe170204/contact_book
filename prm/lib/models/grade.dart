class Grade {
  final int id;
  final int studentId;
  final String? className;
  final int? teacherId;
  final String subject;
  final int semester;
  final List<double> tx15;
  final List<double> tx1tiet;
  final double? giuaKy;
  final double? cuoiKy;
  final double? average;

  Grade({
    required this.id,
    required this.studentId,
    this.className,
    this.teacherId,
    required this.subject,
    required this.semester,
    required this.tx15,
    required this.tx1tiet,
    this.giuaKy,
    this.cuoiKy,
    this.average,
  });

  factory Grade.fromJson(Map<String, dynamic> json) {
    List<double> parseList(dynamic input) {
      if (input is List) {
        return input.map((e) => (e as num).toDouble()).toList();
      }
      return const [];
    }

    double? parseDouble(dynamic input) {
      if (input == null) {
        return null;
      }
      if (input is num) {
        return input.toDouble();
      }
      return double.tryParse(input.toString());
    }

    return Grade(
      id: json['id'] ?? 0,
      studentId: json['studentId'] ?? 0,
      className: json['className']?.toString(),
      teacherId: json['teacherId'] as int?,
      subject: json['subject'] ?? '',
      semester: json['semester'] ?? 1,
      tx15: parseList(json['tx15']),
      tx1tiet: parseList(json['tx1tiet']),
      giuaKy: parseDouble(json['giuaKy']),
      cuoiKy: parseDouble(json['cuoiKy']),
      average: parseDouble(json['average']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'className': className,
      'teacherId': teacherId,
      'subject': subject,
      'semester': semester,
      'tx15': tx15,
      'tx1tiet': tx1tiet,
      'giuaKy': giuaKy,
      'cuoiKy': cuoiKy,
      'average': average,
    };
  }
}
