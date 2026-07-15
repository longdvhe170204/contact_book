import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class TeacherStudentsScreen extends StatefulWidget {
  const TeacherStudentsScreen({super.key});

  @override
  State<TeacherStudentsScreen> createState() => _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends State<TeacherStudentsScreen> {
  User? _currentUser;
  List<String> _classes = [];
  String? _selectedClass;
  List<User> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final user = await StorageService.getCurrentUser();
      if (user == null || !user.isTeacher) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final classes = await ApiService.getTeacherClasses(user.id);
      final selectedClass = classes.isNotEmpty ? classes.first : null;
      final students = selectedClass == null
          ? const <User>[]
          : await ApiService.getTeacherStudents(user.id, className: selectedClass);

      if (!mounted) {
        return;
      }
      setState(() {
        _currentUser = user;
        _classes = classes;
        _selectedClass = selectedClass;
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải danh sách học sinh: $e')),
      );
    }
  }

  Future<void> _loadStudentsByClass(String className) async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _selectedClass = className;
    });

    try {
      final students = await ApiService.getTeacherStudents(user.id, className: className);
      if (!mounted) {
        return;
      }
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải học sinh: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách lớp'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null || !_currentUser!.isTeacher
              ? const Center(child: Text('Chức năng chỉ dành cho giáo viên'))
              : Column(
                  children: [
                    if (_classes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: DropdownButtonFormField<String>(
                          value: _selectedClass,
                          decoration: const InputDecoration(
                            labelText: 'Chọn lớp',
                            border: OutlineInputBorder(),
                          ),
                          items: _classes
                              .map((className) => DropdownMenuItem<String>(
                                    value: className,
                                    child: Text(className),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _loadStudentsByClass(value);
                            }
                          },
                        ),
                      ),
                    Expanded(
                      child: _students.isEmpty
                          ? const Center(child: Text('Chưa có học sinh trong lớp này'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _students.length,
                              itemBuilder: (context, index) {
                                final student = _students[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text('Lớp: ${student.className ?? 'Chưa có'}'),
                                        Text('Số điện thoại: ${student.phoneNumber}'),
                                        Text('Phụ huynh: ${student.parentName ?? 'Chưa cập nhật'}'),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}