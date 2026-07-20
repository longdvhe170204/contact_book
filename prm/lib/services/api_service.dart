import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/grade.dart';
import '../models/schedule.dart';
import '../models/notification_model.dart';
import '../models/assignment.dart';
import '../models/teacher_grade.dart';
import '../models/attendance.dart';
import '../models/conduct.dart';
import '../models/chat_message.dart';
import 'storage_service.dart';

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  // Tự động nhận diện nền tảng để đổi baseUrl
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api';
    } else if (Platform.isAndroid) {
      // 10.0.2.2 là địa chỉ IP đặc biệt của Android Emulator để trỏ về localhost của máy tính
      return 'http://10.0.2.2:8080/api';
    } else {
      // Dành cho iOS Simulator hoặc Windows/macOS Desktop app
      return 'http://localhost:8080/api';
    }
  }

  // Common headers
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static dynamic _extractData(dynamic data) {
    if (data is Map && data.containsKey('data')) {
      return data['data'];
    }
    return data;
  }

  // Handle response
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }

  // Extract list from response (handle both array and object with data field)
  static List<dynamic> _extractList(dynamic data) {
    final extracted = _extractData(data);
    if (extracted is List) {
      return extracted;
    }
    return [];
  }

  // ==================== AUTHENTICATION ====================

  static Future<User> login(String phoneNumber, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'phoneNumber': phoneNumber,
          'password': password,
        }),
      );

      final data = _handleResponse(response);
      final jwtResponse = _extractData(data);

      if (jwtResponse == null || jwtResponse['token'] == null) {
        throw Exception('Invalid response: Token not found');
      }

      final String token = jwtResponse['token'];
      final userData = jwtResponse['user'];

      final user = User.fromJson(userData as Map<String, dynamic>);
      await StorageService.saveUser(user, token: token);

      return user;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  static Future<void> forgotPassword(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password').replace(
          queryParameters: {'phoneNumber': phoneNumber},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      _handleResponse(response);
    } catch (e) {
      throw Exception('Forgot password failed: $e');
    }
  }

  // ==================== STUDENTS ====================

  /// GET /api/students/{id}
  /// Output: User with STUDENT role
  static Future<User> getStudent(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/students/$id'),
        headers: await _getHeaders(),
      );

      final data = _handleResponse(response);
      return User.fromJson(_extractData(data) as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load student: $e');
    }
  }

  static Future<List<User>> getTeacherStudents(int teacherId, {String? className}) async {
    try {
      final uri = Uri.parse('$baseUrl/teachers/$teacherId/students').replace(
        queryParameters: className == null || className.isEmpty
            ? null
            : {'className': className},
      );
      final response = await http.get(uri, headers: await _getHeaders());
      final data = _handleResponse(response);
      final list = _extractList(data);
      return list
          .map((json) => User.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load teacher students: $e');
    }
  }

  static Future<List<String>> getTeacherClasses(int teacherId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/teachers/$teacherId/classes'),
        headers: await _getHeaders(),
      );
      final data = _handleResponse(response);
      final list = _extractList(data);
      return list.map((item) => item.toString()).toList();
    } catch (e) {
      throw Exception('Failed to load teacher classes: $e');
    }
  }

  // ==================== GRADES ====================

  /// GET /api/grades/student/{studentId}/semester/{semester}
  /// Output: List<Grade>
  static Future<List<Grade>> getGrades(int studentId, int semester) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/grades/student/$studentId/semester/$semester'),
        headers: await _getHeaders(),
      );

      final data = _handleResponse(response);
      final list = _extractList(data);
      return list.map((json) => Grade.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load grades: $e');
    }
  }

  static Future<List<TeacherGrade>> getTeacherGrades(
      int teacherId, {
        required String className,
        required int semester,
        String? subject,
      }) async {
    try {
      final query = <String, String>{
        'className': className,
        'semester': semester.toString(),
      };
      if (subject != null && subject.isNotEmpty) {
        query['subject'] = subject;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/teachers/$teacherId/grades').replace(
          queryParameters: query,
        ),
        headers: await _getHeaders(),
      );

      final data = _handleResponse(response);
      final list = _extractList(data);
      return list
          .map((json) => TeacherGrade.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load teacher grades: $e');
    }
  }

  static Future<void> upsertTeacherGrade(
      int teacherId, {
        required int studentId,
        required int semester,
        required String subject,
        required List<double> tx15,
        required List<double> tx1tiet,
        double? giuaKy,
        double? cuoiKy,
        double? average,
      }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/teachers/$teacherId/grades'),
        headers: await _getHeaders(),
        body: json.encode({
          'studentId': studentId,
          'semester': semester,
          'subject': subject,
          'tx15': tx15,
          'tx1tiet': tx1tiet,
          'giuaKy': giuaKy,
          'cuoiKy': cuoiKy,
          'average': average,
        }),
      );
      _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to save grade: $e');
    }
  }

  // ==================== SCHEDULES ====================

  /// GET /api/schedules/class/{className}
  /// Output: List<Schedule> của tuần (dayOfWeek 0..6)
  static Future<List<Schedule>> getSchedules(String className) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/schedules/class/$className'),
        headers: await _getHeaders(),
      );

      final data = _handleResponse(response);
      final list = _extractList(data);
      return list.map((json) => Schedule.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load schedules: $e');
    }
  }

  /// GET /api/schedules/class/{className}/day/{dayOfWeek}
  /// Output: List<Schedule> của ngày đó
  static Future<List<Schedule>> getSchedulesByDay(String className, int dayOfWeek) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/schedules/class/$className/day/$dayOfWeek'),
        headers: await _getHeaders(),
      );

      final data = _handleResponse(response);
      final list = _extractList(data);
      return list.map((json) => Schedule.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load schedules: $e');
    }
  }

  static Future<List<Schedule>> getTeacherSchedules(int teacherId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/teachers/$teacherId/schedules'),
        headers: await _getHeaders(),
      );

      final data = _handleResponse(response);
      final list = _extractList(data);
      return list.map((json) => Schedule.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load teacher schedules: $e');
    }
  }

  // ==================== NOTIFICATIONS ====================

  /// GET /api/notifications
  /// Output: List<NotificationModel> sorted createdAt DESC
  static Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: await _getHeaders(),
      );

      final data = _handleResponse(response);
      final list = _extractList(data);
      return list.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load notifications: $e');
    }
  }

  /// GET /api/notifications/category/{category}
  /// category = IMPORTANT | SCHOOL | FEE
  static Future<List<NotificationModel>> getNotificationsByCategory(String category) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/category/$category'),
        headers: await _getHeaders(),
      );

      final data = _handleResponse(response);
      final list = _extractList(data);
      return list.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load notifications: $e');
    }
  }

  // ==================== ASSIGNMENTS ====================

  /// GET /api/assignments/class/{className}
  /// Output: List<Assignment> sorted dueDate DESC
  static Future<List<Assignment>> getAssignments(String className) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/assignments/class/$className'),
        headers: await _getHeaders(),
      );

      final data = _handleResponse(response);
      final list = _extractList(data);
      return list.map((json) => Assignment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load assignments: $e');
    }
  }

  static Future<List<Assignment>> getTeacherAssignments(int teacherId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/teachers/$teacherId/assignments'),
        headers: await _getHeaders(),
      );

      final data = _handleResponse(response);
      final list = _extractList(data);
      return list.map((json) => Assignment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load teacher assignments: $e');
    }
  }

  static Future<Assignment> createTeacherAssignment(
      int teacherId, {
        required String className,
        required String subject,
        required String title,
        required String description,
        required String dueDate,
        String? fileUrl,
      }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/teachers/$teacherId/assignments'),
        headers: await _getHeaders(),
        body: json.encode({
          'className': className,
          'subject': subject,
          'title': title,
          'description': description,
          'dueDate': dueDate,
          'fileUrl': fileUrl,
        }),
      );

      final data = _handleResponse(response);
      return Assignment.fromJson(_extractData(data) as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create assignment: $e');
    }
  }

  static Future<Assignment> updateTeacherAssignment(
      int id, {
        required String className,
        required String subject,
        required String title,
        required String description,
        required String dueDate,
        String? fileUrl,
      }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/assignments/$id'),
        headers: await _getHeaders(),
        body: json.encode({
          'className': className,
          'subject': subject,
          'title': title,
          'description': description,
          'dueDate': dueDate,
          'fileUrl': fileUrl,
        }),
      );
      final data = _handleResponse(response);
      return Assignment.fromJson(_extractData(data) as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update assignment: $e');
    }
  }

  static Future<void> deleteTeacherAssignment(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/assignments/$id'),
        headers: await _getHeaders(),
      );
      _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to delete assignment: $e');
    }
  }

  static Future<String> uploadFile(List<int> fileBytes, String fileName) async {
    try {
      final token = await StorageService.getToken();
      final uri = Uri.parse('$baseUrl/upload');
      final request = http.MultipartRequest('POST', uri);

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = _handleResponse(response);
      final extracted = _extractData(data);
      if (extracted != null && extracted is Map && extracted.containsKey('fileUrl')) {
        return extracted['fileUrl'].toString();
      }
      throw Exception('File URL not found in response');
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }


  // ==================== ATTENDANCE ====================

  static Future<List<Attendance>> getStudentAttendance(int studentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/student/$studentId'),
        headers: await _getHeaders(),
      );
      final data = _handleResponse(response);
      final list = _extractList(data);
      return list.map((json) => Attendance.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load student attendance: $e');
    }
  }

  static Future<List<Attendance>> getClassAttendance(String className, String date) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/class/$className/date/$date'),
        headers: await _getHeaders(),
      );
      final data = _handleResponse(response);
      final list = _extractList(data);
      return list.map((json) => Attendance.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load class attendance: $e');
    }
  }

  static Future<void> saveAttendance(
      int teacherId, {
        required String className,
        required String subject,
        required String date,
        required List<Map<String, dynamic>> records,
      }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendance?teacherId=$teacherId'),
        headers: await _getHeaders(),
        body: json.encode({
          'className': className,
          'subject': subject,
          'date': date,
          'records': records,
        }),
      );
      _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to save attendance: $e');
    }
  }

  // ==================== CONDUCT ====================

  static Future<List<Conduct>> getStudentConduct(int studentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/conduct/student/$studentId'),
        headers: await _getHeaders(),
      );
      final data = _handleResponse(response);
      final list = _extractList(data);
      return list.map((json) => Conduct.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load student conduct: $e');
    }
  }

  static Future<List<Conduct>> getClassConduct(String className, int month, int year) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/conduct/class/$className/month/$month/year/$year'),
        headers: await _getHeaders(),
      );
      final data = _handleResponse(response);
      final list = _extractList(data);
      return list.map((json) => Conduct.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load class conduct: $e');
    }
  }

  static Future<Conduct> saveConduct(
      int teacherId, {
        required int studentId,
        required String className,
        required int month,
        required int year,
        required String conductRating,
        String? comment,
      }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/conduct?teacherId=$teacherId'),
        headers: await _getHeaders(),
        body: json.encode({
          'studentId': studentId,
          'className': className,
          'month': month,
          'year': year,
          'conductRating': conductRating,
          'comment': comment,
        }),
      );
      final data = _handleResponse(response);
      return Conduct.fromJson(_extractData(data) as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to save conduct: $e');
    }
  }

  // ==================== CHAT ====================

  static Future<List<User>> getStudentTeachers(int studentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/students/$studentId/teachers'),
        headers: await _getHeaders(),
      );
      final data = _handleResponse(response);
      final list = _extractList(data);
      return list.map((json) => User.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to load teachers: $e');
    }
  }

  static Future<List<ChatMessage>> getChatHistory(int user1, int user2) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/history').replace(
          queryParameters: {
            'user1': user1.toString(),
            'user2': user2.toString(),
          },
        ),
        headers: await _getHeaders(),
      );
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data is List) {
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load chat history: $e');
    }
  }

  // ===== PAYMENT - VNPAY =====

  /// Lấy danh sách hóa đơn học phí của học sinh
  static Future<List<Map<String, dynamic>>> getInvoices(int studentId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/payments/invoices/$studentId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Lỗi tải hóa đơn: $e');
    }
  }

  /// Tạo URL thanh toán VNPay cho một hóa đơn
  static Future<String> createVNPayPaymentUrl(int invoiceId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/payments/vnpay/create-payment?invoiceId=$invoiceId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['paymentUrl'];
        }
        throw Exception(data['message'] ?? 'Lỗi tạo URL thanh toán');
      }
      throw Exception('Lỗi kết nối: ${response.statusCode}');
    } catch (e) {
      throw Exception('Lỗi tạo thanh toán VNPay: $e');
    }
  }
}

